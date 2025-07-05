-- Fuzzy finder. Loaded by its keys, so a session that never searches never
-- pays for it.
--
-- Chosen over telescope.nvim because the filtering happens in the fzf process
-- rather than in Lua on the UI thread; on a repository with a hundred thousand
-- files that is the difference between a usable picker and a stuttering one.
-- The cost is that it needs the fzf binary, which the package manifest already
-- installs for the shell.
return {
  "ibhagwan/fzf-lua",
  cmd = "FzfLua",
  keys = {
    { "<leader>ff", "<cmd>FzfLua files<cr>", desc = "Find files" },
    { "<leader>fg", "<cmd>FzfLua live_grep<cr>", desc = "Grep in project" },
    { "<leader>fb", "<cmd>FzfLua buffers<cr>", desc = "Buffers" },
    { "<leader>fh", "<cmd>FzfLua helptags<cr>", desc = "Help tags" },
    { "<leader>fr", "<cmd>FzfLua resume<cr>", desc = "Resume last picker" },
    { "<leader>fd", "<cmd>FzfLua diagnostics_workspace<cr>", desc = "Diagnostics" },
  },
  opts = {
    winopts = {
      height = 0.8,
      width = 0.9,
      preview = { layout = "vertical", vertical = "down:45%" },
    },
    files = {
      -- rg respects .gitignore and is installed by the manifest; the default
      -- `find` fallback walks node_modules.
      cmd = "rg --files --hidden --glob '!.git/'",
    },
  },
}
