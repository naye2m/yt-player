Alright — here’s a **clean, no-BS setup** that does exactly what you want:

* Reads YouTube queries/URLs from JSON
* Caches audio (first 1 hour only)
* Avoids re-downloading
* Plays in background (looped)
* Simple + maintainable

---

# 📁 Project structure

```
yt-audio-cli/
├── yt-player.sh
├── config.json
├── cache/
└── README.md
```

---

# 🧠 1. `config.json`

```json
{
  "items": [
    {
      "name": "lofi",
      "query": "lofi hip hop radio"
    },
    {
      "name": "mix1",
      "url": "https://www.youtube.com/watch?v=yIQd2Ya0Ziw"
    }
  ]
}
```

---

# ⚙️ 2. `yt-player.sh`

```bash
#!/usr/bin/env bash

set -e

CONFIG="config.json"
CACHE_DIR="./cache"
MAX_DURATION=3600   # 1 hour
FORMAT="bestaudio[abr<=128]"

mkdir -p "$CACHE_DIR"

# check deps
for cmd in yt-dlp mpv jq; do
  command -v $cmd >/dev/null || { echo "$cmd not installed"; exit 1; }
done

process_item() {
  local name="$1"
  local query="$2"
  local url="$3"

  local file="$CACHE_DIR/${name}.webm"

  if [ -f "$file" ]; then
    echo "[✓] Cached: $name"
  else
    echo "[↓] Downloading: $name"

    if [ -n "$url" ]; then
      target="$url"
    else
      target="ytsearch1:${query}"
    fi

    yt-dlp \
      --download-sections "*0-${MAX_DURATION}" \
      -f "$FORMAT" \
      -o "$file" \
      "$target"
  fi
}

# parse JSON
count=$(jq '.items | length' "$CONFIG")

for i in $(seq 0 $((count - 1))); do
  name=$(jq -r ".items[$i].name" "$CONFIG")
  query=$(jq -r ".items[$i].query // empty" "$CONFIG")
  url=$(jq -r ".items[$i].url // empty" "$CONFIG")

  process_item "$name" "$query" "$url"
done

# play all in loop (background)
echo "[▶] Playing in background..."
mpv --no-video --loop=inf "$CACHE_DIR"/*.webm >/dev/null 2>&1 &
disown

echo "[✓] Started background player"
```

---

# 📘 3. `README.md`

````markdown
# YT Audio CLI Player

Simple bash-based YouTube audio caching + background player.

## Features

- Reads from JSON (queries or direct URLs)
- Downloads only first 1 hour
- Caches audio locally
- Avoids re-downloading
- Plays in infinite loop
- Runs in background

## Requirements

- yt-dlp
- mpv
- jq

Install (Ubuntu/Debian):

```bash
sudo apt install yt-dlp mpv jq
````

## Usage

1. Edit `config.json`:

```json
{
  "items": [
    { "name": "lofi", "query": "lofi hip hop" },
    { "name": "song1", "url": "https://youtube.com/watch?v=..." }
  ]
}
```

2. Run:

```bash
chmod +x yt-player.sh
./yt-player.sh
```

## Behavior

* Downloads audio into `./cache/`
* Limits to first 1 hour
* Reuses cached files if already downloaded
* Starts playback in background (looped)

## Stop playback

```bash
pkill mpv
```

## Notes

* Uses ~128kbps audio for size optimization
* First run downloads, next runs are instant

```

---

# ⚡ Why this is actually solid

- No pipe hacks → stable  
- Uses yt-dlp the way it’s meant to be used  
- mpv handles playback cleanly  
- JSON makes it extensible  

---

# 🚀 If you want next upgrades

I can extend this into:
- 🔍 :contentReference[oaicite:0]{index=0}
- 🎵 :contentReference[oaicite:1]{index=1}
- 🔄 :contentReference[oaicite:2]{index=2}
- 🌐 :contentReference[oaicite:3]{index=3}
- 🎛️ :contentReference[oaicite:4]{index=4}

Just tell me — this can turn into a **full terminal music system** pretty quickly.
```