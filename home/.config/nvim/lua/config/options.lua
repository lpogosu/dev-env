-- Editor options.

local opt = vim.opt

vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

opt.number = true
opt.relativenumber = true
opt.signcolumn = "yes" -- always reserved, so the text does not jump when a sign appears
opt.cursorline = true
opt.colorcolumn = "80,100"
opt.scrolloff = 4
opt.sidescrolloff = 8
opt.wrap = false

opt.expandtab = true
opt.shiftwidth = 4
opt.tabstop = 4
opt.softtabstop = 4
opt.shiftround = true
opt.smartindent = true

opt.ignorecase = true
opt.smartcase = true -- an uppercase letter in the pattern turns the search case-sensitive
opt.incsearch = true
opt.hlsearch = true

opt.splitbelow = true
opt.splitright = true
opt.splitkeep = "screen" -- opening a split does not scroll the window that was already there

-- Persistent undo across sessions. The file lives under the state directory,
-- not next to the source, so it never ends up in a commit.
opt.undofile = true
opt.undolevels = 10000
opt.swapfile = false -- undofile covers recovery; swap files only produce stale-lock prompts
opt.backup = false
opt.writebackup = false

opt.updatetime = 250 -- CursorHold, and how quickly gitsigns redraws
opt.timeoutlen = 400
opt.termguicolors = true
opt.mouse = "a"
opt.clipboard = "" -- explicit yanks only; see the keymaps for "+y

opt.completeopt = { "menu", "menuone", "noselect" }
opt.pumheight = 12
opt.winborder = "rounded"

opt.list = true
opt.listchars = { tab = "› ", trail = "·", nbsp = "␣", extends = "›", precedes = "‹" }
opt.fillchars = { eob = " " }

opt.confirm = true -- :q on a modified buffer asks instead of failing
opt.laststatus = 3 -- one status line for the whole window layout

opt.grepprg = "rg --vimgrep --smart-case"
opt.grepformat = "%f:%l:%c:%m"

vim.cmd.colorscheme("retrobox")
