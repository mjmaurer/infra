# ------------------------------------ FZF: Built-ins ----------------------------------- #

cpf() {
  # Copies a file or directory given a name. Uses FZF to select the file or directory.

  local to_copy=$(fd --strip-cwd-prefix . | fzf --header 'Select file or dir to copy')
  if [ -z "$to_copy" ]; then
    echo "No file to copy selected"
    return
  fi

  local parent=$(fd --type d --strip-cwd-prefix . | fzf --header 'Select parent directory')
  if [ -z "$parent" ]; then
    echo "No parent directory selected"
    return
  fi

  # Prompt for name via stdin:
  local name
  if [ -n "$ZSH_VERSION" ]; then
    vared -p "Name: " name
  else
    read -p "Name: " -e -i "$name" name
  fi
  if [ -z "$name" ]; then
    echo "No file or dir name provided"
    return
  fi

  # Get extensions (or lack thereof) for both files
  local to_copy_ext="${to_copy##*.}"
  local name_ext="${name##*.}"
  if [[ "$to_copy" != *"."* ]]; then
    to_copy_ext=""
  fi
  if [[ "$name" != *"."* ]]; then
    name_ext=""
  fi
  if [[ "$to_copy_ext" != "$name_ext" ]]; then
    echo "Error: File extensions must match"
    return 1
  fi

  cp -r "$to_copy" "$parent/$name"
}

mkf() {
  local name=$1
  if [ -z "$name" ]; then
    if [ -n "$ZSH_VERSION" ]; then
      vared -p "Name: " name
    else
      read -p "Name: " -e -i "$name" name
    fi
    if [ -z "$name" ]; then
      echo "No file or dir name provided"
      return
    fi
  fi
  # Add trailing slash if no extension and doesn't already end in slash
  if [[ "$name" != *.* ]] && [[ "$name" != */ ]]; then
    name="${name}/"
  fi
  if [ -z "$name" ] || [ "$name" = "/" ]; then
    echo "Name cannot be empty or a single slash"
    return 1
  fi
  # Creates a file or directory given a name. Uses FZF to select the parent directory.
  # It determines whether to create a file or directory based on whether the name ends with a slash.
  local dir=$(fd --type d --strip-cwd-prefix . | fzf --header 'Select parent directory')
  if [ -z "$dir" ]; then
    echo "No directory selected"
    return
  fi
  if [[ "$name" == */ ]]; then
    mkdir -p "$dir/$name"
  else
    touch "$dir/$name"
    # Hacky way to detect if VSCode is running
    if [ -n "$VSCODE_GIT_ASKPASS_MAIN" ]; then
      $VSCODE --goto "$dir/$name"
    fi
  fi
}

mvf() {
  local file=$(fd --strip-cwd-prefix . | fzf --header 'Select file or dir to move')
  if [ -z "$file" ]; then
    echo "No file or dir selected"
    return
  fi

  local new_dir=$(fd --type d --strip-cwd-prefix . | fzf --header 'Select new parent directory')
  if [ -z "$new_dir" ]; then
    echo "No new parent directory selected"
    return
  fi
  mv "$file" "$new_dir"
}

rnf() {
  local file=$(fd --strip-cwd-prefix . | fzf --header 'Select file or dir to rename')
  if [ -z "$file" ]; then
    echo "No file or dir selected"
    return
  fi

  local new_name=$(basename "$file")
  if [ -n "$ZSH_VERSION" ]; then
    vared -p "New name (sure you don't want to use IDE?): " new_name
  else
    read -p "New name (sure you don't want to use IDE?): " -e -i "$new_name" new_name
  fi

  if [ -z "$new_name" ] || [ "$new_name" = "$(basename "$file")" ]; then
    echo "No new name provided or name unchanged"
    return
  fi

  mv "$file" "$(dirname "$file")/$new_name"
}