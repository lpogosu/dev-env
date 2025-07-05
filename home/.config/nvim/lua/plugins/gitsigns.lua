-- Sign column git status, hunk staging and blame.
--
-- The one plugin here that loads on opening a file rather than on a key,
-- because its whole value is being visible before it is asked for. BufReadPre
-- rather than VeryLazy so the signs are there on the first paint instead of
-- appearing a moment later.
return {
  "lewis6991/gitsigns.nvim",
  event = { "BufReadPre", "BufNewFile" },
  opts = {
    signs = {
      add = { text = "+" },
      change = { text = "~" },
      delete = { text = "_" },
      topdelete = { text = "‾" },
      changedelete = { text = "≃" },
    },
    -- Inline blame is off: it re-runs `git blame` on every cursor move and puts
    -- a name at the end of the line being edited. <leader>gb answers the same
    -- question when it is asked.
    current_line_blame = false,
    on_attach = function(buffer)
      local gs = require("gitsigns")
      local function map(mode, lhs, rhs, desc)
        vim.keymap.set(mode, lhs, rhs, { buffer = buffer, desc = desc })
      end

      map("n", "]h", function()
        gs.nav_hunk("next")
      end, "Next hunk")
      map("n", "[h", function()
        gs.nav_hunk("prev")
      end, "Previous hunk")

      map("n", "<leader>gs", gs.stage_hunk, "Stage hunk")
      map("n", "<leader>gr", gs.reset_hunk, "Reset hunk")
      map("n", "<leader>gp", gs.preview_hunk, "Preview hunk")
      map("n", "<leader>gb", function()
        gs.blame_line({ full = true })
      end, "Blame line")
      map("n", "<leader>gd", gs.diffthis, "Diff against index")
    end,
  },
}
