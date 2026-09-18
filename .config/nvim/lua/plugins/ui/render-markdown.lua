-- render-markdown.nvim の表に「行と行のあいだの横罫線」を足す。
--
-- 本体には行区切りを描く設定が無い。pipe_table.border が持つのは
-- 上端 3 文字・区切り行 3 文字・下端 3 文字 + 縦線 + 横線の 11 文字だけで、
-- データ行どうしの境界は描かれない。
--
-- そこで描画クラス render.markdown.table の run() を包み、本体が計算した
-- 列幅（self.data.cols）をそのまま使って行間に仮想行を 1 本足す。
-- 列幅を自前で計算しないので、padding や cell の設定を変えても追従する。
-- ハイライトも本体の縦線と同じ config.row を使うので、見た目は縦線に揃う。

-- 罫線の文字。左端・交点・右端・横線の順。
local SEP = { left = "├", cross = "┼", right = "┤", fill = "─" }

---本体の描画が終わった表に、データ行のあいだの横罫線を足す
---@param self table render.md.render.Table のインスタンス
local function row_separators(self)
  local config, data = self.config, self.data
  -- layout.valid が false のときは本体も上下の枠線を諦めている（列がずれている）
  if not (data and data.layout and data.layout.valid) then
    return
  end

  local parts = {}
  for i, col in ipairs(data.cols) do
    parts[i] = SEP.fill:rep(col.width)
  end
  local text = SEP.left .. table.concat(parts, SEP.cross) .. SEP.right

  -- セルが折り返される行は、本体が marks:replace で行ごと仮想行に置き換えている。
  -- 元の行は conceal され、conceal された行に付けた仮想行は Neovim 側で消えるので、
  -- そういう行には置き換え後の末尾に足す（本体が下端の枠線を足すのと同じやり方）。
  local replaced = {}
  for _, mark in ipairs(self.marks:get()) do
    if mark.replace then
      replaced[mark.start_row] = mark.replace
    end
  end

  -- rows[1] はヘッダ行で、その直下はもともと区切り行。最終行の下は下端の枠線。
  -- よって罫線を引くのは 2 番目から最後の 1 つ前まで（データ行が 1 行なら 0 回）。
  local rows = data.rows
  for i = 2, #rows - 1 do
    local start_row = rows[i].node.start_row
    local line = self:line():pad(data.layout.col):text(text, config.row)
    local virtual = self:indent():line(true):extend(line):get()
    local lines = replaced[start_row]
    if lines then
      lines[#lines + 1] = virtual
    else
      self.marks:add(config, "virtual_lines", start_row, 0, {
        virt_lines = { virtual },
        virt_lines_above = false,
      })
    end
  end
end

---render.markdown.table の run() を 1 回だけ包む
local function patch()
  local ok, render = pcall(require, "render-markdown.render.markdown.table")
  if not ok or type(render.run) ~= "function" or render.row_separator_patched then
    return
  end
  local run = render.run
  render.run = function(self)
    run(self)
    -- 本体の内部構造に触っているので、更新で形が変わっても
    -- 罫線が出なくなるだけで描画自体は壊れないようにする
    pcall(row_separators, self)
  end
  render.row_separator_patched = true
end

return {
  -- 本体は LazyVim の lang.markdown extra が入れている。
  -- optional = true なので、その extra を外したらこの spec ごと無効になる。
  "MeanderingProgrammer/render-markdown.nvim",
  optional = true,
  -- config ではなく opts で当てているのは、LazyVim 側の config
  --（setup + <leader>um のトグル登録）を上書きしないため。
  -- opts の関数はプラグインが rtp に載ったあとに評価されるので require できる。
  opts = function(_, opts)
    patch()
    return opts
  end,
}
