local group = vim.api.nvim_create_augroup("devenv", { clear = true })

-- Highlight what was just yanked. The only way to see the extent of a motion
-- that has already happened.
vim.api.nvim_create_autocmd("TextYankPost", {
  group = group,
  callback = function()
    vim.hl.on_yank({ timeout = 150 })
  end,
})

-- Reopen a file at the line it was left on, unless that line no longer exists
-- or the buffer is one where a saved position is meaningless.
vim.api.nvim_create_autocmd("BufReadPost", {
  group = group,
  callback = function(event)
    local exclude = { "gitcommit", "gitrebase", "help" }
    if vim.tbl_contains(exclude, vim.bo[event.buf].filetype) then
      return
    end
    local mark = vim.api.nvim_buf_get_mark(event.buf, '"')
    if mark[1] > 0 and mark[1] <= vim.api.nvim_buf_line_count(event.buf) then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})

-- Trailing whitespace is removed on request, not on every write. Stripping the
-- whole buffer automatically turns a one-line change into a diff of the entire
-- file whenever the repository was not already clean.
vim.api.nvim_create_user_command("TrimWhitespace", function()
  local view = vim.fn.winsaveview()
  vim.cmd([[keeppatterns %s/\s\+$//e]])
  vim.fn.winrestview(view)
end, { desc = "Remove trailing whitespace" })

-- Create the parent directory when writing to a path that does not exist yet.
vim.api.nvim_create_autocmd("BufWritePre", {
  group = group,
  callback = function(event)
    if event.match:match("^%w%w+://") then
      return -- a URL-like path belongs to a netrw-style handler, not to mkdir
    end
    local dir = vim.fn.fnamemodify(vim.uv.fs_realpath(event.match) or event.match, ":p:h")
    vim.fn.mkdir(dir, "p")
  end,
})

-- Treesitter highlighting for the parsers Neovim ships with. There is no
-- treesitter plugin here: installing parsers per machine needs a C compiler on
-- every machine, and the bundled set already covers the filetypes this
-- configuration itself is written in.
vim.api.nvim_create_autocmd("FileType", {
  group = group,
  pattern = { "lua", "vim", "vimdoc", "query", "markdown", "c" },
  callback = function(event)
    pcall(vim.treesitter.start, event.buf)
  end,
})

-- A terminal buffer has no line numbers to speak of and no sign column.
vim.api.nvim_create_autocmd("TermOpen", {
  group = group,
  callback = function()
    vim.opt_local.number = false
    vim.opt_local.relativenumber = false
    vim.opt_local.signcolumn = "no"
  end,
})
