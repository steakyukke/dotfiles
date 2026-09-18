return {
  {
    "folke/snacks.nvim",
    priority = 1000,
    config = function(_, opts)
      require("snacks").setup(opts)

      -- Auto show image on cursor hold
      vim.api.nvim_create_autocmd("CursorHold", {
        group = vim.api.nvim_create_augroup("snacks_image_hover", { clear = true }),
        pattern = { "*.png", "*.jpg", "*.jpeg", "*.gif", "*.webp", "*.md", "*.markdown" },
        callback = function()
          if Snacks and Snacks.image and Snacks.image.hover then
            -- Safely call hover, ignore errors if no image at cursor
            pcall(Snacks.image.hover)
          end
        end,
      })

      -- Optional: Reduce updatetime for faster hover (default is 4000ms)
      vim.opt.updatetime = 300 -- CursorHold発火間隔（100msは短すぎてフリーズ原因になりやすい）
    end,
    keys = {
      {
        "<leader>mp",
        ft = { "png", "markdown" },
        function()
          Snacks.image.hover()
        end,
        desc = "Preview image/math formula under cursor (manual)",
      },
      {
        "<leader>p",
        function()
          Snacks.picker.pickers()
        end,
      },
      {
        "<space>fh",
        function()
          Snacks.picker.help({
            win = {
              input = { keys = {
                ["<CR>"] = { "edit_vsplit", mode = { "i", "n" } },
              } },
            },
          })
        end,
        desc = "Picker: help pages",
      },
      {
        "<leader>gf",
        function()
          Snacks.picker.git_log_file({
            confirm = function(picker, item)
              if item and item.commit then
                Snacks.gitbrowse({ commit = item.commit })
              end
            end,
          })
        end,
        desc = "Git Log File (Enter=Browse, o=Checkout)",
      },
      {
        "<leader>gD",
        function()
          Snacks.picker.git_diff({ base = "main" })
        end,
        desc = "Git Diff vs Main",
      },
    },
    ---@type snacks.Config
    opts = {
      scroll = { enabled = false },
      dashboard = {
        preset = {
          keys = {
            {
              icon = " ",
              key = "f",
              desc = "Find File",
              action = function()
                Snacks.picker.files({ cwd = vim.fn.getcwd() })
              end,
            },
            { icon = " ", key = "n", desc = "New File", action = ":ene | startinsert" },
            {
              icon = " ",
              key = "g",
              desc = "Find Text",
              action = function()
                Snacks.picker.grep({ cwd = vim.fn.getcwd() })
              end,
            },
            {
              icon = " ",
              key = "r",
              desc = "Recent Files",
              action = function()
                Snacks.picker.recent()
              end,
            },
            {
              icon = " ",
              key = "c",
              desc = "Config",
              action = function()
                Snacks.picker.files({ cwd = vim.fn.stdpath("config"), hidden = true })
              end,
            },
            { icon = " ", key = "s", desc = "Restore Session", section = "session" },
            { icon = "󰒲 ", key = "x", desc = "Lazy Extras", action = ":LazyExtras" },
            { icon = "󰒲 ", key = "l", desc = "Lazy", action = ":Lazy" },
            { icon = " ", key = "q", desc = "Quit", action = ":qa" },
          },
        },
      },
      image = {
        enabled = true,
        -- nb の --original URL形式を実際のファイルパスに変換
        resolve = function(file, src)
          -- http://localhost:6789/--original/{notebook}/{filename} 形式を検出
          local notebook, filename = src:match("http://localhost:6789/%-%-original/([^/]+)/(.+)$")
          if notebook and filename then
            local nb = require("config.nb")
            return nb.get_nb_dir() .. "/" .. notebook .. "/" .. filename
          end
          return nil
        end,
        doc = {
          -- enable image viewer for documents
          -- a treesitter parser must be available for the enabled languages.
          -- supported language injections: markdown, html
          enabled = true,
          -- render the image inline in the buffer
          -- if your env doesn't support unicode placeholders, this will be disabled
          -- takes precedence over `opts.float` on supported terminals
          inline = true,
          -- render the image in a floating window
          -- only used if `opts.inline` is disabled
          float = false,
          max_width = 80,
          max_height = 40,
        },
      },
      picker = {
        win = {
          input = {
            keys = {
              ["h"] = { "toggle_hidden", mode = { "n" } },
              ["I"] = { "toggle_ignored", mode = { "n" } },
            },
          },
        },
        sources = {
          files = {
            hidden = true, -- ドットファイルを常に対象にする
            ignored = true, -- .gitignore 対象も常に対象にする
            -- 空入力時は最近よく開いたファイルを上に（半減期30日。記録は stdpath("data")/snacks/picker-frecency）
            matcher = { frecency = true, sort_empty = true },
          },
          grep = {
            hidden = true,
            ignored = false, -- node_modules 等まで舐めると重いので OFF（ピッカー内 I で切替）
          },
          explorer = {
            hidden = true, -- ドットファイル（.git など）を常に表示
            ignored = true, -- .gitignore 対象（node_modules など）も表示
            actions = {
              -- 標準の explorer_yank は setreg を直に呼ぶため TextYankPost が発火せず、
              -- autocmds.lua の yank_to_clipboard に乗らない。自前で無名レジスタと + の両方に入れる
              yank_path_clipboard = function(picker)
                local paths = {}
                for _, item in ipairs(picker:selected({ fallback = true })) do
                  paths[#paths + 1] = Snacks.picker.util.path(item)
                end
                if #paths == 0 then
                  return
                end
                local text = table.concat(paths, "\n")
                local regtype = #paths == 1 and "c" or "l"
                vim.fn.setreg('"', text, regtype)
                vim.fn.setreg("+", text, regtype)
                Snacks.notify.info(("Yanked %d path(s)"):format(#paths))
              end,
            },
            win = {
              list = {
                keys = {
                  ["y"] = { "yank_path_clipboard", mode = { "n", "x" } },
                },
              },
            },
          },
          git_log_file = {
            focus = "list", -- Default focus to the list
            win = {
              list = {
                keys = {
                  ["o"] = "git_checkout",
                },
              },
            },
          },
        },
      },
    },
  },
}
