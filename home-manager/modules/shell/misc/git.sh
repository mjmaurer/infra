# ------------------------------------ Git ----------------------------------- #

git_local_exclude() {
  # Add's a file to .git/info/exclude if .git exists
  if [ -z ".git" ]; then
    echo "Git repo not found"
    return
  fi
  local to_exclude=$(fd --strip-cwd-prefix . | fzf --header 'Select file to exclude from git')
  if [ -z "$to_exclude" ]; then
    echo "No file to exclude selected"
    return
  fi
  echo "$to_exclude" >> .git/info/exclude
}