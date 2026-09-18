-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

local keymap = vim.keymap.set
local keydel = vim.keymap.del

local opts = { noremap = true, silent = true }
local util = require("lazyvim.util")

-- p/P: 無名レジスタからペースト（d/c で削除したものを貼り付け可能）
-- クリップボードからペーストしたい場合は "+p を使う
-- y はクリップボードにも入る（autocmds.lua の TextYankPost で制御）

-- emacs like keybind
keymap("i", "<C-a>", "<Home>", opts)
keymap("i", "<C-e>", "<End>", opts)

-- Control + I と Tab をデフォルトの状態に戻す
vim.api.nvim_set_keymap("n", "<C-i>", "<C-i>", { noremap = true })
vim.api.nvim_set_keymap("i", "<C-i>", "<C-i>", { noremap = true })

-- Increment / Decrement
keymap("n", "+", "<C-a>", opts)
keymap("n", "-", "<C-x>", opts)

-- Tab
keymap("n", "<tab>", ":tabnext<Return>", opts)
keymap("n", "<s-tab>", ":tabprev<Return>", opts)

-- Split window
keymap("n", "ss", ":split<Return>", opts)
keymap("n", "sv", ":vsplit<Return>", opts)
-- Move window
keymap("n", "sh", "<C-w>h")
keymap("n", "sk", "<C-w>k")
keymap("n", "sj", "<C-w>j")
keymap("n", "sl", "<C-w>l")
-- Resize window
keymap("n", "<C-w><left>", "<C-w><")
keymap("n", "<C-w><right>", "<C-w>>")
keymap("n", "<C-w><up>", "<C-w>+")
keymap("n", "<C-w><down>", "<C-w>-")

-- Diagnostics
keymap("n", "<C-j>", function()
  vim.diagnostic.goto_next()
end, opts)

-- lazydocker
if vim.fn.executable("lazydocker") == 1 then
  vim.keymap.set("n", "<leader>d", function()
    util.terminal("lazydocker", { esc_esc = false, ctrl_hjkl = false, border = "rounded" })
  end, { desc = "LazyDocker" })
end

-- terminal
keymap("n", "<c-/>", function()
  Snacks.terminal()
end, { desc = "Terminal (Root Dir)" })
keymap("n", "<c-_>", function()
  Snacks.terminal(nil, { cwd = LazyVim.root() })
end, { desc = "Terminal (cwd)" })

-- disable default keymappings
keydel("n", "<leader>ft", { desc = "Terminal (cwd)" })
keydel("n", "<leader>fT", { desc = "Terminal (root)" })

-- Notification History: <leader>n -> <leader>nn
keydel("n", "<leader>n")
keymap("n", "<leader>nn", function()
  Snacks.notifier.show_history()
end, { desc = "Notification History" })

-- Get git root from current buffer
local function get_git_root()
  local buf_dir = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":h")
  -- vim.fn.systemlist の代わりに vim.system + タイムアウトでハング防止
  local result = vim.system(
    { "git", "-C", buf_dir, "rev-parse", "--show-toplevel" },
    { text = true, timeout = 3000 }
  ):wait()
  return (result.code == 0 and vim.trim(result.stdout)) or LazyVim.root.get({ buf = 0 })
end

-- Swap LazyGit keymaps (gg: cwd, gG: root)
keymap("n", "<leader>gg", function()
  Snacks.lazygit({ cwd = vim.fn.getcwd() })
end, { desc = "LazyGit (cwd)" })
keymap("n", "<leader>gG", function()
  Snacks.lazygit({ cwd = get_git_root() })
end, { desc = "LazyGit (Root Dir)" })

-- Find Files from project root
-- hidden / ignored は plugins/base/snacks.lua の sources.files / sources.grep で常時 ON
keymap("n", "<leader><leader>", function()
  Snacks.picker.files({ cwd = get_git_root() })
end, { desc = "Find Files (Root Dir)" })

-- Grep from project root
keymap("n", "<leader>/", function()
  Snacks.picker.grep({ cwd = get_git_root() })
end, { desc = "Grep (Root Dir)" })

-- browse under cursor
keymap("n", "gh", function()
  local cfile = vim.fn.expand("<cfile>")
  if cfile:match("^https?://") then
    vim.system({ "open", cfile }) -- for macOS（os.executeのブロッキング回避）
  else
    vim.cmd("normal! gF!")
  end
end, { desc = "link open" })

-- gx: open URL or AWS ARN in browser
keymap("n", "gx", function()
  local cword = vim.fn.expand("<cWORD>")
  local cfile = vim.fn.expand("<cfile>")
  local arn = cword:match("[\"`']?(arn:aws[a-z%-]*:[^\"`'%s]+)[\"`']?")
  if arn then
    vim.ui.open("https://console.aws.amazon.com/go/view?arn=" .. arn)
  else
    vim.ui.open(cfile)
  end
end, { desc = "Open URL or AWS ARN" })

