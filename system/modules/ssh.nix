{
  # This setups a SSH server for a headless system.
  services.openssh = {
    enable = true;
    settings = {
      # Opinionated: forbid root login through SSH.
      PermitRootLogin = "no";
      # Opinionated: use keys only.
      PasswordAuthentication = false;
    };
  };
}
