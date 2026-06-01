#!/usr/bin/env bash
set -euo pipefail

# --- Configuration ---
PORTABLE_DIR="${HOME}/.config/.mjmaurer-portable-dotfiles"
DIFFS_DIR="${PORTABLE_DIR}/diffs"
DOWNLOAD_URL="https://github.com/mjmaurer/infra/releases/download/portable-dotfiles/dotfiles-portable.zip"
TODAY=$(date +%Y-%m-%d)

# --- Defaults ---
SAVE_DIFFS=1
OBSIDIAN_VAULT="${HOME}/Documents/obsidian"
INSTALL_SHELL=0
INSTALL_INPUTRC=0
INSTALL_PSQLRC=0
INSTALL_GIT=0
INSTALL_CLAUDE=0
INSTALL_VSCODE=0
INSTALL_NEOVIM=0
INSTALL_TMUX=0
INSTALL_ALACRITTY=0
INSTALL_DIRENV=0
INSTALL_OBSIDIAN=0
INSTALL_AI_TOOLS=0
INSTALL_SSH=0
INSTALL_SCRIPTS=0
INSTALL_AEROSPACE=0
ANY_INSTALL=0

# --- Cleanup ---
CLEANUP_DIR=""
cleanup() {
    if [ -n "$CLEANUP_DIR" ] && [ -d "$CLEANUP_DIR" ]; then
        chmod -R u+w "$CLEANUP_DIR" 2>/dev/null || true
        rm -rf "$CLEANUP_DIR"
    fi
}
trap cleanup EXIT

# --- Diff state ---
DIFF_CONTENT=""
INSTALLED_FILES=""

usage() {
    cat <<'EOF'
Usage: install-portable-dotfiles.sh [OPTIONS]

Downloads portable dotfiles and optionally installs them to your home directory.
All dotfiles are always cached to ~/.config/.mjmaurer-portable-dotfiles/.

Install flags:
  --install-minimal     Install: shell, inputrc, neovim, tmux, direnv, obsidian, aerospace, scripts
  --install-shell       Install .zshrc, .bashrc, .p10k.zsh
  --install-inputrc     Install .inputrc
  --install-psqlrc      Install .psqlrc
  --install-git         Install .gitconfig (drop-in) and .config/git/
  --install-claude      Install .claude/
  --install-vscode      Install .config/Code/
  --install-neovim      Install .config/nvim/
  --install-tmux        Install .config/tmux/ and .config/tmuxp/
  --install-alacritty   Install .config/alacritty/
  --install-direnv      Install .config/direnv/
  --install-obsidian    Install Documents/obsidian/ (see --obsidian-vault)
  --install-ai-tools    Install AI tool configs (aichat, mcp, llm, aider, etc.)
  --install-ssh         Install .ssh/config (drop-in)
  --install-scripts     Install .local/bin/
  --install-aerospace   Install .aerospace.toml

Options:
  --obsidian-vault PATH   Set obsidian vault install path (default: ~/Documents/obsidian)
  --no-diffs              Don't save diff files (still prints to stdout)
  --help                  Show this help message

Drop-in behavior:
  Git and SSH are installed as drop-in by default:
  - Git: appends [include] directive to ~/.gitconfig
  - SSH: prepends Include directive to ~/.ssh/config
EOF
    exit 0
}

