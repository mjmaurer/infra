{ config, username, ... }: {
  sops = {
    # Generate age key based on SSH key to this path
    age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
    age.keyFile = "/var/lib/sops-nix/key.txt";
    age.generateKey = true;

    # Not using host GPG keys, so unset default
    gnupg.sshKeyPaths = [ ];

    defaultSopsFile = ./secrets/common.yaml;
    secrets = {
      gpgAuthKeygrip = { };

      smbHost = { };
      smbUrl = { };

      # TODO: probably want this via sops home-manager module,
      # but it does create issues with (permissions? I tried but can't remember the error)
      apiKeyAnthropic = { };
      apiKeyCodestral = { };
      apiKeyVoyage = { };
      apiKeyOpenai = { };

      mjmaurerHashedPassword = { neededForUsers = true; };
    };
    templates = {
      "shell.env" = {
        # mode = "0400";
        # group = config.users.groups.${username}.name;
        owner = config.users.users.${username}.name;
        content = ''
          export ANTHROPIC_API_KEY=${config.sops.placeholder.apiKeyAnthropic}
          export CLAUDE_API_KEY=${config.sops.placeholder.apiKeyAnthropic}
          export CODESTRAL_API_KEY=${config.sops.placeholder.apiKeyCodestral}
          export VOYAGE_API_KEY=${config.sops.placeholder.apiKeyVoyage}
          export OPENAI_API_KEY=${config.sops.placeholder.apiKeyOpenai}
        '';
      };
      "gpg_sshcontrol" = {
        owner = config.users.users.${username}.name;
        # Newlines in 'content' are needed!
        content = ''
          ${config.sops.placeholder.gpgAuthKeygrip}

        '';
      };
    };
  };
}

