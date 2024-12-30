# Personal Nix Infrastructure

Everything in this repo is fully declarative. You should be able to go from zero to OS in 15 minutes.

This supports NixOS, Darwin, and Home Manager as separate flakes.

Because Home Manager is managed separately from NixOS / Darwin, NixOS / Darwin machines should follow Home Manager's instructions in addition to their own.

## Pre-Install

- Clone this repo to `~/infra`
- For Home Manager / Darwin:
  - [Install Nix](https://nixos.org/download) (Also consider [this alternative installer](https://github.com/DeterminateSystems/nix-installer))
  - You need to add `experimental-features = nix-command flakes` to `/etc/nix/nix.conf` first. This can be removed once `--extra-experimental-features "nix-command flakes"` on the command below starts working again.

## Darwin:

This is just a summary of the [Darwin README](https://github.com/LnL7/nix-darwin?tab=readme-ov-file#step-1-creating-flakenix).

Darwin flakes don't manage the hostname or system users.
You should add an appropriate darwin configuration to the flake.nix file under your Mac's hostname, which can be set with:

```
scutil --set HostName <hostname>
```

Then, to install run:

```
nix run nix-darwin -- switch --flake ~/infra
```

After this you can use `nrb` (nix-rebuild) to update the system.

### Homebrew Updates

```sh
brew update
darwin-rebuild switch
```

### Unicode Hex Input

This is necessary for the `alt` key to work in the terminal.

```
Keyboard -> Text Input -> Edit -> click +
Select "Unicode Hex Input" and hit "Add"
```

## Home Manager

### Install / Switch

```sh
nix run home-manager/master -- switch --flake ~/infra#{mac,linux,nixos}
```

After this, you can use `hmswitch`.

#### Optional: Non-Default User

If you want to use a non-default user (`mjmaurer`), you should add it to `flake.nix` under `homeConfigurations`.

#### Optional: Manage as Standalone Flake

There's probably not much use to this, because you'd still have to update based
on the central flake.

```sh
nix run home-manager/master -- init
```

After, you would need to setup the central flake as an input to the standalone flake,
and use the appropriate homeConfiguration derivation. Then run:

```sh
nix run home-manager/master -- init --switch
```

You'd need to run `nix flake update` to update the standalone flake.

## Updating 

Go to this repo and run `nix flake update`.

This will update the flake inputs (e.g. nixpkgs, home-manager, etc).
