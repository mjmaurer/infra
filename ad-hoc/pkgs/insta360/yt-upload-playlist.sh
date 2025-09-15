#!/usr/bin/env bash

set -euo pipefail

PRIVACY="private"

while getopts "p:" opt; do
  case $opt in
    p) PRIVACY="$OPTARG" ;;
    \?) exit 1 ;; # getopts will print an error
  esac
done
shift $((OPTIND - 1))

if [[ $# -ne 2 ]]; then
  echo "Usage: $0 [-p <privacy>] <directory> <playlist_id>"
  exit 1
fi

DIRECTORY="$1"
PLAYLIST_ID="$2"

if [[ "$PRIVACY" != "public" && "$PRIVACY" != "private" && "$PRIVACY" != "unlisted" ]]; then
  echo "Error: Invalid privacy: '$PRIVACY'. Must be 'public', 'private', or 'unlisted'." >&2
  exit 1
fi

if [[ ! -d "$DIRECTORY" ]]; then
  echo "Error: Directory not found at '$DIRECTORY'" >&2
  exit 1
fi

CONFIG_DIR="$HOME/.config/youtubeuploader"
CLIENT_SECRETS_FILE="$CONFIG_DIR/client_secrets.json"

if [[ ! -f "$CLIENT_SECRETS_FILE" ]]; then
  echo "ERROR: client_secrets.json not found." >&2
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
  filename=$(basename "$file")
  echo "Uploading '$title'..."

  if youtubeuploader \
    -privacy "$PRIVACY" \
    -filename "$file" \
    -title "$title" \
    -description "" \
    -notify false \
    -secrets $CLIENT_SECRETS_FILE \
    -playlistID "$PLAYLIST_ID"; then
    echo "Successfully uploaded '$title'."
    successful_uploads+=("$filename")
  else
    echo "Failed to upload '$title'." >&2
    failed_uploads+=("$filename")
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
