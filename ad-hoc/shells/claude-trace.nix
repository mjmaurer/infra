{
  lib,
  pkgs-latest,
  ...
}:
pkgs-latest.buildNpmPackage rec {
  pname = "claude-trace";
  version = "1.0.8";

  src = pkgs-latest.fetchFromGitHub {
    owner = "Richard-Weiss";
    repo = "lemmy";
    rev = "7cf8f71a8f1e6108a84806aebf1d9e09a76cdee1";
    hash = "sha256-bTbQy7m8bubvyfnoFbZVMuBbqg0TNazgb+slpLpgfGY=";
  };

  npmDepsHash = "sha256-XFcxl6thsHgwC+pNT6ZPjRL33BQW0KMh4bxh45ac2gQ=";

  nativeBuildInputs = [ pkgs-latest.makeWrapper ];

  # Build claude-trace (and any workspace deps it needs)
  buildPhase = ''
    runHook preBuild
    npm run build --workspace=apps/claude-trace
    runHook postBuild
  '';

  # Custom install: extract only claude-trace and its node_modules
  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib/claude-trace $out/bin

    cp -r apps/claude-trace/dist $out/lib/claude-trace/
    cp -r apps/claude-trace/frontend $out/lib/claude-trace/frontend
    cp apps/claude-trace/package.json $out/lib/claude-trace/

    # Copy node_modules, dereferencing workspace symlinks
    cp -rL node_modules $out/lib/claude-trace/node_modules 2>/dev/null || true

    # Remove any broken symlinks that survived
    find $out -type l ! -exec test -e {} \; -delete

    makeWrapper ${pkgs-latest.nodejs}/bin/node $out/bin/claude-trace \
      --add-flags "$out/lib/claude-trace/dist/cli.js"

    runHook postInstall
  '';

  meta = {
    description = "Record all your interactions with Claude Code";
    homepage = "https://github.com/badlogic/lemmy/tree/main/apps/claude-trace";
    license = lib.licenses.mit;
    mainProgram = "claude-trace";
  };
}
