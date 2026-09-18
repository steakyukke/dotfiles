return {
  {
    "folke/tokyonight.nvim",
    lazy = false,
    priority = 1000,
    opts = {
      style = "moon",
      on_highlights = function(hl, c)
        -- snacks explorer / picker: ドットファイルと .gitignore 対象のファイル名。
        -- 既定は NonText (#545c7e) で暗すぎて読めず、#a9b1d6 では通常ファイル (Normal #c8d3f5) と
        -- 区別がつかなかったので、その中間の fg_dark (#828bb8) にする
        hl.SnacksPickerPathHidden = { fg = c.fg_dark }
        hl.SnacksPickerPathIgnored = { fg = c.fg_dark }

        -- markdown プレビュー (render-markdown.nvim) の配色
        -- 見出し: 既定は 青 / 黄 / 緑 / teal / 紫 / 桃 の順。H1 黄 / H2 青 / H3 紫 / H4 teal / H5 緑 / H6 桃 に変更。
        -- 帯色は文字色を背景と 10% ブレンド（tokyonight と同じ計算）。
        -- tokyonight は RenderMarkdownH{n}Bg / Fg も既定の色順で別途定義しているので、同じ順に揃える
        local util = require("tokyonight.util")
        local heading_colors = { c.yellow, c.blue, c.magenta, c.teal, c.green, c.purple }
        for i, color in ipairs(heading_colors) do
          hl["@markup.heading." .. i .. ".markdown"] = { fg = color, bg = util.blend_bg(color, 0.1), bold = true }
          hl["RenderMarkdownH" .. i .. "Bg"] = { bg = util.blend_bg(color, 0.1) }
          hl["RenderMarkdownH" .. i .. "Fg"] = { fg = color, bold = true }
        end
        -- 表ヘッダのセル文字（treesitter が @markup.heading を当てる）: 白の太字
        hl["@markup.heading.markdown"] = { fg = "#ffffff", bold = true }
        -- インラインコード: 既定 fg blue (#82aaff) を白に寄せ、bg は既定 #444a73 (L36% S26%) より暗く (L31% S23%)
        hl["@markup.raw.markdown_inline"] = { fg = "#b4ccff", bg = "#3d4261" }
        -- 箇条書きの点・リスト: H4 と同じ teal
        hl.RenderMarkdownBullet = { fg = c.teal }
        hl["@markup.list"] = { fg = c.teal }
        hl["@markup.list.markdown"] = { fg = c.teal, bold = true }
        -- 表: ヘッダ行の罫線は桃 (#fca7ea)、データ行と行間罫線（自作 render-markdown.lua も config.row を使う）は通常の文字色
        hl.RenderMarkdownTableHead = { fg = c.purple }
        hl.RenderMarkdownTableRow = { fg = c.fg }
        -- 水平線 (---): 通常の文字色 (#c8d3f5) に灰色を 30% 混ぜた色
        hl.RenderMarkdownDash = { fg = "#b2bad2" }
      end,
    },
  },
  -- 起動時のデフォルト colorscheme を tokyonight-moon に固定
  {
    "LazyVim/LazyVim",
    opts = { colorscheme = "tokyonight-moon" },
  },
  {
    "thesimonho/kanagawa-paper.nvim",
    -- lazy = false,
    -- priority = 1000,
    opts = {
      transparent = true,
      wezterm = {
        enabled = false,
        -- neovim will write the theme name to this file
        -- wezterm will read from this file to know which theme to use
        path = (os.getenv("TEMP") or "/tmp") .. "/nvim-theme",
      },
    },
  },
  {
    "zenbones-theme/zenbones.nvim",
    -- Optionally install Lush. Allows for more configuration or extending the colorscheme
    -- If you don't want to install lush, make sure to set g:zenbones_compat = 1
    -- In Vim, compat mode is turned on as Lush only works in Neovim.
    dependencies = "rktjmp/lush.nvim",
    -- lazy = false,
    -- priority = 1000,
    -- opts = { transparent_background = true },
    -- you can set set configuration options here
    config = function()
      -- vim.g.zenbones_darken_comments = 45
      vim.g.zenbones_transparent_background = true
      vim.g.zenbones_lightness = "bright"
      vim.g.zenbones_darkness = "stark"
      vim.g.zenbones_darken_noncurrent_window = false
      vim.g.zenbones_lighten_noncurrent_window = true
      vim.g.zenbones_solid_float_border = true
      -- vim.cmd.colorscheme("zenbones")
    end,
  },
}
