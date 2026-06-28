require("generated")
require("config.core")

-- DMS owns these writable visual fragments. Monitor configuration remains
-- Nix-backed by config.core, with DMS outputs taking runtime precedence.
require("dms.colors")
require("dms.layout")
require("dms.outputs")
require("dms.cursor")

require("config.rules")
require("config.binds")

-- User-managed rules from DMS take final precedence.
require("dms.windowrules")
