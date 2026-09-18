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
        -- 見出し: 既定は H1 青 / H2 黄 / H3 緑。H1 黄 / H2 緑 / H3 青 に入れ替え（帯色も文字色に合わせて回す）
        local util = require("tokyonight.util")
        hl["@markup.heading.1.markdown"] = { fg = c.yellow, bg = util.blend_bg(c.yellow, 0.1), bold = true }
        hl["@markup.heading.2.markdown"] = { fg = c.green, bg = util.blend_bg(c.green, 0.1), bold = true }
        hl["@markup.heading.3.markdown"] = { fg = c.blue, bg = util.blend_bg(c.blue, 0.1), bold = true }
        -- tokyonight は RenderMarkdownH{n}Bg / Fg も既定の色順で別途定義しているので、同じ順に揃える
        for i, color in ipairs({ c.yellow, c.green, c.blue }) do
          hl["RenderMarkdownH" .. i .. "Bg"] = { bg = util.blend_bg(color, 0.1) }
          hl["RenderMarkdownH" .. i .. "Fg"] = { fg = color, bold = true }
        end
        -- インラインコード: 既定 fg blue (#82aaff) を白に寄せる
        hl["@markup.raw.markdown_inline"] = { fg = "#b4ccff", bg = "#444a73" }
        -- 箇条書きの点・リスト: H4 と同じ teal
        hl.RenderMarkdownBullet = { fg = c.teal }
        hl["@markup.list"] = { fg = c.teal }
        hl["@markup.list.markdown"] = { fg = c.teal, bold = true }
        -- 表: ヘッダ行の罫線は teal、データ行と行間罫線（自作 render-markdown.lua も config.row を使う）は通常の文字色
        hl.RenderMarkdownTableHead = { fg = c.teal }
        hl.RenderMarkdownTableRow = { fg = c.fg }
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
