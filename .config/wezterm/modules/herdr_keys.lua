-- modules/herdr_keys.lua
--
-- WezTerm のペインで herdr (Harder) がフォアグラウンドで動いているときは、
-- WezTerm 側のペイン操作キーを WezTerm で処理せず、herdr の同じ操作に転送する。
--
-- 【仕組み】
-- 各キーバインドを wezterm.action_callback で包み、押されたときに
-- pane:get_foreground_process_name() を見て herdr なら herdr 向けのキー
-- （prefix=ctrl+b + 文字、または直接コード）を SendKey で送り込む。
-- herdr でなければ従来どおり WezTerm のアクションを実行する。
--
-- 【herdr 側の対応キー】 ~/.config/herdr/config.toml の [keys] を参照
--   split_vertical   = prefix+r   ← WezTerm Ctrl+Shift+R
--   split_horizontal = prefix+d   ← WezTerm Ctrl+Shift+D
--   close_pane       = prefix+x   ← WezTerm Ctrl+Shift+X
--   zoom             = prefix+z   ← WezTerm Ctrl+Shift+Z
--   focus_pane_*     = prefix+hjkl ← WezTerm Alt+hjkl / Ctrl+Shift+hjkl
--   resize_pane_*    = ctrl+alt+hjkl ← WezTerm Ctrl+Shift+Alt+hjkl
--   new_tab          = prefix+c   ← WezTerm Cmd+T
--   close_tab        = prefix+shift+x ← WezTerm Cmd+W は herdr 前面では無効（何も送らない）
--   next_tab         = prefix+n   ← WezTerm Ctrl+Tab
--   previous_tab     = prefix+p   ← WezTerm Ctrl+Shift+Tab
--   switch_workspace = alt+1..9   ← WezTerm Ctrl+1..9
--     （Ctrl+数字は WezTerm が ESC[27;5;49~ 形式で送り herdr が解釈できないため、ESC+数字 = Alt+数字 に変換して送る）
--
-- LEADER (Ctrl+q) 系のキーは herdr に転送せず、WezTerm のまま扱う。
--
-- 【元に戻したいとき】
-- wezterm.lua の require("modules.herdr_keys") の行をコメントアウトするだけでよい。

local wezterm = require("wezterm")
local act = wezterm.action

local module = {}

-- herdr の prefix キー（config.toml の [keys].prefix と合わせる）
local HERDR_PREFIX = { key = "b", mods = "CTRL" }

-- フォアグラウンドプロセスが herdr かどうか
local function is_herdr(pane)
  local name = pane:get_foreground_process_name()
  if not name then
    return false
  end
  local base = name:match("([^/]+)$") or name
  return base == "herdr"
end
module.is_herdr = is_herdr

-- herdr にキー列を送る。keys は SendKey に渡すテーブルの配列
local function send_keys(window, pane, keys)
  local actions = {}
  for _, k in ipairs(keys) do
    table.insert(actions, act.SendKey(k))
  end
  window:perform_action(act.Multiple(actions), pane)
end

-- herdr がフォアグラウンドなら herdr_keys を送信、そうでなければ fallback を実行する
local function herdr_or(herdr_keys, fallback)
  return wezterm.action_callback(function(window, pane)
    if is_herdr(pane) then
      send_keys(window, pane, herdr_keys)
    else
      window:perform_action(fallback, pane)
    end
  end)
end
module.herdr_or = herdr_or

-- prefix + 1キー の省略形
local function prefixed(key, mods)
  return { HERDR_PREFIX, { key = key, mods = mods } }
end

-- 既存バインドと同じキー・同じ WezTerm アクションで、herdr 時だけ転送先を差し替える
local keys = {
  -- 分割 (Ctrl+Shift)
  { key = "r", mods = "CTRL|SHIFT", action = herdr_or(prefixed("r"), act.SplitHorizontal({ domain = "CurrentPaneDomain" })) },
  { key = "d", mods = "CTRL|SHIFT", action = herdr_or(prefixed("d"), act.SplitVertical({ domain = "CurrentPaneDomain" })) },

  -- ペインを閉じる
  { key = "x", mods = "CTRL|SHIFT", action = herdr_or(prefixed("x"), act({ CloseCurrentPane = { confirm = true } })) },

  -- ズーム（WezTerm 側はペインが2つ以上のときのみ）
  {
    key = "Z",
    mods = "CTRL",
    action = herdr_or(
      prefixed("z"),
      wezterm.action_callback(function(window, pane)
        local tab = pane:tab()
        if #tab:panes() > 1 then
          window:perform_action(act.TogglePaneZoomState, pane)
        end
      end)
    ),
  },

  -- ペイン移動 (Alt+hjkl / Ctrl+Shift+hjkl)
  { key = "h", mods = "ALT", action = herdr_or(prefixed("h"), act.ActivatePaneDirection("Left")) },
  { key = "j", mods = "ALT", action = herdr_or(prefixed("j"), act.ActivatePaneDirection("Down")) },
  { key = "k", mods = "ALT", action = herdr_or(prefixed("k"), act.ActivatePaneDirection("Up")) },
  { key = "l", mods = "ALT", action = herdr_or(prefixed("l"), act.ActivatePaneDirection("Right")) },
  { key = "h", mods = "CTRL|SHIFT", action = herdr_or(prefixed("h"), act.ActivatePaneDirection("Left")) },
  { key = "j", mods = "CTRL|SHIFT", action = herdr_or(prefixed("j"), act.ActivatePaneDirection("Down")) },
  { key = "k", mods = "CTRL|SHIFT", action = herdr_or(prefixed("k"), act.ActivatePaneDirection("Up")) },
  { key = "l", mods = "CTRL|SHIFT", action = herdr_or(prefixed("l"), act.ActivatePaneDirection("Right")) },

  -- ペインリサイズ (Ctrl+Shift+Alt+hjkl)
  -- herdr 側は resize_pane_* = "ctrl+alt+hjkl" の直接チョードに割り当てているので、
  -- prefix を挟まず ctrl+alt+hjkl をそのまま送る
  { key = "h", mods = "CTRL|SHIFT|ALT", action = herdr_or({ { key = "h", mods = "CTRL|ALT" } }, act.AdjustPaneSize({ "Left", 1 })) },
  { key = "j", mods = "CTRL|SHIFT|ALT", action = herdr_or({ { key = "j", mods = "CTRL|ALT" } }, act.AdjustPaneSize({ "Down", 1 })) },
  { key = "k", mods = "CTRL|SHIFT|ALT", action = herdr_or({ { key = "k", mods = "CTRL|ALT" } }, act.AdjustPaneSize({ "Up", 1 })) },
  { key = "l", mods = "CTRL|SHIFT|ALT", action = herdr_or({ { key = "l", mods = "CTRL|ALT" } }, act.AdjustPaneSize({ "Right", 1 })) },

  -- タブ操作
  { key = "t", mods = "SUPER", action = herdr_or(prefixed("c"), act.SpawnTab("CurrentPaneDomain")) },
  -- Cmd+W: herdr 前面では何もしない（誤爆でタブを消さないため無効化）。herdr のタブを閉じるのは prefix+shift+x
  { key = "w", mods = "SUPER", action = herdr_or({}, act.CloseCurrentTab({ confirm = true })) },
  { key = "Tab", mods = "CTRL", action = herdr_or(prefixed("n"), act.ActivateTabRelative(1)) },
  { key = "Tab", mods = "SHIFT|CTRL", action = herdr_or(prefixed("p"), act.ActivateTabRelative(-1)) },
}

-- ワークスペース切替 (Ctrl+1..9)
-- herdr 側は switch_workspace = "alt+1..9"。herdr 以外のペインでは Ctrl+数字をそのまま送る（従来どおり）
for n = 1, 9 do
  local key = tostring(n)
  table.insert(keys, {
    key = key,
    mods = "CTRL",
    action = herdr_or({ { key = key, mods = "ALT" } }, act.SendKey({ key = key, mods = "CTRL" })),
  })
end

function module.apply_to_config(config)
  for _, k in ipairs(keys) do
    table.insert(config.keys, k)
  end
end

return module
