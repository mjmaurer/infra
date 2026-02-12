{
  lib,
  stdenv,
  fetchFromGitHub,
  bun,
  makeWrapper,
}:
stdenv.mkDerivation rec {
  pname = "mcp-cli";
  version = "0.3.0";

  src = fetchFromGitHub {
    owner = "philschmid";
    repo = "mcp-cli";
    rev = "v${version}";
    hash = "sha256-S924rqlVKzUFD63NDyK5bbXnonra+/UoH6j78AAj3d0=";
  };

  nativeBuildInputs = [
    bun
    makeWrapper
  ];

  buildPhase = ''
    runHook preBuild

    export HOME=$TMPDIR
    bun install --frozen-lockfile

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib/mcp-cli
    cp -r . $out/lib/mcp-cli

    mkdir -p $out/bin
    makeWrapper ${bun}/bin/bun $out/bin/mcp-cli \
      --add-flags "run $out/lib/mcp-cli/src/index.ts" \
      --set-default HOME "$HOME"

    runHook postInstall
  '';

  meta = {
    description = "A lightweight CLI for interacting with MCP servers";
    homepage = "https://github.com/philschmid/mcp-cli";
    license = lib.licenses.mit;
    mainProgram = "mcp-cli";
  };
}
