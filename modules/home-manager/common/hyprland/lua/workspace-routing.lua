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
  -- Moving the active workspace from Hyprland's focused monitor also moves
  -- focus.  Remember each monitor's visible workspace so routing does not
  -- leave every output showing whichever workspace happened to be moved last.
  local visible_workspaces = {}
  local focused_workspace = hl.get_active_workspace()

  for _, monitor in ipairs(hl.get_monitors()) do
    local workspace = monitor.active_workspace
    if workspace and not workspace.special and workspace.id > 0 then
      visible_workspaces[#visible_workspaces + 1] = workspace.id
    end
  end

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

  -- A workspace has one routed destination.  On a profile that reduces the
  -- number of monitors, more than one previously visible workspace can map to
  -- the same destination; retaining the last one is the only representable
  -- result.  Normal postUp transitions add monitors, preserving all of them.
  local active_workspaces = {}
  for _, workspace_id in ipairs(visible_workspaces) do
    local monitor = hl.get_monitor(workspace_monitor(workspace_id, monitors))
    if monitor then
      active_workspaces[monitor.name] = workspace_id
    end
  end

  for _, monitor in ipairs(hl.get_monitors()) do
    local workspace_id = active_workspaces[monitor.name]
    if workspace_id and (not monitor.active_workspace or monitor.active_workspace.id ~= workspace_id) then
      monitor:set_workspace({ workspace = tostring(workspace_id) })
    end
  end

  -- set_workspace restores each monitor independently but can alter keyboard
  -- focus.  Restore the workspace the user was interacting with last.
  if focused_workspace and not focused_workspace.special and focused_workspace.id > 0 then
    local workspace = hl.get_workspace(tostring(focused_workspace.id))
    if workspace then
      hl.dispatch(hl.dsp.focus({ workspace = workspace }))
    end
  end
end

return M
