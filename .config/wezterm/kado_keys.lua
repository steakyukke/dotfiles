-- kado_keys.lua
--
-- 自分（kado）用のキーバインド上書き。
--
-- 【このファイルの役割】
-- 元の設定 (moz-us-3) の keymaps.lua や modules/ を一切編集せずに、
-- 自分好みのキーバインドだけをここに集約する。
-- WezTerm は同じキーを後から定義した方が勝つため、wezterm.lua の最後で
-- このファイルを読み込むことで上書きが成立する。
--
-- 【元に戻したいとき】
-- wezterm.lua の require("kado_keys") の行をコメントアウトするだけでよい。
--
-- 【キー選定の方針】
-- Ctrl 単体（Ctrl+H など）は Neovim と zsh がほぼ全て使用済みのため使わない。
--   例: Neovim の <C-h/j/k/l> はウィンドウ移動と診断ジャンプ、
--       zsh の ^K は kill-line、^L は clear-screen。
-- Ctrl+Shift は Neovim・zsh ともにマッピングが存在しないため衝突しない。
-- Ghostty 側 (~/.config/ghostty/config) にも同じキーを設定して揃えている。
--
-- 【もし Ctrl+Shift が効かない場合】
-- wezterm.lua の macos_forward_to_ime_modifier_mask が復活していないか確認する。
-- 復活が必要なら、下記の "CTRL|SHIFT" を "CTRL|SUPER" に、
-- "CTRL|SHIFT|ALT" を "CTRL|SUPER|ALT" に置換すれば同じ配置で移行できる。

local wezterm = require("wezterm")
local act = wezterm.action

local module = {}

local keys = {
  -- ペイン移動
  { key = "h", mods = "CTRL|SHIFT", action = act.ActivatePaneDirection("Left") },
  { key = "j", mods = "CTRL|SHIFT", action = act.ActivatePaneDirection("Down") },
  { key = "k", mods = "CTRL|SHIFT", action = act.ActivatePaneDirection("Up") },
  { key = "l", mods = "CTRL|SHIFT", action = act.ActivatePaneDirection("Right") },

  -- ペイン分割
  -- WezTerm の SplitHorizontal は「右に新ペイン」、SplitVertical は「下に新ペイン」
  -- 文字は LEADER(Ctrl+Q) の r / d / x と揃えている
  { key = "r", mods = "CTRL|SHIFT", action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
  { key = "d", mods = "CTRL|SHIFT", action = act.SplitVertical({ domain = "CurrentPaneDomain" }) },

  -- ペインを閉じる（タブを閉じるのは Cmd+W のまま）
  -- 注: keymaps.lua:313 の Ctrl+Shift+X（コピーモード）を上書きしている
  { key = "x", mods = "CTRL|SHIFT", action = act({ CloseCurrentPane = { confirm = true } }) },

  -- ペインリサイズ（移動と同じ hjkl に Alt を足す）
  { key = "h", mods = "CTRL|SHIFT|ALT", action = act.AdjustPaneSize({ "Left", 1 }) },
  { key = "j", mods = "CTRL|SHIFT|ALT", action = act.AdjustPaneSize({ "Down", 1 }) },
  { key = "k", mods = "CTRL|SHIFT|ALT", action = act.AdjustPaneSize({ "Up", 1 }) },
  { key = "l", mods = "CTRL|SHIFT|ALT", action = act.AdjustPaneSize({ "Right", 1 }) },

  -- スクロール（vim の <C-y> <C-e> に対応させた文字）
  { key = "y", mods = "CTRL|SHIFT", action = act.ScrollByLine(-3) },
  { key = "e", mods = "CTRL|SHIFT", action = act.ScrollByLine(3) },

  -- ズーム切替は keymaps.lua:171 の Ctrl+Shift+Z をそのまま使う（上書きしない）
}

function module.apply_to_config(config)
  for _, k in ipairs(keys) do
    table.insert(config.keys, k)
  end
end

return module
