local wezterm = require("wezterm")
local module = {}

local appearance = {
  color_scheme = "Solarized Dark Higher Contrast",

  -- 起動時のウィンドウサイズ（デフォルト 80x24 の約2倍×2倍）
  initial_cols = 160,
  initial_rows = 48,

  -- window title
  -- タイトルバーを非表示
  -- MACOS_FORCE_SQUARE_CORNERS: 角丸をやめてボーダーを四隅まで繋げる
  window_decorations = "RESIZE|MACOS_FORCE_SQUARE_CORNERS", -- NONE, TITLE, TITLE | RESIZE, RESIZE, INTEGRATED_BUTTONS
  window_close_confirmation = "NeverPrompt", -- AlwaysPrompt or NeverPrompt

  -- Pane
  inactive_pane_hsb = {
    hue = 1.0,
    saturation = 0.98,
    brightness = 0.9,
  },

  -- Tab
  show_tabs_in_tab_bar = true,
  hide_tab_bar_if_only_one_tab = true, -- タブが1つのときはタブバー（ステータスバー含む）ごと非表示
  tab_bar_at_bottom = false, -- タブバーを上部に表示
  show_new_tab_button_in_tab_bar = false,
  show_close_tab_button_in_tabs = false, -- Nightly限定
  tab_max_width = 30,
  use_fancy_tab_bar = true,
  -- use_fancy_tab_bar = trueの場合のタブバー透過設定
  window_frame = {
    -- タブバー（fancy tab bar）の背景をペインと同じ色にする
    inactive_titlebar_bg = "#1a1a2e",
    active_titlebar_bg = "#1a1a2e",
    -- ウィンドウ外枠のボーダー（カーソル色に合わせたティール系アクセント）
    border_left_width = "2px",
    border_right_width = "2px",
    border_top_height = "2px",
    border_bottom_height = "2px",
    border_left_color = "#80EBDF",
    border_right_color = "#80EBDF",
    border_top_color = "#80EBDF",
    border_bottom_color = "#80EBDF",
  },
  -- Hide borders between tabs
  colors = {
    -- アクティブPaneの背景色（やや明るい灰色）。非アクティブは inactive_pane_hsb で暗く戻る
    background = "#1a1a2e",
    -- 標準の文字色（配色のデフォルト #9cc2c3 は薄いので白寄りに上書き）
    foreground = "#e6edf3",
    -- use_fancy_tab_bar = falseの場合のタブバー背景
    tab_bar = {
      background = "#1a1a2e",
      inactive_tab_edge = "none",
    },
    -- カーソルとコピーモード選択色（WezTermデフォルト）
    cursor_bg = "#80EBDF",
    cursor_fg = "#000000",
    cursor_border = "#80EBDF",
    -- Pane分割線。アクセント色にしてペインの境界を明確にする
    split = "#80EBDF",
    selection_bg = "#ffdd00",
    selection_fg = "#000000",
  },
}

function module.apply_to_config(config)
  for k, v in pairs(appearance) do
    config[k] = v
  end
end

return module
