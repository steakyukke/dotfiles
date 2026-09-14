local wezterm = require("wezterm")
local act = wezterm.action
local module = {}

-- =============================================================================
-- macOS の Space ごとに WezTerm のウィンドウを常駐させるためのモジュール
--
-- WezTerm の GUI プロセスは「アクティブなワークスペース1つ」しか表示できない。
-- （ワークスペースを切り替えると、そのプロセスの全ウィンドウの中身が入れ替わる）
-- そのため、ワークスペースごとに GUI プロセス自体を分けて起動する。
--
--   LEADER + O : ワークスペースを選んで、新しい GUI プロセスで開く
--
-- 開いたウィンドウを目的の Space へドラッグしておけば、その Space に留まる。
-- 注意: プロセスが別なので mux は共有されない（ペインの移動やセッション共有は不可）。
-- =============================================================================

local WEZTERM_BIN = wezterm.executable_dir .. "/wezterm"

local function shquote(s)
	return "'" .. (tostring(s):gsub("'", "'\\''")) .. "'"
end

-- 今の WezTerm から切り離した、新しい GUI プロセスを起動する
-- （nohup + & で親から独立させ、この WezTerm を終了しても残るようにする）
function module.launch(workspace)
	if not workspace or workspace == "" then
		return
	end

	local cmd = string.format(
		"nohup %s start --always-new-process --workspace %s >/dev/null 2>&1 &",
		shquote(WEZTERM_BIN),
		shquote(workspace)
	)
	wezterm.background_child_process({ "/bin/sh", "-c", cmd })
	wezterm.log_info("space_window: spawned new wezterm process for workspace " .. workspace)
end

local function project_choices()
	local choices = {}
	local ok, projects = pcall(function()
		return require("modules.projects").get_projects()
	end)
	if ok and projects then
		for _, p in ipairs(projects) do
			table.insert(choices, {
				id = p.name,
				label = string.format("%s  (%s)", p.name, p.cwd or ""),
			})
		end
	end
	return choices
end

local function launch_picker()
	return wezterm.action_callback(function(window, pane)
		local choices = project_choices()
		table.insert(choices, { id = "__prompt__", label = "+ 新しいワークスペース名を入力…" })

		window:perform_action(
			act.InputSelector({
				title = "新しいウィンドウ (別プロセス) で開くワークスペース",
				choices = choices,
				fuzzy = true,
				action = wezterm.action_callback(function(inner_window, inner_pane, id)
					if not id then
						return
					end
					if id ~= "__prompt__" then
						module.launch(id)
						return
					end
					inner_window:perform_action(
						act.PromptInputLine({
							description = "(wezterm) 新プロセスで開くワークスペース名:",
							action = wezterm.action_callback(function(_, _, line)
								module.launch(line)
							end),
						}),
						inner_pane
					)
				end),
			}),
			pane
		)
	end)
end

function module.apply_to_config(config)
	table.insert(config.keys, { key = "O", mods = "LEADER", action = launch_picker() })
end

return module
