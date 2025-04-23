# ------------------------------------ Nix ----------------------------------- #

new_nix_flake() {
    # Check if shell.nix already exists
    if [ -f "flake.nix" ]; then
        echo "flake.nix already exists in current directory"
        read -p "Overwrite? [y/N] " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi

    # Check if template directory exists
    if [ ! -f "$NIX_TEMPLATE_FILE" ]; then
        echo "Template file $NIX_TEMPLATE_FILE does not exist"
        exit 1
    fi


    cp "$NIX_TEMPLATE_FILE" flake.nix
    chmod u+w flake.nix
    echo "Created flake.nix"
    echo "You can exclude it from git locally with: gle (git_local_exclude)"
    echo "May also want to create .envrc with 'use flake'"
}
