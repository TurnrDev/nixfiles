local M = {}
local rules = {}

---Remove the workspace rules installed by M.assign.
function M.clear()
  for _, rule in ipairs(rules) do
    rule:set_enabled(false)
  end
  rules = {}
end

---Find the monitor assigned to a numbered workspace.
---
---Workspace 1 is permanently assigned to the first (left-hand) monitor.
---All subsequent workspaces cycle through the remaining monitors.
---@param workspace integer
---@param monitors string[]
---@return string
local function workspace_monitor(workspace, monitors)
  if workspace == 1 or #monitors == 1 then
    return monitors[1]
  end

  return monitors[2 + ((workspace - 2) % (#monitors - 1))]
end

---Bind numbered workspaces to monitors with workspace 1 pinned left.
---
---With three monitors, the first monitor owns workspace 1; the second owns
---2, 4, 6, ...; and the third owns 3, 5, 7, .... Workspace rules take effect
---when a workspace is created, so workspaces do not need to exist when this
---function is called.
---@param monitors string[]
---@param workspace_count? integer
function M.assign(monitors, workspace_count)
  M.clear()

  for workspace = 1, workspace_count or 36 do
    rules[#rules + 1] = hl.workspace_rule({
      workspace = tostring(workspace),
      monitor = workspace_monitor(workspace, monitors),
    })
  end
end

---Install workspace assignments and reconcile workspaces that already exist.
---@param monitors string[]
---@param workspace_count? integer
function M.apply(monitors, workspace_count)
  M.assign(monitors, workspace_count)

  for _, workspace in ipairs(hl.get_workspaces()) do
    if not workspace.special and workspace.id > 0 then
      local monitor = hl.get_monitor(workspace_monitor(workspace.id, monitors))

      if monitor and (not workspace.monitor or workspace.monitor.name ~= monitor.name) then
        hl.dispatch(hl.dsp.workspace.move({
          workspace = workspace,
          monitor = monitor,
        }))
      end
    end
  end
end

return M
