-- Entry point.
--
-- Order matters: options first because some plugins read them while loading,
-- then the plugin manager, then everything that does not depend on a plugin.
require("config.options")
require("config.lazy")
require("config.keymaps")
require("config.autocmds")
require("config.lsp")
