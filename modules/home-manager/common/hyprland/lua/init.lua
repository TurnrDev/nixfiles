require("generated")
require("config.core")

-- DMS owns these writable visual fragments. Monitor configuration remains
-- Nix-owned and is applied by config.core from generated.lua.
require("dms.colors")
require("dms.layout")
require("dms.cursor")

require("config.rules")
require("config.binds")

-- User-managed rules from DMS take final precedence.
require("dms.windowrules")
