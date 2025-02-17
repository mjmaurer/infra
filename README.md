# Personal Nix Infrastructure

Everything in this repo is fully declarative. You should be able to go from zero to OS in 15 minutes.

This supports NixOS, Darwin, and Home Manager as separate flakes.

Because Home Manager is managed separately from NixOS / Darwin, NixOS / Darwin machines should follow Home Manager's instructions in addition to their own.

## Pre-Install

- Clone this repo to `~/infra`
- For Home Manager / Darwin:
  - [Install Nix](https://nixos.org/download) (Also consider [this alternative installer](https://github.com/DeterminateSystems/nix-installer))
  - You need to add `experimental-features = nix-command flakes` to `/etc/nix/nix.conf` first. This can be removed once `--extra-experimental-features "nix-command flakes"` on the command below starts working again.

## Install: NixOS (Local Machine)

1. Flash live.iso from the github action to a USB stick.
2. Boot into it. It should start an SSH server automatically, and uses dhcpcd
  - Debugging: Look at dhcpcd
3. Confirm you can SSH into it: `ssh -I ~/.nix-profile/lib/libykcs11.dylib root@IP`
  - Debugging: Make sure you can generate a public key from your resident PIV (See PIV README section). If not, try unplugging/replugging


```
cd install
nix-build iso.nix
sudo dd if=result/<iso> of=/dev/<usb>
# Boot into nixos iso image on /dev/<usb>
# Configure networking
partition --device /dev/<harddrive> --bios ([l]egacy|[u]efi)
# Make personal changes to /mnt/etc/nixos
echo "<hostname>" >> /mnt/etc/nixos/hostname # Must match the name of the file in /machines
nixos-install --flake /mnt/infra
```

## Install: Darwin

This is just a summary of the [Darwin README](https://github.com/LnL7/nix-darwin?tab=readme-ov-file#step-1-creating-flakenix).

Darwin flakes don't manage the hostname or system users.
You should add an appropriate darwin configuration to the flake.nix file under your Mac's hostname, which can be set with:

```
scutil --set HostName <hostname>
scutil --set LocalHostName <hostname>
```

Then, to install run:

```
nix run nix-darwin -- switch --flake ~/infra
```

After this you can use `nrb` (nix-rebuild) to update the system.

You should likely [update Homebrew packages](#homebrew-updates) next.

### Homebrew Package Updates

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

## Install: Standalone Home Manager

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

# Implementation Notes

## Updating

Go to this repo and run `nix flake update`.

This will update the flake inputs (e.g. nixpkgs, home-manager, etc).

## NixOS vs Darwin

There are enough mutually exclusive features between NixOS and Darwin that it's not practical to share many modules.

- Most of Darwin's config is stuck in `system/common/darwin.nix`
- Most of `system/modules` is NixOS-specific. See `system/common/_base.nix` for shared modules.

## Impermanence

Motivation: https://grahamc.com/blog/erase-your-darlings/
Implementation: https://github.com/nix-community/impermanence / https://nixos.wiki/wiki/Impermanence

Nix only needs to persist `/boot` and `/nix`. However in `install/partition`, we still partition `/home` and `/root` on disk.

Even though `/root` is currently persisted, we should prepare for impermanence. To do so, use `environment.persistence` to designate directories to be persisted (such as certain `/var/*` paths):

- Use `/persist-nobackup` (specialVar `persistNoBackup`) for directories that should not be backed up.
- Use `/persist-backup` (specialVar `persistBackup`) for directories that should be backed up.

See `tailscale.nix` for an example of how to use these.

See [this GH issue](https://github.com/mjmaurer/infra/issues/11) for future work / more details.

## Upgrade Notes

- Sequoia (15.0.0): Need to follow this to fix eDSRecordNotFound error: https://determinate.systems/posts/nix-support-for-macos-sequoia/

## Yubikey OpenPGP setup

See the scripts under the home-manager crypt modules.

## Yubikey PIV (Resident) SSH Keys

Follow [this guide](https://github.com/fredxinfan/ykman-piv-ssh) to setup a yubikey with a new resident SSH keys:

```
# Only if you haven't already (this might take a while)
ykman piv keys generate -a RSA4096 --touch-policy ALWAYS --pin-policy ONCE 9a ./yubikey-public.pem
ykman piv certificates generate -s 'some comment' 9a ./yubikey-public.pem
rm ./yubikey-public.pem

# NOTE FOR BELOW: opensc-pkcs11.so was having issues when used with `ssh -I`, but could theoretically work there instead. opensc does have the benefit when using `ssh-keygen` that it only prints the single PIV public key in slot 9a.

# Get public key (add to sops and AuthorizedKeys):
ssh-keygen -D ~/.nix-profile/lib/opensc-pkcs11.so -e
# Authenticate (See below for running a test server):
# This is aliased to sshyk
ssh -I ~/.nix-profile/lib/libykcs11.dylib -p 2222 localhost 

# [Optional] Test:
pkcs11-tool --login --test 

```

Can quickly run a test server with:
```
mkdir -p /tmp/ssh_test

# Generate host keys
ssh-keygen -t rsa -f /tmp/ssh_test/ssh_host_rsa_key -N ""

echo "Port 2222
HostKey /tmp/ssh_test/ssh_host_rsa_key
AuthorizedKeysCommand /bin/echo \"$(ssh-keygen -D ~/.nix-profile/lib/opensc-pkcs11.so -e)\"
AuthorizedKeysCommandUser $(whoami)" > /tmp/ssh_test/sshd_config

/usr/sbin/sshd -f /tmp/ssh_test/sshd_config -D -dd
```
<!-- AuthorizedKeysCommand /bin/echo \"$(ssh-keygen -D ~/.nix-profile/lib/opensc-pkcs11.so -e)\" -->

Right now, these are just used for logging into the USB ISO with SSH.

# Troubleshooting

If there are any errors at all during the build, it could cause a potential issue with something downstream.

## Darwin

### Launchd

Launchd services will sometimes not get removed. You'll have to unload the service and remove it's plist manually. This applies to homebrew services and darwin launchd services.

### Kanata

[See here](https://github.com/jtroo/kanata/releases) for official installation instructions.

If you see `connect-failed ...` from kanata, it likely means the kanata version is depending on a new Karabiner driver version than the one installed. I build this derivation manually so we can get quicker updates if needed. This message could also mean that the Karabiner system extension isn't getting activated properly.

You can get more info on LaunchD daemons by checking their logs. Use this command to get more info about the command currently running:

```
sudo plutil -p /Library/LaunchDaemons/DAEMON.plist
```

You can find the current driver version by:

```
# to find the karabiner-driver store path
nss karabiner
defaults read /nix/store/k0xq3rhsg7ahz7nqk6wapvh7d075r4hc-karabiner-elements-15.3.0-driver/Library/Application\ Support/org.pqrs/Karabiner-DriverKit-VirtualHIDDevice/Applications/Karabiner-VirtualHIDDevice-Daemon.app/Contents/Info.plist
```


