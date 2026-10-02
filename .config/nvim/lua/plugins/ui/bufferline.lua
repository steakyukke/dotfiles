return {
  "akinsho/bufferline.nvim",
  opts = function(_, opts)
    local nb = require("config.nb")
    opts.options = opts.options or {}
    opts.options.name_formatter = function(buf)
      local title = nb.get_title(buf.path)
      return title or buf.name
    end
    -- タブ（バッファ）を閉じるのは中クリックだけにする。
    -- LazyVim 既定の右クリックで閉じる（right_mouse_command）は無効化する。
    -- herdr 内では右クリックが herdr のペインメニューに取られて nvim まで届かず、
    -- herdr の外でだけ効くと挙動が揃わないため。nil だと bufferline 既定の "bdelete! %d" に戻るので false を入れる。
    opts.options.middle_mouse_command = function(n)
      Snacks.bufdelete(n)
    end
    opts.options.right_mouse_command = false
  end,
}
