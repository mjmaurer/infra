#!/usr/bin/env bash


# Check if shell.nix already exists
if [ -f "shell.nix" ]; then
    echo "shell.nix already exists in current directory"
    read -p "Overwrite? [y/N] " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

TEMPLATE_DIR="${XDG_DATA_HOME}/nix-shell-templates"

# Check if template directory exists
if [ ! -d "$TEMPLATE_DIR" ]; then
    echo "Template directory $TEMPLATE_DIR does not exist"
    exit 1
fi

# Get list of available templates
templates=("$TEMPLATE_DIR"/*.nix)
if [ ${#templates[@]} -eq 0 ]; then
    echo "No templates found in $TEMPLATE_DIR"
    exit 1
fi

# If no argument provided, show selection menu
if [ -z "$1" ]; then

    echo "Select template by number:"
    templates_array=($(basename -a "${templates[@]}"))
    select template in "${templates_array[@]}"; do
        if [ -n "$template" ]; then
            selected="$TEMPLATE_DIR/$template.nix"
            if [ -f "$selected" ]; then
                break
            else
                selected="$TEMPLATE_DIR/$template"
                if [ -f "$selected" ]; then
                    break
                fi
            fi
        fi
        echo "Invalid selection"
    done
    echo "Selected: $selected"

else
    # Use provided argument
    selected="$TEMPLATE_DIR/$1.nix"
    if [ ! -f "$selected" ]; then
        echo "Template $1.nix not found"
        exit 1
    fi
fi

# Copy selected template to shell.nix
cp "$selected" shell.nix
echo "Created shell.nix from template $(basename "$selected")"
echo "You can exclude it from git locally with: gle (git_local_exclude)"
