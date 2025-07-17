 # Personal Nix Infrastructure

Everything in this repo is fully declarative. You should be able to go from zero to OS in 15 minutes.

This supports NixOS, Darwin, and Home Manager as separate flakes.

Because Home Manager is managed separately from NixOS / Darwin, NixOS / Darwin machines should follow Home Manager's instructions in addition to their own.

## Pre-Install

- Clone this repo to `~/infra` and cd into it
- Run `nix develop ".#new-host"` to enter a shell which walks through steps of creating keys / config for new host. The following assumes you have a NEW_HOST_DATA environment variable created by this.
- For Home Manager / Darwin:
  - [Install Nix](https://nixos.org/download) (Also consider [this alternative installer](https://github.com/DeterminateSystems/nix-installer))
  - You need to run `export NIX_CONFIG="extra-experimental-features = nix-command flakes ca-derivations"` first. This can be removed once `--extra-experimental-features` on the commands below starts working again.
- For Cloud / VPS
  - Install Nix: `sh <(curl -L https://nixos.org/nix/install) --daemon`
  - Add keypair for root ssh (sshPubLiveIso): `sudo vim /root/.ssh/authorized_keys; sudo systemctl restart ssh`
  - Make sure this is not honored after

## Install: NixOS (Local Machine)

1. Flash live.iso from the github action to a USB stick.
1. Plug it in, reboot, and immediately go into BIOS settings:
   - Change `Boot Mode` to `UEFI only`
   - [Optional] Move the USB up in the boot order
1. Boot into the USB. It should start an SSH server automatically, and uses dhcpcd (check dhcpcd logs if theres an issue)
1. Confirm you can SSH into it: `ssh -I ~/.nix-profile/lib/libykcs11.dylib root@live-iso` 

   - **Debugging:** Make sure you can generate a public key from your resident PIV (See PIV README section). If not, try unplugging/replugging
   - **Debugging:**  `live-iso` (previosly `nixos`) should resolve via router DNS, but if not you have to use IP

1. Get the disk device IDs using `ls -l /dev/disk/by-id`. You will use this to write the the disko config.
1. Get the kernel module for your network card for initrd: `lspci -v | grep -iA8 'network\|ethernet'`
1. Get the interface names: `networkctl list` or `ip link`
1. Continue to `NixOS (Remote Machine)` section below

## Install: NixOS (Remote Machine)

1. Create (or copy) a new directory under `system/machines`, with `secrets.yaml`, `default.nix`, `disko.nix`, and an empty `hardware-configuration.nix`
1. Create a preauthorized Tailscale auth key (single-use or alternatively a reusable key thats only valid for a day)

   - Add the tailscale key as a sops secret

1. Run the install command (get ready to enter your SSH key's password a lot):

```sh
cd ~/infra
NEW_HOST=<machine_name>
# Or live-iso.localdomain
IP=live-iso
PKPATH=<my_liveiso_ssh_key_path>
# Note for cloud: Remove --disk-encryption-keys
nix run github:nix-community/nixos-anywhere -- \
    -i "$PKPATH" --flake ".#$NEW_HOST" --target-host root@$IP \
   --extra-files "$NEW_HOST_DATA/ssh_host_keys" \
   --disk-encryption-keys /tmp/disk.key "$NEW_HOST_DATA/luks_keys/disk.key" \
   --generate-hardware-config nixos-generate-config "./system/machines/$NEW_HOST/hardware-configuration.nix" \
   --build-on remote --print-build-logs
```

1. Remove USB, reboot and enjoy! NOTE: You should probably use headless/remote reboot first thing to make sure it works (`sshk root@maple-init`). See remote LUKS section below for more info

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

### Installing Minimal Darwin system without OS config

```
HOST="my-hostname" USERNAME="username" nix run nix-darwin -- switch --flake github:mjmaurer/infra/main#default --impure
```

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

**Currently outdated. May or may not work**

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

## Updating Filesystem with Disko

Disko doesn't have great support for [in-place updates](https://github.com/nix-community/disko/issues/295), but can still be used to mount whatever you create imperitavely (i.e. as a replacement for `fileSystems` / fstab).

Make any modifications needed to `system/machines/$HOST/disko.nix`, and then you could ask an LLM to create a starter bash script for the changes given the diff. Once applies, you should commit these to `system/machines/$HOST/fs-patches` just to keep track.

Then, you might be able to mount without a rebuild (but you should probably just rebuild):
```
# Dry run first (it should only format new disks):
sudo nix run github:nix-community/disko -- --dry-run --mode mount ~/infra/system/machines/$HOST/disko.nix
# If it looks good:
sudo nix run github:nix-community/disko -- --mode mount ~/infra/system/machines/$HOST/disko.nix
```

## Decrypting LUKS Drive Remotely via SSH on Reboot 

Just ssh like normal, however, use a hostname of `${hostname}-init`. This way, tailscale doesn't interfere, and we don't have to deal with known_host issues due to changing key.

```
sshk root@maple-init
# Wait for boot
sshk mjmaurer@maple
# Note: Could also use `maple.localdomain` for non-tailscale 
# Note: If you can't login after boot, it could be because tailscale didnt start up correctly
```

## Headed vs Headed-Minimal vs Headless

Each OS derivation only needs one (configured in `flake.nix`):

```
# They directly import each other
Headed         ⊃ Headed-Minimal
Headed-Minimal ⊃ Headless
```

Since the headless module is always included, it contains most of the basic configuration.

Headed-Minimal modules include a display server (Wayland) and Sway window manager.
They also include a terminal (Alacritty) and browser (Firefox).
However, many other GUI tools are not included.

At the system-level, this layout only applies to NixOS. Darwin manages everything in `common/darwin.nix`.

## Impermanence

Motivation: https://grahamc.com/blog/erase-your-darlings/
Implementation: https://github.com/nix-community/impermanence / https://nixos.wiki/wiki/Impermanence

Nix only needs to persist `/boot` and `/nix`. However in `install/partition`, we still partition `/home` and `/root` on disk.

Even though `/root` is currently persisted, we should prepare for impermanence. To do so, use `environment.persistence` to designate directories to be persisted (such as certain `/var/*` paths):

- Use `/persist-nobackup` (specialVar `persistNoBackup`) for directories that should not be backed up.
- Use `/persist-backup` (specialVar `persistBackup`) for directories that should be backed up.

See `tailscale.nix` for an example of how to use these.

See [this GH issue](https://github.com/mjmaurer/infra/issues/11) for future work / more details.

## Adding arbitrary SSH keys to GPG-agent for authentication

[See here](https://github.com/drduh/YubiKey-Guide?tab=readme-ov-file#import-ssh-keys)

```
# Same as with ssh-agent:
ssh-add ~/.ssh/id_rsa
```

## Yubikey OpenPGP Key Setup

See the scripts under `ad-hoc/pkgs/crypt`.

## Yubikey PIV (Resident) SSH Key Setup

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

# Debugging if that test fails (seems like using git signing breaks / resets something):
# - ykman list (most reliable)
# - Try existing current shell or reopening a new shell 
# - The act of running the below commands with OPENSC_DEBUG
# - Plug out / plug in
# - yubi-switch
OPENSC_DEBUG=3 pkcs11-tool --module ~/.nix-profile/lib/libykcs11.dylib -L
OPENSC_DEBUG=3 pkcs11-tool --module ~/.nix-profile/lib/opensc-pkcs11.so -L
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

## Partitioning Schemes

Went with LUKS encrypted root with ZFS on top. Didn't choose zfs encryption because it's reported to be a [bit](https://github.com/openzfs/zfs/issues/13736) buggy.

## GitHub Setup

After setting up your GPG key, you'll need to configure GitHub to work with it:

1. Make sure the SIGN subkey ID is configured in home-manager for `git.signingKey`
2. Add the AUTH subkey's keygrip ID to SOPS (which sets gpg-agent's sshcontrol)
   ```
   gpg --list-keys --with-keygrip
   ```
3. Run Nix Rebuild (`nrb`)
4. Confirm that gpg-agent is now managing the SSH key:
   ```
   ssh-add -L
   ```
5. Add the SSH public key to GitHub SSH keys
   ```
   gpg --export-ssh-key mjmaurer777@gmail.com
   ```
6. Add the GPG public key to GitHub GPG keys to enable signing:
   ```
   gpg --armor --export mjmaurer777@gmail.com
   ```
7. Test authentication with:
   ```
   ssh -T git@github.com
   ```
8. Test signing with a commit

Note: This also depends on the `addGpgSshIdentity` activation, which sets ~/.ssh/id_rsa_yubikey.pub.

# Troubleshooting

If there are any error messages at all during a build / rebuild, it could cause a potential issue with something downstream.

## Darwin

### Launchd

Launchd services will sometimes not get removed. You'll have to unload the service and remove it's plist manually. This applies to homebrew services and darwin launchd services.

### Kanata

[See here](https://github.com/jtroo/kanata/releases) for official installation instructions.

If you see `connect-failed ...` from kanata, it likely means the kanata version is depending on a new Karabiner driver version than the one installed. I build this derivation manually so we can get quicker updates if needed. This message could also mean that the Karabiner system extension isn't getting activated properly.

The kanata exe (and any terminal you run it in) requires 'Input Monitoring' and 'Accessability' permissions. If you update the kanata binary (even via homebrew), you'll need to regrant them.
If you get io errors, it could be because you're running Alacritty. Try the default terminal.

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

### Sequioa Upgrade Notes

Sequoia (15.0.0): Need to follow this to fix eDSRecordNotFound error: https://determinate.systems/posts/nix-support-for-macos-sequoia/
