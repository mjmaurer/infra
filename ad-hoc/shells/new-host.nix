{
  lib,
  mkShell,
  writeScript,
}:
let
  cleanup-script = writeScript "cleanup-temp" ''
    if [ -d "$NEW_HOST" ]; then
      echo "Cleaning up temporary directory: $NEW_HOST"
      rm -rf "$NEW_HOST"
    fi
  '';
in
(mkShell {
  name = "new-host-shell";

  shellHook = ''
    NEW_HOST=$(mktemp -d -t new_host.XXXXXX)

    # Register cleanup on shell exit
    trap "$(cat ${cleanup-script})" EXIT
  '';
})
// {
  meta = with lib; {
    licenses = licenses.mit;
    platforms = platforms.all;
  };
}
