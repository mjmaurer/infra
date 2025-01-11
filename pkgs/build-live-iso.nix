{ lib
, writeShellApplication
, openssh
}:
(writeShellApplication {
  name = "build-live-iso";
  runtimeInputs = [ openssh ];
  text = ''
    out="$(pwd)/result"
    iso_out="$(dirname "$out")/live.iso"

    nix build --out-link "$out" \
      --extra-experimental-features nix-command \
      --extra-experimental-features flakes \
      --no-write-lock-file -j auto ".#nixosConfigurations.live-iso.config.system.build.isoImage" || exit 1

    cp "$out/iso/*.iso" "$iso_out"

    echo "Congrats 🎉! Flash $iso_out to your device of choice."
    echo "Flash command: 'dd if=$iso_out of=/dev/<usb> bs=4M status=progress'"
  '';
})
  // {
  meta = with lib; {
    licenses = licenses.mit;
    platforms = platforms.all;
  };
}
