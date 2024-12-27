# Personal Nix Infrastructure

Everything in this repo is fully declarative. You should be able to go from zero to OS in 15 minutes.

Home Manager is managed separately from NixOS, so NixOS machines should follow both the [NixOS](#nixos) and [Home Manager](#home-manager) sections below.

## Pre-Install

- Clone this repo to `~/infra`

## NixOS:

## Home Manager

### Install / Switch

First, [install Nix](https://nixos.org/download) (Also consider [this alternative installer](https://github.com/DeterminateSystems/nix-installer))

Then, run Home Manager. On non-NixOS systems, you need to add `experimental-features = nix-command flakes` to `/etc/nix/nix.conf` first. This can be removed once `--extra-experimental-features "nix-command flakes"` on the command below starts working again.

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

## NixOS / Home Manager

### Update Flake

Go to this repo and run `nix flake update`.

This will update the flake inputs (e.g. nixpkgs, home-manager, etc).