parse_args() {
    while [ $# -gt 0 ]; do
        case "$1" in
            --install-minimal)
                INSTALL_SHELL=1; INSTALL_INPUTRC=1; INSTALL_NEOVIM=1
                INSTALL_TMUX=1; INSTALL_DIRENV=1; INSTALL_OBSIDIAN=1
                INSTALL_AEROSPACE=1; INSTALL_SCRIPTS=1; ANY_INSTALL=1
                ;;
            --install-shell)     INSTALL_SHELL=1; ANY_INSTALL=1 ;;
            --install-inputrc)   INSTALL_INPUTRC=1; ANY_INSTALL=1 ;;
            --install-psqlrc)    INSTALL_PSQLRC=1; ANY_INSTALL=1 ;;
            --install-git)       INSTALL_GIT=1; ANY_INSTALL=1 ;;
            --install-claude)    INSTALL_CLAUDE=1; ANY_INSTALL=1 ;;
            --install-vscode)    INSTALL_VSCODE=1; ANY_INSTALL=1 ;;
            --install-neovim)    INSTALL_NEOVIM=1; ANY_INSTALL=1 ;;
            --install-tmux)      INSTALL_TMUX=1; ANY_INSTALL=1 ;;
            --install-alacritty) INSTALL_ALACRITTY=1; ANY_INSTALL=1 ;;
            --install-direnv)    INSTALL_DIRENV=1; ANY_INSTALL=1 ;;
            --install-obsidian)  INSTALL_OBSIDIAN=1; ANY_INSTALL=1 ;;
            --install-ai-tools)  INSTALL_AI_TOOLS=1; ANY_INSTALL=1 ;;
            --install-ssh)       INSTALL_SSH=1; ANY_INSTALL=1 ;;
            --install-scripts)   INSTALL_SCRIPTS=1; ANY_INSTALL=1 ;;
            --install-aerospace) INSTALL_AEROSPACE=1; ANY_INSTALL=1 ;;
            --obsidian-vault)
                shift
                OBSIDIAN_VAULT="${1:?--obsidian-vault requires a path argument}"
                ;;
            --no-diffs) SAVE_DIFFS=0 ;;
            --help|-h) usage ;;
            *)
                echo "Unknown option: $1" >&2
                echo "Run with --help for usage." >&2
                exit 1
                ;;
        esac
        shift
    done
}

check_deps() {
    local missing=0
    for cmd in curl unzip diff; do
        if ! command -v "$cmd" &>/dev/null; then
            echo "Error: '$cmd' is required but not found." >&2
            missing=1
        fi
    done
    if [ "$missing" -eq 1 ]; then exit 1; fi
}

download_and_extract() {
    CLEANUP_DIR=$(mktemp -d)

    echo "Downloading portable dotfiles..."
    if ! curl -fsSL "$DOWNLOAD_URL" -o "$CLEANUP_DIR/dotfiles-portable.zip" </dev/null 2>&1; then
        echo "Error: Failed to download portable dotfiles from:" >&2
        echo "  $DOWNLOAD_URL" >&2
        echo "Make sure the release exists at https://github.com/mjmaurer/infra/releases/tag/portable-dotfiles" >&2
        exit 1
    fi

    echo "Extracting..."
    unzip -qo "$CLEANUP_DIR/dotfiles-portable.zip" -d "$CLEANUP_DIR/portable"
    chmod -R u+w "$CLEANUP_DIR/portable"

    # Always overwrite the portable cache
    if [ -d "$PORTABLE_DIR" ]; then
        chmod -R u+w "$PORTABLE_DIR" 2>/dev/null || true
        rm -rf "$PORTABLE_DIR"
    fi
    mkdir -p "$PORTABLE_DIR"
    cp -a "$CLEANUP_DIR/portable/." "$PORTABLE_DIR/"

    echo "Portable dotfiles cached at: $PORTABLE_DIR"
}

# Record diff for a single file. Args: $1=source (new), $2=target (existing location)
record_diff() {
    local src="$1" target="$2"
    if [ ! -f "$target" ]; then
        INSTALLED_FILES="${INSTALLED_FILES}  [new] ${target}\n"
        return
    fi
    local d
    d=$(diff -u "$target" "$src" 2>/dev/null || true)
    if [ -n "$d" ]; then
        INSTALLED_FILES="${INSTALLED_FILES}  [changed] ${target}\n"
        DIFF_CONTENT="${DIFF_CONTENT}--- ${target}\n+++ ${src}\n${d}\n\n"
    else
        INSTALLED_FILES="${INSTALLED_FILES}  [unchanged] ${target}\n"
    fi
}

# Record diffs for all files in a directory. Args: $1=source dir, $2=target dir
record_diffs_dir() {
    local src_dir="$1" target_dir="$2"
    [ ! -d "$src_dir" ] && return
    while IFS= read -r src_file; do
        local rel="${src_file#"$src_dir"/}"
        record_diff "$src_file" "$target_dir/$rel"
    done < <(find "$src_dir" -type f | sort)
}

