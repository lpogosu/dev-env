-- Formatting.
--
-- Format on demand, not on save. Formatting on save in a repository that is not
-- already formatted produces a diff nobody asked for, and in a repository that
-- is, the CI check is the thing that actually matters. `lsp_format = "fallback"`
-- means a filetype with no dedicated formatter still gets whatever the language
-- server offers.
return {
  "stevearc/conform.nvim",
  cmd = "ConformInfo",
  keys = {
    {
      "<leader>cf",
      function()
        require("conform").format({ async = true, lsp_format = "fallback" })
      end,
      mode = { "n", "v" },
      desc = "Format buffer or selection",
    },
  },
  opts = {
    formatters_by_ft = {
      lua = { "stylua" },
      python = { "ruff_format" },
      go = { "gofmt" },
      sh = { "shfmt" },
      json = { "jq" },
      yaml = { "yamlfmt" },
    },
    -- A formatter that is not installed is skipped rather than reported as an
    -- error: the same configuration runs on machines with different toolchains.
    default_format_opts = { lsp_format = "fallback" },
    notify_on_error = false,
  },
}
