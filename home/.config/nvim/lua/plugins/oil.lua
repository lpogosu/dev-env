-- File management as a buffer: rename, move and delete by editing lines and
-- writing.
--
-- netrw is disabled in config/lazy.lua, so this replaces it rather than sitting
-- next to it. A tree sidebar was the alternative and lost: a sidebar is a
-- second, permanent representation of the file system that has to be kept in
-- sync, while this is the directory the current file is in, opened with `-`.
return {
  "stevearc/oil.nvim",
  cmd = "Oil",
  keys = {
    { "-", "<cmd>Oil<cr>", desc = "Open parent directory" },
  },
  opts = {
    default_file_explorer = true,
    delete_to_trash = false, -- there is no trash on a server
    skip_confirm_for_simple_edits = false,
    view_options = { show_hidden = true },
    keymaps = {
      ["q"] = "actions.close",
      ["<C-h>"] = false, -- window navigation wins over oil's split mapping
    },
  },
}