-- browse github repogitory
keymap("n", "<leader>gR", function()
  local github_repogitory_name = vim.fn.expand("<cfile>")
  if github_repogitory_name:match(".+/[^/]+") then
    vim.system({ "open", "https://github.com/" .. github_repogitory_name }) -- for macOS（os.executeのブロッキング回避）
  else
    vim.cmd("normal!, gF!")
  end
end, { desc = "GitHub repogitory" })

-- substitution word under cursor
keymap("n", "#", function()
  local current_word = vim.fn.expand("<cword>")
  vim.api.nvim_feedkeys(":%s/" .. current_word .. "//g", "n", false)
  -- :%s/word/CURSOR/g
  local ll = vim.api.nvim_replace_termcodes("<Left><Left>", true, true, true)
  vim.api.nvim_feedkeys(ll, "n", false)
  vim.opt.hlsearch = true
end, { desc = "substitusion word under cursor" })

-- say command
keymap("n", "<leader>say", function()
  local current_word = vim.fn.expand("<cword>")
  vim.api.nvim_feedkeys(":!say -v Ava " .. current_word .. "\n", "n", false)
end, { desc = "say command" })

-- Codex stash: バッファ内容を保存してクリア（Codex Ctrl+G 連携）
vim.keymap.set("n", "<leader>S", function()
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local content = table.concat(lines, "\n")
  local stash_file = vim.fn.expand("~/.local/share/codex_stash.txt")
  local f = io.open(stash_file, "w")
  if f then
    f:write(content)
    f:close()
    vim.api.nvim_buf_set_lines(0, 0, -1, false, {})
    vim.notify("Stashed to " .. stash_file, vim.log.levels.INFO)
  end
end, { desc = "Stash buffer to codex_stash.txt and clear" })

-- zz -> z -> z cycle: center -> top -> bottom -> center ...
-- ref: https://zenn.dev/vim_jp/articles/67ec77641af3f2
local zz_state = { pos = 0, last_time = 0 }

keymap("n", "zz", function()
  zz_state.pos = 1
  zz_state.last_time = vim.loop.now()
  vim.cmd("normal! zz")
end, { desc = "Scroll center (then z to cycle)" })

keymap("n", "z", function()
  local now = vim.loop.now()
  -- 1秒以内かつzzの後なら次の位置へ
  if zz_state.pos > 0 and (now - zz_state.last_time) < 1000 then
    zz_state.last_time = now
    zz_state.pos = (zz_state.pos % 3) + 1
    if zz_state.pos == 1 then
      vim.cmd("normal! zz")
    elseif zz_state.pos == 2 then
      vim.cmd("normal! zt")
    else
      vim.cmd("normal! zb")
    end
  else
    -- 通常のz（次のキーを待つ）
    zz_state.pos = 0
    local char = vim.fn.getcharstr()
    vim.cmd("normal! z" .. char)
  end
end, { desc = "Cycle scroll after zz / normal z commands" })

-- Ctrl+Shift+W は WezTerm 側でも未割当（タブを閉じる誤爆防止）。Neovim でも何もしない
keymap({ "n", "i", "v", "t" }, "<C-S-w>", "<Nop>", opts)

-- Alt+V で矩形ビジュアル（Ctrl+V をターミナル側に取られた環境との互換。<C-q> は WezTerm の LEADER）
keymap({ "n", "v" }, "<M-v>", "<C-v>", opts)

-- yp / yP: 編集中ファイルのパスをヤンク（絶対 / LazyVim.root() からの相対）
-- o（オペレータ待ち）モードに置く理由: which-key の「+Yank」パネルは o モードのツリーで、
-- n モードに置くと一覧に載らず、y 単独のたびに timeoutlen 待ちが発生する
local function yank_path(relative)
  return function()
    -- v:operator / v:register は <Esc> より前に読む
    local operator, reg = vim.v.operator, vim.v.register
    -- オペレータ待ちを抜ける（抜けないと次のキーがモーションとして食われる）
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "n", false)
    -- o モードのツリーは全オペレータ共通なので dp / cp では何もしない
    if operator ~= "y" then
      return
    end
    local path = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":p")
    if relative then
      local root = LazyVim.root() .. "/"
      if path:sub(1, #root) == root then
        path = path:sub(#root + 1)
      end
    end
    -- 中断された y が無名レジスタを空で上書きするため schedule 越しに書く
    vim.schedule(function()
      vim.fn.setreg('"', path)
      vim.fn.setreg("+", path)
      if reg ~= '"' and reg ~= "" then
        vim.fn.setreg(reg, path)
      end
      vim.notify("Yanked: " .. path)
    end)
  end
end
keymap("o", "p", yank_path(false), { desc = "Yank file path (absolute)" })
keymap("o", "P", yank_path(true), { desc = "Yank file path (relative to root)" })
