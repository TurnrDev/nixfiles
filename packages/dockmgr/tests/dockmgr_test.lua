local source_path, jq = ...

local config_path = os.tmpname()
local state_path = os.tmpname()
local calls = {}
local monitors = {}

local function write_file(path, content)
  local file = assert(io.open(path, "w"))
  file:write(content)
  file:close()
end

local function assert_equal(actual, expected, message)
  if actual ~= expected then
    error(string.format("%s: expected %s, got %s", message, expected, actual))
  end
end

_G.hl = {
  get_monitors = function()
    return monitors
  end,
  monitor = function(configuration)
    calls[#calls + 1] = configuration
  end,
}

local dockmgr = assert(loadfile(source_path))()

write_file(config_path, [[
  {"profiles":[
    {"id":"dock","disableUnspecifiedOutputs":true,"outputs":{
      "DP-1":{"mode":"2560x1440@60","position":{"x":0,"y":0},"scale":1.0},
      "eDP-1":{"disabled":true}
    }},
    {"id":"description","disableUnspecifiedOutputs":true,"outputs":{
      "desc:Example Display":{"mode":"preferred","position":{"x":0,"y":0},"scale":1.0}
    }}
  ]}
]])

monitors = {
  { name = "DP-1", description = "External" },
  { name = "eDP-1", description = "Internal" },
  { name = "HDMI-A-1", description = "Unconfigured" },
}
calls = {}
dockmgr.apply("dock", config_path, jq)
assert_equal(#calls, 3, "enabled, disabled, and unspecified outputs must be configured")
assert_equal(calls[1].output, "DP-1", "enabled output target")
assert_equal(calls[1].mode, "2560x1440@60", "enabled output mode")
assert_equal(calls[2].output, "eDP-1", "disabled output target")
assert_equal(calls[2].disabled, true, "disabled output state")
assert_equal(calls[3].output, "HDMI-A-1", "unspecified output target")
assert_equal(calls[3].disabled, true, "unspecified output disabled")

monitors = { { name = "DP-1", description = "Example Display" } }
calls = {}
dockmgr.apply("description", config_path, jq)
assert_equal(#calls, 1, "description selectors must configure matching outputs")
assert_equal(calls[1].output, "desc:Example Display", "description selector retained")

calls = {}
assert_equal(dockmgr.restore(state_path, config_path, jq), false, "missing state must not restore")
write_file(state_path, "dock\n")
dockmgr.restore(state_path, config_path, jq)
assert_equal(#calls, 2, "saved profile restore must apply configured outputs")

assert(os.remove(config_path))
assert(os.remove(state_path))
