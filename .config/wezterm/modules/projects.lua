local wezterm = require("wezterm")
local act = wezterm.action
local mux = wezterm.mux
local module = {}

-- =============================================================================
-- プロジェクト定義
--   ここに追記すれば、そのままランチャー（LEADER + o）に並ぶ
--   name         : ワークスペース名（一意）
--   cwd          : 起動時のカレントディレクトリ
--   left         : 左カラムで実行するコマンド（nil ならシェルのまま）
--   right        : 右カラムで実行するコマンド（nil なら左右分割しない）
--   top_left     : 左カラムを上下分割したときの上ペイン（left の別名）
--   bottom_left  : 左カラムを上下分割したときの下ペイン（指定時のみ分割）
--   top_right    : 右カラムを上下分割したときの上ペイン（right の別名）
--   bottom_right : 右カラムを上下分割したときの下ペイン（指定時のみ分割）
--   ratio        : 右カラムの幅の割合（省略時 0.4）
--   left_ratio   : 左カラムの下ペインの高さの割合（省略時 0.5）
--   right_ratio  : 右カラムの下ペインの高さの割合（省略時 0.5）
--   focus        : 起動時にフォーカスするペイン
--                  "top_left" / "bottom_left" / "top_right" / "bottom_right"
--                  （"left" / "right" も可。省略時は左上）
--
--   例: 4分割
--     { name = "foo", cwd = "...",
--       top_left = "claude", bottom_left = "lazygit",
--       top_right = "nvim",  bottom_right = "npm run dev",
--       ratio = 0.5, left_ratio = 0.3, right_ratio = 0.3 }
-- =============================================================================
-- 起動時に自動で開くプロジェクト名（nil にすると通常の default ワークスペースで起動）
local STARTUP_PROJECT = "herdr"

local PROJECTS = {
	{
		name = "herdr",
		cwd = wezterm.home_dir .. "/@kadota-src/yukke-memo",
		left = "herdr",
	},
	{
		name = "yukke-memo",
		cwd = wezterm.home_dir .. "/@kadota-src/yukke-memo",
		-- left = "claude",
		-- right = "nvim",
		-- ratio = 0.7,
		bottom_left = "claude",
		top_left = "claude",
		left_ratio = 0.5,
	},
	{
		name = "claude-config",
		cwd = wezterm.home_dir .. "/.claude",
		left = "claude",
		-- right = "nvim",
		-- ratio = 0.7,
	},
	{
		name = "wezterm-config",
		cwd = wezterm.home_dir .. "/.config/wezterm",
		left = "claude",
		-- right = "nvim",
		-- ratio = 0.7,
	},
}

local function workspace_exists(name)
	for _, ws in ipairs(mux.get_workspace_names()) do
		if ws == name then
			return true
		end
	end
	return false
end

-- フォーカス指定を正規化（left = top_left / right = top_right 扱い）
local FOCUS_ALIAS = {
	left = "top_left",
	right = "top_right",
	top_left = "top_left",
	bottom_left = "bottom_left",
	top_right = "top_right",
	bottom_right = "bottom_right",
}

-- プロジェクト用のワークスペースを組み立てる（既にあれば何もしない）
local function build_workspace(project)
	if workspace_exists(project.name) then
		return
	end

	-- 各位置のコマンド（left / right は上ペインの別名として扱う）
	local cmd = {
		top_left = project.top_left or project.left,
		bottom_left = project.bottom_left,
		top_right = project.top_right or project.right,
		bottom_right = project.bottom_right,
	}
	local has_right = cmd.top_right ~= nil or cmd.bottom_right ~= nil

	local tab, top_left_pane = mux.spawn_window({
		workspace = project.name,
		cwd = project.cwd,
	})

	-- tab.lua のカスタムタイトル機構に合わせてタブ名を設定
	local ok, tab_module = pcall(require, "tab")
	if ok then
		tab_module.custom_title[tab:tab_id()] = project.name
	end

	local panes = { top_left = top_left_pane }

	-- 先に左右分割 → その後それぞれのカラムを上下分割
	if has_right then
		panes.top_right = top_left_pane:split({
			direction = "Right",
			size = project.ratio or 0.4,
			cwd = project.cwd,
		})
	end

	if cmd.bottom_left then
		panes.bottom_left = panes.top_left:split({
			direction = "Bottom",
			size = project.left_ratio or 0.5,
			cwd = project.cwd,
		})
	end

	if cmd.bottom_right and panes.top_right then
		panes.bottom_right = panes.top_right:split({
			direction = "Bottom",
			size = project.right_ratio or 0.5,
			cwd = project.cwd,
		})
	end

	-- 左上は最後に流す（先に流すと分割前に画面が埋まるため）
	local order = { "top_right", "bottom_right", "bottom_left", "top_left" }
	for _, position in ipairs(order) do
		if panes[position] and cmd[position] then
			panes[position]:send_text(cmd[position] .. "\n")
		end
	end

	local focus = FOCUS_ALIAS[project.focus or ""] or "top_left"
	local focus_pane = panes[focus] or panes.top_left
	pcall(function()
		focus_pane:activate()
	end)
end

-- プロジェクトを開く（無ければ作る → 切り替える）
local function open_project(window, pane, project)
	build_workspace(project)
	window:perform_action(act.SwitchToWorkspace({ name = project.name }), pane)
end

-- ランチャー: プロジェクト一覧から選んで開く
local function project_picker()
	return wezterm.action_callback(function(window, pane)
		local choices = {}
		for i, project in ipairs(PROJECTS) do
			-- ● = 起動済み / ○ = 未起動
			local mark = workspace_exists(project.name) and "●" or "○"
			table.insert(choices, {
				id = tostring(i),
				label = string.format("%s %s", mark, project.name),
			})
		end

		window:perform_action(
			act.InputSelector({
				title = "Open project",
				fuzzy = true,
				choices = choices,
				action = wezterm.action_callback(function(win, inner_pane, id)
					if not id then
						return
					end
					open_project(win, inner_pane, PROJECTS[tonumber(id)])
				end),
			}),
			pane
		)
	end)
end

local function find_project(name)
	for _, project in ipairs(PROJECTS) do
		if project.name == name then
			return project
		end
	end
	return nil
end

-- WezTerm 起動時: STARTUP_PROJECT のワークスペースを組み立てて、そこから始める
-- （gui-startup を定義すると既定のウィンドウ生成はこちらの責任になる）
wezterm.on("gui-startup", function(cmd)
	-- `wezterm start -- <command>` のように明示指定された場合はそちらを優先
	if cmd then
		mux.spawn_window(cmd)
		return
	end

	-- `wezterm start --always-new-process --workspace <name>` で起動された場合、
	-- この時点の active workspace にその名前が入っている（未指定なら "default"）。
	-- macOS の Space ごとに別プロセスを立てる用途なので、指定があればそちらを優先する。
	local requested = mux.get_active_workspace()
	local target = (requested and requested ~= "default") and requested or STARTUP_PROJECT

	local project = target and find_project(target)
	if not project then
		-- プロジェクト定義のない名前なら、素のウィンドウをその名前で開く
		mux.spawn_window({ workspace = target })
		if target then
			mux.set_active_workspace(target)
		end
		return
	end

	build_workspace(project)
	mux.set_active_workspace(project.name)
end)

-- 他モジュール（modules/space_window.lua）からプロジェクト一覧を参照するため
function module.get_projects()
	return PROJECTS
end

function module.apply_to_config(config)
	table.insert(config.keys, { key = "o", mods = "LEADER", action = project_picker() })
end

return module
