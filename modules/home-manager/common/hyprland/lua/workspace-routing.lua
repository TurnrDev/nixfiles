local M = {}
local rules = {}

---Remove the workspace rules installed by M.assign.
function M.clear()
  for _, rule in ipairs(rules) do
    rule:set_enabled(false)
  end
  rules = {}
end

---Bind numbered workspaces to monitors in round-robin order.
---
---The first monitor owns workspaces 1, 4, 7, ..., the second 2, 5, 8, ...,
---and so on. Workspace rules take effect when a workspace is created, so
---workspaces do not need to exist when this function is called.
---@param monitors string[]
---@param workspace_count? integer
function M.assign(monitors, workspace_count)
  M.clear()

  for workspace = 1, workspace_count or 36 do
    rules[#rules + 1] = hl.workspace_rule({
      workspace = tostring(workspace),
      monitor = monitors[((workspace - 1) % #monitors) + 1],
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
      local monitor = hl.get_monitor(monitors[((workspace.id - 1) % #monitors) + 1])

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
