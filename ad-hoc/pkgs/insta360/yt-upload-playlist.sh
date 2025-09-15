#!/usr/bin/env bash

set -euo pipefail

if [[ $# -ne 2 ]]; then
  echo "Usage: $0 <directory> <playlist_name>"
  exit 1
fi

DIRECTORY="$1"
PLAYLIST_NAME="$2"

if [[ ! -d "$DIRECTORY" ]]; then
  echo "Error: Directory not found at '$DIRECTORY'" >&2
  exit 1
fi

CONFIG_DIR="$HOME/.config/yt-upload-playlist"
CLIENT_SECRETS_FILE="$CONFIG_DIR/client_secret.json"
TOKEN_FILE="$CONFIG_DIR/token.json"

if [[ ! -f "$CLIENT_SECRETS_FILE" ]]; then
  echo "ERROR: client_secret.json not found." >&2
  echo "Please obtain your OAuth 2.0 client ID from the Google Cloud Console" >&2
  echo "and place it at: $CLIENT_SECRETS_FILE" >&2
  exit 1
fi

mkdir -p "$CONFIG_DIR"

# Using null delimiter for safety with filenames containing spaces
mapfile -d '' video_files < <(find "$DIRECTORY" -maxdepth 1 -type f -name "*.mp4" -print0 | sort -z)

if [[ ${#video_files[@]} -eq 0 ]]; then
  echo "No .mp4 files found in '$DIRECTORY'."
  exit 0
fi

echo -e "\nFound ${#video_files[@]} videos to upload."
successful_uploads=()
failed_uploads=()

for file in "${video_files[@]}"; do
  title=$(basename "$file" .mp4)
  echo "Uploading '$title'..."

  if youtube-upload \
    --privacy=private \
    --title="$title" \
    --playlist="$PLAYLIST_NAME" \
    --noauth_local_webserver \
    --client-secrets="$CLIENT_SECRETS_FILE" \
    --credentials-file="$TOKEN_FILE" \
    "$file"; then
    echo "Successfully uploaded '$title'."
    successful_uploads+=("$(basename "$file")")
  else
    echo "Failed to upload '$title'." >&2
    failed_uploads+=("$(basename "$file")")
  fi
  echo "--------------------"
done

echo -e "\n--- Upload Summary ---"
echo "Successfully uploaded ${#successful_uploads[@]} video(s):"
for name in "${successful_uploads[@]}"; do
  echo "  - $name"
done

if [[ ${#failed_uploads[@]} -gt 0 ]]; then
  echo -e "\nFailed to upload ${#failed_uploads[@]} video(s):"
  for name in "${failed_uploads[@]}"; do
    echo "  - $name"
  done
fi
echo "----------------------"

if [[ ${#failed_uploads[@]} -gt 0 ]]; then
  exit 1
fi
