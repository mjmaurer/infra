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
      # TODO: probably want this via sops home-manager module
      # "shellDotEnv" = {
      #   sopsFile = ./secrets/shell.env;
      #   mode = "0400";
      #   owner = config.users.users.${username}.name;
      #   group = config.users.groups.${username}.name;
      # };
      gpgAuthKeygrip = { };

      smbHost = { };
      smbUrl = { };

      apiKeyAnthropic = { };
      apiKeyCodestral = { };
      apiKeyVoyage = { };
      apiKeyOpenai = { };
    };
    templates = {
      "shell.env" = {
        #   mode = "0400";
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
        content = ''
          ${config.sops.placeholder.gpgAuthKeygrip}

        '';
        # Newlines are needed!
      };
    };
  };
}

