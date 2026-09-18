local wezterm = require("wezterm")
local act = wezterm.action
local module = {}

-- 非フォーカス時の暗さ（0.0〜1.0 / 大きいほど暗い）
local UNFOCUSED_BG_DARKEN = 0.35
local UNFOCUSED_FG_DARKEN = 0.15
local UNFOCUSED_BORDER_DARKEN = 0.55

-- 非フォーカス時に減光するか（false なら window-focus-changed で何もしない）
local DIM_ON_UNFOCUS = false

-- appearance.lua 適用後の基準値をスナップショット（wezterm.lua での require 順に依存）
local base_opacity = 1.0
local base_colors = {}
local base_frame = {}

function module.apply_to_config(config)
  base_opacity = config.window_background_opacity or 1.0
  for k, v in pairs(config.colors or {}) do
    base_colors[k] = v
  end
  for k, v in pairs(config.window_frame or {}) do
    base_frame[k] = v
  end

  -- 透明度調整のキーを追加
  table.insert(config.key_tables.setting_mode, { key = ";", action = act.EmitEvent("increase-opacity") })
  table.insert(config.key_tables.setting_mode, { key = "-", action = act.EmitEvent("decrease-opacity") })
  table.insert(config.key_tables.setting_mode, { key = "0", action = act.EmitEvent("reset-opacity") })
end

local function reactivate_setting_mode(window)
  window:perform_action(
    wezterm.action.ActivateKeyTable({ name = "setting_mode", one_shot = false }),
    window:active_pane()
  )
end

local function adjust_opacity(window, delta, config)
  local overrides = window:get_config_overrides() or {}
  local current = overrides.window_background_opacity or config.window_background_opacity or 1.0

  local new_opacity = current + delta
  new_opacity = math.max(0.1, math.min(1.0, new_opacity))

  overrides.window_background_opacity = new_opacity
  window:set_config_overrides(overrides)

  reactivate_setting_mode(window)
end

wezterm.on("decrease-opacity", function(window, config)
  adjust_opacity(window, -0.1, config)
end)

wezterm.on("increase-opacity", function(window, config)
  adjust_opacity(window, 0.1, config)
end)

wezterm.on("reset-opacity", function(window, config)
  local overrides = window:get_config_overrides() or {}
  overrides.window_background_opacity = config.window_background_opacity
  window:set_config_overrides(overrides)

  reactivate_setting_mode(window)
end)

-- フォーカス連動の減光
-- 透過（blur）は常に維持したまま、非フォーカス時は背景・文字を暗くして区別する
local function dimmed_colors()
  local colors = {}
  for k, v in pairs(base_colors) do
    colors[k] = v
  end
  local bg = base_colors.background
  local fg = base_colors.foreground
  if bg then
    colors.background = tostring(wezterm.color.parse(bg):darken(UNFOCUSED_BG_DARKEN))
  end
  if fg then
    colors.foreground = tostring(wezterm.color.parse(fg):darken(UNFOCUSED_FG_DARKEN))
  end
  return colors
end

-- 非フォーカス時のボーダー色（アクセント色を暗く落とす）
local function dimmed_frame()
  local frame = {}
  for k, v in pairs(base_frame) do
    if k:match("^border_.*_color$") then
      frame[k] = tostring(wezterm.color.parse(v):darken(UNFOCUSED_BORDER_DARKEN))
    elseif k:match("_titlebar_bg$") and v ~= "none" then
      -- タブバー背景は本体の背景と同じだけ暗くする
      frame[k] = tostring(wezterm.color.parse(v):darken(UNFOCUSED_BG_DARKEN))
    else
      frame[k] = v
    end
  end
  return frame
end

wezterm.on("window-focus-changed", function(window, pane)
  local overrides = window:get_config_overrides() or {}
  -- 透過はフォーカス状態に関わらず維持する
  overrides.window_background_opacity = base_opacity
  if not DIM_ON_UNFOCUS or window:is_focused() then
    overrides.colors = nil
    overrides.window_frame = nil
  else
    overrides.colors = dimmed_colors()
    overrides.window_frame = dimmed_frame()
  end
  window:set_config_overrides(overrides)
end)

return module
