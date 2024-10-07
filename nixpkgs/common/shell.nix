{ lib }:
{
  rc = builtins.readFile ./shellRcCommon.sh;
  sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
    BOBBY_PORT = 7850;
    AUTOMATIC_PORT = 7860;
    RVC_PORT = 7865;
    PLEX_WEB_PORT = 32400;
    JELLYFIN_WEB_PORT = 8096;
  };
  shellAliases = {
    ".." = "cd ..";
    "gc" = "git commit -v";
    "gcs" = "git commit -v --gpg-sign";
    "ga" = "git add --all";
    "gs" = "git status";
    "rg" = "rg --hidden";
    "nix-shell" = "nix-shell --command 'zsh'";
    "ns" = "nix-shell";
    "la" = lib.mkDefault "ls -A --color";
    "ls" = lib.mkDefault "ls --color";
    "hmswitchnoload" = "home-manager -f ~/.config/nixpkgs/machines/$MACHINE_NAME.nix switch -b backup";
    "dtail" = "docker logs -tf --tail='50'";
    "dstop" = "docker stop `docker ps -aq`";
    "dlog" = "docker logs ";
    "dtop" = "docker run --name ctop  -it --rm -v /var/run/docker.sock:/var/run/docker.sock quay.io/vektorlab/ctop";
    "dps" = "docker ps ";
    "dcrneup" = "docker compose up -f ~/docker-compose.yml -d ";
    "dcup" = "docker compose up -d ";
    "dcreup" = "docker compose up -d --build --force-recreate ";
    "drm" = "docker rm `docker ps -aq`";
    "dcp" = "docker compose -f ~/docker-compose.yml ";
    "dcporph" = "docker compose -f ~/docker-compose.yml --remove-orphans ";
  };
}