# Install a single file. Args: $1=relative path, $2=optional target override
install_file() {
    local rel_path="$1"
    local target="${2:-$HOME/$rel_path}"
    local src="$PORTABLE_DIR/$rel_path"
    if [ ! -e "$src" ]; then
        echo "  [skip] $rel_path (not in portable dotfiles)"
        return
    fi
    record_diff "$src" "$target"
    mkdir -p "$(dirname "$target")"
    cp -f "$src" "$target"
}

# Install a directory. Args: $1=relative path, $2=optional target override
install_dir() {
    local rel_path="$1"
    local target="${2:-$HOME/$rel_path}"
    local src="$PORTABLE_DIR/$rel_path"
    if [ ! -d "$src" ]; then
        echo "  [skip] $rel_path/ (not in portable dotfiles)"
        return
    fi
    record_diffs_dir "$src" "$target"
    mkdir -p "$target"
    cp -a "$src/." "$target/"
}

# --- Drop-in handlers ---

install_git_dropin() {
    local include_path="$PORTABLE_DIR/.gitconfig"
    local gitconfig="$HOME/.gitconfig"

    if [ -f "$include_path" ]; then
        record_diff "$include_path" "$gitconfig"
        if [ -f "$gitconfig" ] && grep -qF "$include_path" "$gitconfig" 2>/dev/null; then
            INSTALLED_FILES="${INSTALLED_FILES}  [drop-in] Include already present in ${gitconfig}\n"
        elif [ -f "$gitconfig" ]; then
            printf '\n[include]\n    path = %s\n' "$include_path" >> "$gitconfig"
            INSTALLED_FILES="${INSTALLED_FILES}  [drop-in] Appended include to ${gitconfig}\n"
        else
            printf '[include]\n    path = %s\n' "$include_path" > "$gitconfig"
            INSTALLED_FILES="${INSTALLED_FILES}  [drop-in] Created ${gitconfig} with include\n"
        fi
    else
        echo "  [skip] .gitconfig (not in portable dotfiles)"
    fi

    # .config/git/ is copied directly
    install_dir ".config/git"
}

install_ssh_dropin() {
    local include_path="$PORTABLE_DIR/.ssh/config"
    local ssh_dir="$HOME/.ssh"
    local ssh_config="$ssh_dir/config"

    if [ ! -f "$include_path" ]; then
        echo "  [skip] .ssh/config (not in portable dotfiles)"
        return
    fi

    record_diff "$include_path" "$ssh_config"

    if [ ! -d "$ssh_dir" ]; then
        mkdir -p "$ssh_dir"
        chmod 700 "$ssh_dir"
    fi

    if [ -f "$ssh_config" ] && grep -qF "$include_path" "$ssh_config" 2>/dev/null; then
        INSTALLED_FILES="${INSTALLED_FILES}  [drop-in] Include already present in ${ssh_config}\n"
    elif [ -f "$ssh_config" ]; then
        local tmp
        tmp=$(mktemp)
        printf 'Include %s\n\n' "$include_path" > "$tmp"
        cat "$ssh_config" >> "$tmp"
        mv "$tmp" "$ssh_config"
        chmod 600 "$ssh_config"
        INSTALLED_FILES="${INSTALLED_FILES}  [drop-in] Prepended Include to ${ssh_config}\n"
    else
        printf 'Include %s\n' "$include_path" > "$ssh_config"
        chmod 600 "$ssh_config"
        INSTALLED_FILES="${INSTALLED_FILES}  [drop-in] Created ${ssh_config} with Include\n"
    fi
}

# --- Category installers ---

do_install_shell() {
    echo "Installing shell dotfiles..."
    install_file ".zshrc"
    install_file ".bashrc"
    install_file ".p10k.zsh"
}

do_install_inputrc() {
    echo "Installing inputrc..."
    install_file ".inputrc"
}

do_install_psqlrc() {
    echo "Installing psqlrc..."
    install_file ".psqlrc"
}

do_install_git() {
    echo "Installing git config (drop-in)..."
    install_git_dropin
}

do_install_claude() {
    echo "Installing Claude Code config..."
    install_dir ".claude"
}

