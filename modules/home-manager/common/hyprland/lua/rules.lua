hl.window_rule({
  name = "float-system-monitor",
  match = {
    initial_title = "^(System Monitor)$",
    initial_class = "^(org\\.quickshell)$",
  },
  float = true,
  size = { 835, 660 },
})

hl.window_rule({
  name = "float-quickshell",
  match = { initial_class = "^(org\\.quickshell)$" },
  float = true,
})

hl.window_rule({
  name = "float-edmarketconnector",
  match = { initial_class = "^(Edmarketconnector)$" },
  float = true,
  opacity = "0.8",
})

hl.window_rule({
  name = "workspace-spotify",
  match = { initial_class = "^([sS]potify)$" },
  workspace = "9",
})

hl.window_rule({
  name = "workspace-discord",
  match = { initial_class = "^([dD]iscord)$" },
  workspace = "9",
})
