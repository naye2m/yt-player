#!/usr/bin/env bash

set -euo pipefail

CONFIG="${1:-config.json}"
CACHE_DIR="./cache"
PID_FILE=".mpv.pid"
MAX_DURATION=0
# FORMAT="bestaudio[abr<=128]/bestaudio"
FORMAT="bestaudio/best"
# FORMAT="bestaudio[ext=m4a]/bestaudio/best" # // aggressive audio format selection, prefer m4a but fallback to any audio if not available
# FORMAT="bestaudio"

# kill if kill included in the command line arguments
if [[ "$#" -gt 0 ]] && [[ $1 == "kill" || $1 == "-k" || $1 == "--kill" || $1 == "k" ]]; then
# kill $(cat .mpv.pid) && rm .mpv.pid &&  echo
  if [ -f "$PID_FILE" ]; then
    while read -r pid; do
      if kill -0 "$pid" 2>/dev/null; then
        kill "$pid"
        echo "Killed player with PID $pid"
      else
        echo "No running player found with PID $pid"
      fi
    done < "$PID_FILE"
    rm -f "$PID_FILE"
    echo "Player stopped and PID file removed."
  else
    echo "No PID file found. Player may not be running."
  fi
  exit 0
fi


mkdir -p "$CACHE_DIR"

for cmd in yt-dlp mpv jq; do
  command -v "$cmd" >/dev/null || { echo "Missing dependency: $cmd" >&2; exit 1; }
done

if [ ! -f "$CONFIG" ]; then
  echo "Config not found: $CONFIG" >&2
  exit 1
fi

is_running() {
  local pid="$1"
  kill -0 "$pid" 2>/dev/null
}

sanitize_name() {
  printf "%s" "$1" | tr '[:space:]' '-' | tr -cd '[:alnum:]_.-'
}

if [ -f "$PID_FILE" ]; then
  existing_pid="$(cat "$PID_FILE" 2>/dev/null || true)"
  # if [ -n "${existing_pid:-}" ] && is_running "$existing_pid"; then
  #   echo "[i] Player already running (PID $existing_pid)"
  #   exit 0
  # fi
  # kill $(cat "$PID_FILE" 2>/dev/null || true) || true
  # rm -f "$PID_FILE"
  has_existing_pids=false
  for pid in $(cat "$PID_FILE" 2>/dev/null || true); do
    if is_running "$pid"; then
      echo "[i] Player already running with PID $pid"
      has_existing_pids=true
    else
      echo "[!] No running player found with PID $pid"
    fi
  done
  if $has_existing_pids; then
    echo "Please stop the existing player(s) before starting a new one." >&2
    exit 1
  else
    rm -f "$PID_FILE"
    echo "Removed stale PID file."
  fi
fi

count="$(jq '.items | length' "$CONFIG")"
if [ "$count" -eq 0 ]; then
  echo "No items found in $CONFIG" >&2
  exit 1
fi

for i in $(seq 0 $((count - 1))); do
  name="$(jq -r ".items[$i].name // empty" "$CONFIG")"
  query="$(jq -r ".items[$i].query // empty" "$CONFIG")"
  url="$(jq -r ".items[$i].url // empty" "$CONFIG")"
  volume="$(jq -r ".items[$i].volume // empty" "$CONFIG")"

  if [ -z "$name" ]; then
    echo "Item index $i is missing 'name'" >&2
    exit 1
  fi

  safe_name="$(sanitize_name "$name")"
  if [ -z "$safe_name" ]; then
    echo "Invalid name for item index $i: '$name'" >&2
    exit 1
  fi

  if [ -n "$url" ]; then
    target="$url"
  elif [ -n "$query" ]; then
    target="ytsearch1:${query}"
  else
    echo "Item '$name' must include either 'url' or 'query'" >&2
    exit 1
  fi

  if compgen -G "$CACHE_DIR/${safe_name}.*" >/dev/null; then
    echo "[✓] Cached: $name"
    continue
  fi

  echo "[↓] Downloading: $name"
  yt-dlp \
    --download-sections \
    "*0-${MAX_DURATION}" \
    -f "$FORMAT" \
    -o "$CACHE_DIR/${safe_name}.%(ext)s" \
    "$target"
  echo "[✓] Downloaded: $name and saved to $CACHE_DIR/${safe_name}.*"
done

shopt -s nullglob
audio_files=("$CACHE_DIR"/*)
if [ "${#audio_files[@]}" -eq 0 ]; then
  echo "No cached files to play" >&2
  exit 1
fi

# for file in "${audio_files[@]}"; do
for i in $(seq 0 $((count - 1))); do
  name="$(jq -r ".items[$i].name // empty" "$CONFIG")"
  safe_name="$(sanitize_name "$name")"
  file="$(compgen -G "$CACHE_DIR/${safe_name}.*" | head -n1)"
  volume="$(jq -r ".items[$i].volume // empty" "$CONFIG")"
  if [ -z "$file" ]; then
    echo "No cached file found for item '$name'" >&2
    continue
  fi
  echo "[✓] Ready to play: $(basename "$file")"
  # volume="$(jq -r ".items[$i].volume // empty" "$CONFIG")" X 100
  # volume="$(jq -r ".items[] | select(.name == \"$(basename "$file" | sed 's/\.[^.]*$//')\") | .volume // 1" "$CONFIG" | head -n1)"
  # if ! [[ "$volume" =~ ^[0-9]*\.?[0-9]+$ ]]; then
  #   volume="1"
  # fi
  volume="$(awk -v v="$volume" 'BEGIN {printf "%.0f", v * 100}')"
  nohup mpv --no-video --volume="$volume" --loop-playlist=inf "${file}" >/dev/null 2>&1 &
  pid=$!
  echo "$pid" >> "$PID_FILE"
  echo "[✓] Started player for $(basename "$file") (PID $pid)"
  echo "stopping player with: kill $pid"
done
# player_pid=$!
# echo "$player_pid" > "$PID_FILE"

# echo "[✓] Started background player (PID $player_pid)"
echo "[i] Stop with: kill $(cat "$PID_FILE") && rm -f $PID_FILE"
