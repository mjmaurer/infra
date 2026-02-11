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
    bun build src/index.ts --compile --minify --outfile mcp-cli

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    install -Dm755 mcp-cli $out/bin/mcp-cli

    runHook postInstall
  '';

  meta = {
    description = "A lightweight CLI for interacting with MCP servers";
    homepage = "https://github.com/philschmid/mcp-cli";
    license = lib.licenses.mit;
    mainProgram = "mcp-cli";
  };
}
