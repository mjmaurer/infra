{ pkgs, sops-nix-pkgs, ... }: {
  default = pkgs.mkShell {
    packages = with pkgs; [
      sops
      age
      ssh-to-age

      # Guide I used to set up Yubikey (also on GitHub)
      drduh-yubikey-guide
      # Store keys on paper
      paperkey

      yubikey-manager
      yubikey-personalization
      # yubikey-touch-detector
    ];
    nativeBuildInputs = [ sops-nix-pkgs.sops-import-keys-hook ];
    shellHook = ''
      export NIX_CONFIG="extra-experimental-features = nix-command flakes ca-derivations";
    '';
  };
}
