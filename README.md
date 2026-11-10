# AquaticOS-Example

## Introductory Info
This is meant to be a template/example to start from to use my [AquaticOS](https://git.aquaticservers.com/aqua/AquaticOS) Project, to start your own journey for dendritic.

To get started, clone this repo with `git clone https://git.aquaticservers.com/aqua/AquaticOS-Example.git`

Then, if you do not wish to have git with your copy of this project, remove the .git folder with `rm -r .git` inside the projects folder

If you do wish to use your own git repository, create a blank repository, then change the remote with `git remote set-url origin [YOUR PROJECT CLONE URL]`. If you are doing this, I expect you are semi-familiar with git and will likely not provide further help with managing your git repo.

## How to use this project
Make a folder called `modules` in the root of the project. Inside here is where you will put every nix module you want to create. This folder is loaded recursively so everything inside it will load, as long as it ends in `.nix`. It will also ignore any filenames starting with an `_`.

Once the folder is made, you may start to add your own modules, following the details below

I expect you to be at least slightly familiar with nix itself, and will not be explaining anything about basic nix config that is not specifically relevent to the strucutre of a module or other feature unique to this kind of setup.

## Basic Modules
This is the basic template of a module:
```
{ ... }:
{
  flake.modules.nixos.MODULENAME
  { ... }:
  {
    [nix base/core code here]
  };

  flake.modules.homeManager.MODULENAME
  { ... }:
  {
    [nix home manager code here]
  };
}
```
Then, replace `MODULENAME` with what you want to name the module, for example, `kde` might be used for a KDE desktop setup

You do not need both, and can have module files with only `flake.modules.nixos.MODULENAME` or only `flake.modules.homeManager.MODULENAME`, if you only need core/base nixos config, or only need home manager config

The top/first line `{...}:` is mainly only to be used for `inputs`, and not for `pkgs` or `lib` or other things you wish to load into your config. If you need `pkgs` or `lib` or similar, you should include them in the `{...}:` section under the module bit they are used in. 

As an example, if you only use pkgs in the bare nixos module part, but not in the home manager section,  and you need to also use inputs, you would do something like this:
```
{ inputs, ... }:
{
  flake.modules.nixos.MODULENAME
  { pkgs, ... }:
  {
    [nix base/core code here]
  };

  flake.modules.homeManager.MODULENAME
  { ... }:
  {
    [nix home manager code here]
  };
}
```

Multiple files can have the same module name, and they will act as if you put it all into 1 file, merging the 2 files modules together as if they are one at build time.

## Adding Hosts
To make a host, simply make a module with the name of it matching the hostname you are using, then, create a file and put in the relevent bit (I personally use `flake-parts.nix` for this as it fills in for putting your host in the flake):
```
{ inputs, ... }:
{
  flake.nixosConfigurations = inputs.self.lib.mkNixos "x86_64-linux" "HOSTNAME";
}
```
This will automatically import the module that matches the hostname, for any host it is built on with that hostname.

The project is currently only setup and tested on x86_64 hosts, so I am unsure of any potential breakage currently by using it on arm or darwin or any other architectures.

## Loading Modules
So, you have your host, the bit of code to load it, and the module for it. Now, you want to load one of the other modules you have. Imports of `nixos.MODULENAME` modules can be done inside other nixos modules via this:
```
imports = with inputs.self.modules.nixos; [
  MODULENAME
];
```

If you wish to load `homeManager.MODULENAME` modules from inside another home manager module, you can do so with this:
```
imports = with inputs.self.modules.homeManager; [
  MODULENAME
];
```

Lastly, if you wish to load a home manager module from inside the nixos section (This is needed for initially loading any initial home manager module), you can do so in 2 ways.

Way 1, this will import this home manager module for all users:
```
home-manager.sharedModules = with inputs.self.modules.homeManager; [
  MODULENAME
];
```

Way 2, this will import this home manager module for only `USERNAME`:
```
home-manager.users.USERNAME.imports = with inputs.self.modules.homeManager; [
  MODULENAME
];
```

## Default modules

A few default modules, prefixed with `core_`, are available to you.

***YOU ARE HIGHLY EXPECTED TO LOAD `core_system-core` IN BOTH REGULAR NIX AND HOME MANAGER SECTIONS, THOUGH IT IS NOT REQUIRED IF YOU WISH TO WRITE EVEN THE BASE NIX STUFF ON YOUR OWN***

Most of the settings set in `core_system-core` that should matter are set with `mkOverride 500`, so they can be set as normal and it will override the base settings.

## Final Words

Beyond making a module, adding a host, and loading the modules, everything else should just be standard nix configuration inside any `flake.modules.nixos.MODULENAME` section, and standard home manager config inside any `flake.modules.homeManager.MODULENAME` section. I am not responsible for how you use this config, and do not expect support unless I explicitly offer it, or unless there is a major issue that is due to my core config itself that can not be resolved.