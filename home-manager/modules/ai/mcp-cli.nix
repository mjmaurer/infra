{
  lib,
  stdenv,
  stdenvNoCC,
  fetchFromGitHub,
  bun,
  makeWrapper,
}:
let
  pname = "mcp-cli";
  version = "0.3.0";

  src = fetchFromGitHub {
    owner = "philschmid";
    repo = "mcp-cli";
    rev = "v${version}";
    hash = "sha256-S924rqlVKzUFD63NDyK5bbXnonra+/UoH6j78AAj3d0=";
  };

  # node_modules as a fixed-output derivation: the only kind of build allowed
  # network access inside the Nix sandbox (on by default on NixOS, off on darwin).
  # `--production` skips devDependencies, which include platform-specific Biome
  # binaries; the runtime deps are pure JS, so one hash works on every platform.
  # Update `outputHash` whenever `version` changes: set it to lib.fakeHash, build,
  # and copy the "got:" hash from the error.
  deps = stdenvNoCC.mkDerivation {
    pname = "${pname}-deps";
    inherit version src;

    nativeBuildInputs = [ bun ];

    dontConfigure = true;
    dontFixup = true; # don't patch/strip anything; it would change the output hash

    buildPhase = ''
      runHook preBuild

      export HOME=$TMPDIR
      export BUN_INSTALL_CACHE_DIR=$TMPDIR/bun-cache
      bun install --frozen-lockfile --production --ignore-scripts --no-progress

      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall

      mkdir -p $out
      cp -r node_modules $out/node_modules

      runHook postInstall
    '';

    outputHashMode = "recursive";
    outputHashAlgo = "sha256";
    outputHash = "sha256-yDqCHnjmkz8dotufExIb5qRE04fLDWlEy+1u1YzFBqs=";
  };
in
stdenv.mkDerivation {
  inherit pname version src;

  nativeBuildInputs = [ makeWrapper ];

  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib/mcp-cli
    cp -r . $out/lib/mcp-cli
    ln -s ${deps}/node_modules $out/lib/mcp-cli/node_modules

    mkdir -p $out/bin
    makeWrapper ${bun}/bin/bun $out/bin/mcp-cli \
      --add-flags "run $out/lib/mcp-cli/src/index.ts"

    runHook postInstall
  '';

  passthru = { inherit deps; };

  meta = {
    description = "A lightweight CLI for interacting with MCP servers";
    homepage = "https://github.com/philschmid/mcp-cli";
    license = lib.licenses.mit;
    mainProgram = "mcp-cli";
  };
}
