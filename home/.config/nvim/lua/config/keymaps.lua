-- Mappings that do not belong to a plugin. Plugin mappings are declared in the
-- plugin's own spec, so that the mapping is what triggers the plugin to load.

local map = vim.keymap.set

-- Clear the search highlight and redraw. <C-l> already redraws, so this only
-- adds to a key that is never used for anything else.
local redraw = "<cmd>nohlsearch<bar>diffupdate<bar>normal! <C-l><cr>"
map("n", "<C-l>", redraw, { desc = "Redraw and clear search" })

-- Move between windows without the prefix.
map("n", "<C-h>", "<C-w>h")
map("n", "<C-j>", "<C-w>j")
map("n", "<C-k>", "<C-w>k")
map("n", "<C-w>l", "<C-w>l") -- <C-l> is taken above; the prefixed form still works

-- Keep the cursor in place while joining, and centre the view when jumping by
-- half a page or between search matches.
map("n", "J", "mzJ`z")
map("n", "<C-d>", "<C-d>zz")
map("n", "<C-u>", "<C-u>zz")
map("n", "n", "nzzzv")
map("n", "N", "Nzzzv")

-- Move the selected block and reindent it.
map("v", "J", ":m '>+1<cr>gv=gv", { desc = "Move selection down" })
map("v", "K", ":m '<-2<cr>gv=gv", { desc = "Move selection up" })

-- Keep the register when pasting over a selection: the default swaps the
-- unnamed register for the text that was replaced, so a second paste pastes
-- the wrong thing.
map("x", "<leader>p", [["_dP]], { desc = "Paste without clobbering the register" })

-- The system clipboard is opt-in. clipboard=unnamedplus makes every delete in
-- the editor overwrite what was copied from the browser.
map({ "n", "v" }, "<leader>y", [["+y]], { desc = "Yank to system clipboard" })
map("n", "<leader>Y", [["+Y]], { desc = "Yank line to system clipboard" })

-- Diagnostics.
map("n", "<leader>e", vim.diagnostic.open_float, { desc = "Line diagnostics" })
map("n", "<leader>q", vim.diagnostic.setloclist, { desc = "Diagnostics to loclist" })

-- Quickfix, which is where grepprg and the LSP put their results.
map("n", "<leader>co", "<cmd>copen<cr>", { desc = "Open quickfix" })
map("n", "]q", "<cmd>cnext<cr>zz", { desc = "Next quickfix item" })
map("n", "[q", "<cmd>cprev<cr>zz", { desc = "Previous quickfix item" })

map("t", "<Esc><Esc>", [[<C-\><C-n>]], { desc = "Leave terminal mode" })