do_install_vscode() {
    echo "Installing VSCode config..."
    install_dir ".config/Code"
}

do_install_neovim() {
    echo "Installing Neovim config..."
    install_dir ".config/nvim"
}

do_install_tmux() {
    echo "Installing tmux config..."
    install_dir ".config/tmux"
    install_dir ".config/tmuxp"
}

do_install_alacritty() {
    echo "Installing Alacritty config..."
    install_dir ".config/alacritty"
}

do_install_direnv() {
    echo "Installing direnv config..."
    install_dir ".config/direnv"
}

do_install_obsidian() {
    echo "Installing Obsidian vault..."
    install_dir "Documents/obsidian" "$OBSIDIAN_VAULT"
}

do_install_ai_tools() {
    echo "Installing AI tools config..."
    install_dir ".config/aichat"
    install_dir ".config/ai"
    install_dir ".config/mcp"
    install_dir ".config/llm"
    install_dir ".config/streamdown"
    install_file ".aider.conf.yml"
    install_file ".aider.model.settings.yml"
    install_dir ".config/aider"
}

do_install_ssh() {
    echo "Installing SSH config (drop-in)..."
    install_ssh_dropin
}

do_install_aerospace() {
    echo "Installing Aerospace config..."
    install_file ".aerospace.toml"
}

do_install_scripts() {
    echo "Installing scripts..."
    install_dir ".local/bin"
    # Make scripts executable
    if [ -d "$HOME/.local/bin" ]; then
        find "$HOME/.local/bin" -type f -exec chmod +x {} +
    fi
}

main() {
    parse_args "$@"
    check_deps
    download_and_extract

    if [ "$ANY_INSTALL" -eq 0 ]; then
        echo ""
        echo "No install flags provided. Dotfiles cached only."
        echo "Run with --install-minimal or --help to see install options."
        exit 0
    fi

    echo ""

    [ "$INSTALL_SHELL" -eq 1 ]     && do_install_shell     || true
    [ "$INSTALL_INPUTRC" -eq 1 ]   && do_install_inputrc   || true
    [ "$INSTALL_PSQLRC" -eq 1 ]    && do_install_psqlrc    || true
    [ "$INSTALL_GIT" -eq 1 ]       && do_install_git       || true
    [ "$INSTALL_CLAUDE" -eq 1 ]    && do_install_claude    || true
    [ "$INSTALL_VSCODE" -eq 1 ]    && do_install_vscode    || true
    [ "$INSTALL_NEOVIM" -eq 1 ]    && do_install_neovim    || true
    [ "$INSTALL_TMUX" -eq 1 ]      && do_install_tmux      || true
    [ "$INSTALL_ALACRITTY" -eq 1 ] && do_install_alacritty || true
    [ "$INSTALL_DIRENV" -eq 1 ]    && do_install_direnv    || true
    [ "$INSTALL_OBSIDIAN" -eq 1 ]  && do_install_obsidian  || true
    [ "$INSTALL_AI_TOOLS" -eq 1 ]  && do_install_ai_tools  || true
    [ "$INSTALL_SSH" -eq 1 ]       && do_install_ssh       || true
    [ "$INSTALL_AEROSPACE" -eq 1 ] && do_install_aerospace || true
    [ "$INSTALL_SCRIPTS" -eq 1 ]   && do_install_scripts   || true

    # Print summary
    echo ""
    echo "=== Installed files ==="
    printf '%b' "$INSTALLED_FILES"

    # Print diffs
    if [ -n "$DIFF_CONTENT" ]; then
        echo ""
        echo "=== Diffs ==="
        printf '%b' "$DIFF_CONTENT"
    fi

    # Save diffs
    if [ "$SAVE_DIFFS" -eq 1 ] && [ -n "$DIFF_CONTENT" ]; then
        mkdir -p "$DIFFS_DIR"
        printf '%b' "# $(date '+%Y-%m-%d %H:%M:%S')\n\n${DIFF_CONTENT}" >> "$DIFFS_DIR/$TODAY.diff"
        echo "Diffs saved to: $DIFFS_DIR/$TODAY.diff"
    fi

    echo ""
    echo "Done."
}

main "$@"
