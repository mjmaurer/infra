{
  pkgs,
  lib,
}:

let
  appName = "AeroSpace.app";
  version = "0.18.4-Beta";
in
pkgs.stdenv.mkDerivation {
  pname = "aerospace";

  inherit version;

  src = pkgs.fetchzip {
    url = "https://github.com/nikitabobko/AeroSpace/releases/download/v${version}/AeroSpace-v${version}.zip";
    sha256 = "sha256-TjVxq1HS/gdGi32noj7i1P6e9lXKNtBoO373Cesnwks=";
  };

  nativeBuildInputs = [ pkgs.installShellFiles ];

  installPhase = ''
    runHook preInstall
    mkdir -p $out/Applications
    mv ${appName} $out/Applications
    cp -R bin $out
    mkdir -p $out/share
    runHook postInstall
  '';

  postInstall = ''
    installManPage manpage/*
    installShellCompletion --bash shell-completion/bash/aerospace
    installShellCompletion --fish shell-completion/fish/aerospace.fish
    installShellCompletion --zsh  shell-completion/zsh/_aerospace
  '';

  doInstallCheck = true;
  nativeInstallCheckInputs = [
    pkgs.versionCheckHook
  ];

  passthru.updateScript = pkgs.gitUpdater {
    url = "https://github.com/nikitabobko/AeroSpace.git";
    rev-prefix = "v";
  };

  meta = {
    license = lib.licenses.mit;
    mainProgram = "aerospace";
    homepage = "https://github.com/nikitabobko/AeroSpace";
    description = "i3-like tiling window manager for macOS";
    platforms = lib.platforms.darwin;
    maintainers = with lib.maintainers; [ alexandru0-dev ];
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}
