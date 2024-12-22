#!/usr/bin/env bash


# Check if shell.nix already exists
if [ -f "flake.nix" ]; then
    echo "flake.nix already exists in current directory"
    read -p "Overwrite? [y/N] " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

TEMPLATE_DIR="${XDG_DATA_HOME}/nix-templates"

# Check if template directory exists
if [ ! -d "$TEMPLATE_DIR" ]; then
    echo "Template directory $TEMPLATE_DIR does not exist"
    exit 1
fi


# Copy selected template to shell.nix
cp "$TEMPLATE_DIR/flake-template.nix" flake.nix
chmod u+w flake.nix
echo "Created flake.nix"
echo "You can exclude it from git locally with: gle (git_local_exclude)"
