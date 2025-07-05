-- Language servers.
--
-- No nvim-lspconfig. Since 0.11 Neovim has `vim.lsp.config` and
-- `vim.lsp.enable`, which is most of what lspconfig wrapped; four servers with
-- three lines of settings between them do not need a dependency with a
-- thousand of them.
--
-- The one piece of logic worth having: a server is only enabled when its binary
-- exists on this machine. An enabled server that cannot start reports a failure
-- on every buffer that matches its filetypes, which is how "my editor is broken"
-- reports usually begin.

local servers = {
  lua_ls = {
    cmd = { "lua-language-server" },
    filetypes = { "lua" },
    root_markers = { ".luarc.json", "stylua.toml", ".git" },
    settings = {
      Lua = {
        runtime = { version = "LuaJIT" },
        workspace = { checkThirdParty = false },
        -- Without this every reference to `vim` in a Neovim config is an
        -- undefined-global warning.
        diagnostics = { globals = { "vim" } },
        telemetry = { enable = false },
      },
    },
  },
  pyright = {
    cmd = { "pyright-langserver", "--stdio" },
    filetypes = { "python" },
    root_markers = { "pyproject.toml", "setup.cfg", "requirements.txt", ".git" },
  },
  gopls = {
    cmd = { "gopls" },
    filetypes = { "go", "gomod" },
    root_markers = { "go.work", "go.mod", ".git" },
  },
  bashls = {
    cmd = { "bash-language-server", "start" },
    filetypes = { "sh", "bash" },
    root_markers = { ".git" },
  },
}

for name, definition in pairs(servers) do
  vim.lsp.config(name, definition)
  if vim.fn.executable(definition.cmd[1]) == 1 then
    vim.lsp.enable(name)
  end
end

vim.diagnostic.config({
  severity_sort = true,
  underline = { severity = vim.diagnostic.severity.ERROR },
  -- Virtual text on every line turns a file with twenty warnings into a file
  -- that cannot be read. The sign column says a diagnostic is there; <leader>e
  -- says what it is.
  virtual_text = false,
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = "E",
      [vim.diagnostic.severity.WARN] = "W",
      [vim.diagnostic.severity.INFO] = "I",
      [vim.diagnostic.severity.HINT] = "H",
    },
  },
  float = { border = "rounded", source = true },
})

vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("devenv-lsp", { clear = true }),
  callback = function(event)
    local function map(lhs, rhs, desc)
      vim.keymap.set("n", lhs, rhs, { buffer = event.buf, desc = desc })
    end
    map("grn", vim.lsp.buf.rename, "Rename symbol")
    map("gra", vim.lsp.buf.code_action, "Code action")
    map("grr", vim.lsp.buf.references, "References")
    map("gd", vim.lsp.buf.definition, "Go to definition")
    map("K", vim.lsp.buf.hover, "Hover")
  end,
})
