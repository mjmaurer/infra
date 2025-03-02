{
  callPackage,
  writeShellApplication,
  lib,
}:
let
  shellApp =
    { name, text }:
    callPackage (writeShellApplication {
      inherit name text;
      runtimeInputs = [ ];
    })
    // {
      meta = with lib; {
        licenses = licenses.mit;
        platforms = platforms.all;
      };
    };
in
{
  ssh-host-bootstrap = shellApp {
    name = "ssh-host-bootstrap";
    text = builtins.readFile ./ssh-host-bootstrap.sh;
  };
}
