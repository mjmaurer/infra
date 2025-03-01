{ lib, writeShellApplication, openssh }:
(writeShellApplication {
  name = "build-live-iso";
  runtimeInputs = [ openssh ];
  text = ''
    out="$(pwd)/result"

    # This creates a symlink to the iso as the `result` directory
    nix build --out-link "$out" \
      --extra-experimental-features nix-command \
      --extra-experimental-features flakes \
      --no-write-lock-file -j auto ".#nixosConfigurations.live-iso.config.system.build.isoImage" || exit 1

    cp "$out"/iso/*.iso "./live.iso" || { echo "Error: ISO file not found"; exit 1; }

    echo "Congrats 🎉! Flash ./live.iso to your device of choice."
    echo "Flash command: 'dd if=./live.iso of=/dev/<usb> bs=4M status=progress'"
  '';
}) // {
  meta = with lib; {
    licenses = licenses.mit;
    platforms = platforms.all;
  };
}
