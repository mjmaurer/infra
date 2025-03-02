{
  callPackage,
  writeShellApplication,
  lib,
}:
let
  shellApp =
    { name, text }:
    writeShellApplication {
      inherit name text;
      runtimeInputs = [ ];
    };
in
{
  ssh-host-bootstrap = shellApp {
    name = "ssh-host-bootstrap";
    text = builtins.readFile ./ssh-host-bootstrap.sh;
  };
}
