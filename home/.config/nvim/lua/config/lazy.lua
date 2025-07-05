-- Plugin manager.
--
-- lazy.nvim is installed by bootstrap.sh, not by this file. The usual bootstrap
-- snippet clones the manager the first time the editor starts, which means the
-- editor reaches the network on a machine where that was not expected, at the
-- worst possible moment. Here the editor never clones anything: install.missing
-- is false, the update checker is off, and plugin code changes only when
-- `bootstrap.sh` runs `Lazy! restore` against the tracked lockfile.

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

if not vim.uv.fs_stat(lazypath) then
  vim.notify(
    "lazy.nvim is not installed. Run bootstrap.sh; the editor does not install plugins itself.",
    vim.log.levels.WARN
  )
  return
end

vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  spec = { { import = "plugins" } },
  install = { missing = false },
  checker = { enabled = false },
  change_detection = { enabled = false },
  ui = { border = "rounded" },
  performance = {
    rtp = {
      -- Built-in plugins this configuration replaces or does not use. Each one
      -- is a file Neovim would otherwise source at every start.
      disabled_plugins = {
        "gzip",
        "netrwPlugin",
        "tarPlugin",
        "tohtml",
        "tutor",
        "zipPlugin",
      },
    },
  },
})
