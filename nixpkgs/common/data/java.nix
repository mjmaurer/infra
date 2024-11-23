{ pkgs ? import <nixpkgs> { } }:

pkgs.mkShell {

  buildInputs = with pkgs; [
    jdk17
    maven
  ];

  shellHook = ''
    export DISPLAY=$(ip route list default | awk '{print $3}'):0
  '';

}
