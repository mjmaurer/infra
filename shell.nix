{ pkgs, sops-nix-pkgs, ... }: {
  default = pkgs.mkShell {
    packages = with pkgs; [
      sops
      age
      ssh-to-age
    ];
    nativeBuildInputs = [ sops-nix-pkgs.sops-import-keys-hook ];
    shellHook = ''
      export NIX_CONFIG="extra-experimental-features = nix-command flakes ca-derivations";
    '';
  };
}
