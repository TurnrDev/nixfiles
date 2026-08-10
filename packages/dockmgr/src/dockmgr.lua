local M = {}

local function shell_quote(value)
  return "'" .. value:gsub("'", "'\\\\''") .. "'"
end

local function jq_lines(jq, config_path, profile_id, filter)
  local command = table.concat({
    jq,
    "-er",
    "--arg profile", shell_quote(profile_id),
    shell_quote(filter),
    shell_quote(config_path),
  }, " ")
  local pipe, error_message = io.popen(command, "r")

  if not pipe then
    error("dockmgr: unable to read profile: " .. error_message)
  end

  return pipe
end

local function profile_outputs(jq, config_path, profile_id)
  local filter = [[
    .profiles[]
    | select(.id == $profile)
    | .outputs
    | to_entries[]
    | [
        .key,
        (.value.mode // "preferred"),
        (.value.position.x // 0),
        (.value.position.y // 0),
        (.value.scale // 1),
        (.value.disabled // false)
      ]
    | @tsv
  ]]
  local pipe = jq_lines(jq, config_path, profile_id, filter)
  local outputs = {}

  for line in pipe:lines() do
    local fields = {}
    for field in (line .. "\t"):gmatch("(.-)\t") do
      fields[#fields + 1] = field
    end

    if #fields ~= 6 then
      pipe:close()
      error("dockmgr: invalid output record for profile " .. profile_id)
    end

    outputs[#outputs + 1] = {
      output = fields[1],
      mode = fields[2],
      position_x = tonumber(fields[3]),
      position_y = tonumber(fields[4]),
      scale = tonumber(fields[5]),
      disabled = fields[6] == "true",
    }
  end

  pipe:close()

  return outputs
end

local function disables_unconfigured_outputs(jq, config_path, profile_id)
  local filter = [[
    .profiles[]
    | select(.id == $profile)
    | .disableUnspecifiedOutputs // true
  ]]
  local pipe = jq_lines(jq, config_path, profile_id, filter)
  local value = pipe:read("*l")

  pipe:close()
  if value == nil then
    error("dockmgr: failed to read profile " .. profile_id)
  end

  return value == "true"
end

local function output_matches_monitor(output, monitor)
  return output == monitor.name or output == "desc:" .. monitor.description
end

local function monitor_for_output(output)
  for _, monitor in ipairs(hl.get_monitors()) do
    if output_matches_monitor(output, monitor) then
      return monitor
    end
  end

  return nil
end

local function monitor_matches_output(monitor, output)
  if output.disabled then
    return monitor == nil
  end

  if monitor == nil or output.mode == "preferred" then
    return false
  end

  local width, height, refresh_rate = output.mode:match("^(%d+)x(%d+)@([%d.]+)$")
  if width == nil then
    return false
  end

  return monitor.width == tonumber(width)
    and monitor.height == tonumber(height)
    and math.abs(monitor.refresh_rate - tonumber(refresh_rate)) < 0.05
    and monitor.position.x == output.position_x
    and monitor.position.y == output.position_y
    and math.abs(monitor.scale - output.scale) < 0.001
end

---Apply a dockmgr profile by ID using Hyprland's native monitor API.
---@param profile_id string
---@param config_path? string
---@param jq? string
function M.apply(profile_id, config_path, jq)
  config_path = config_path or "/etc/dockmgr/config.json"
  jq = jq or "jq"
  local outputs = profile_outputs(jq, config_path, profile_id)

  for _, output in ipairs(outputs) do
    if not monitor_matches_output(monitor_for_output(output.output), output) then
      local monitor = {
        output = output.output,
        disabled = output.disabled,
      }

      if not output.disabled then
        monitor.mode = output.mode
        monitor.position = output.position_x .. "x" .. output.position_y
        monitor.scale = output.scale
      end

      hl.monitor(monitor)
    end
  end

  if disables_unconfigured_outputs(jq, config_path, profile_id) then
    for _, monitor in ipairs(hl.get_monitors()) do
      local configured = false

      for _, output in ipairs(outputs) do
        if output_matches_monitor(output.output, monitor) then
          configured = true
          break
        end
      end

      if not configured then
        hl.monitor({ output = monitor.name, disabled = true })
      end
    end
  end
end

_G.dockmgr = M
