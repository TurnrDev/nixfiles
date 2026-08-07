# dockmgr

`dockmgr` selects Hyprland display profiles from connected USB devices,
displays, and laptop-lid state. It watches for changes and applies the selected
profile through Hyprland's Lua monitor API.

This flake contains generic software and Nix modules. Display layouts, device
IDs, and hooks belong in the consuming configuration.

## Try it

Run the program from this checkout:

```console
nix run . -- --version
```

For development tools (ShellCheck, Lua, and jq):

```console
nix develop
nix flake check
```

## NixOS module

Add dockmgr as an input, preferably following the consumer's `nixpkgs`:

```nix
dockmgr = {
  url = "github:TurnrDev/nixfiles?dir=packages/dockmgr";
  inputs.nixpkgs.follows = "nixpkgs";
};
```

Import its NixOS module and define generic display profiles:

```nix
{
  inputs,
  ...
}:
{
  imports = [ inputs.dockmgr.nixosModules.default ];

  programs.dockmgr = {
    enable = true;

    profiles = [
      {
        name = "Laptop";
        match = null; # Required fallback profile.
        outputs.eDP-1 = {
          mode = "preferred";
          position = { x = 0; y = 0; };
          scale = 1.0;
        };
      }
      {
        name = "Docked";
        match.usb.anyOf = [ "1234:5678" ];
        outputs = {
          "desc:Example external display" = {
            mode = "2560x1440@60";
            position = { x = 0; y = 0; };
          };
          eDP-1.disabled = true;
        };
      }
    ];
  };
}
```

`match` supports nested `and`, `or`, and `not` expressions, plus `usb`,
`displays`, and `lid` clauses. USB and display clauses support `anyOf`,
`allOf`, and `noneOf`. A `match = null` fallback profile is required. More
specific matching profiles win; declaration order breaks ties.

Output names may be Hyprland output names such as `eDP-1`, or description
selectors such as `desc:Example external display`. Profiles disable connected
outputs not listed in `outputs` by default; set
`disableUnspecifiedOutputs = false` for additive layouts. Session and greeter
hooks are configured independently with `hooks.session` and `hooks.greeter`,
each providing `preUp`, `postUp`, `preDown`, and `postDown` command lists.

The module installs `dockmgr`, writes its resolved configuration to
`/etc/dockmgr/config.json`, and exposes the generated `package` and
`configFile` as read-only options.

## Home Manager integration

Import the Home Manager module for each managed Hyprland user:

```nix
{
  inputs,
  ...
}:
{
  imports = [ inputs.dockmgr.homeManagerModules.default ];
}
```

When `programs.dockmgr.enable` is set in the corresponding NixOS
configuration, the module creates a user watcher service. The watcher starts
at Hyprland's `hyprland.start` event and runs with the `session` hook context.

For a non-Home-Manager Hyprland environment such as a greeter, start
`dockmgr watch --config /etc/dockmgr/config.json --context greeter` after the
compositor is ready.

## Commands

```console
dockmgr once
dockmgr watch
dockmgr status
dockmgr --version
```

`once`, `watch`, and `status` accept `--config PATH` and
`--context session|greeter`. The default config path is
`/etc/dockmgr/config.json`.
