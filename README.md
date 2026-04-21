# YT Audio CLI Player

Simple Bash-based YouTube audio caching + background player.

## Features

- Reads tracks from `config.json` (`query` or `url`)
- Downloads only the first hour of audio
- Caches locally and skips re-downloads
- Plays cached tracks in a loop in the background
- Stores player PID for clean stop/start behavior

## Requirements

- `yt-dlp`
- `mpv`
- `jq`

Install on Ubuntu/Debian:

```bash
sudo apt install yt-dlp mpv jq
```

## Usage

1. Edit `config.json` with your items.
2. Run:

```bash
chmod +x yt-player.sh
./yt-player.sh
```

## Config format

```json
{
  "items": [
    { "name": "lofi", "query": "lofi hip hop radio" },
    { "name": "mix1", "url": "https://www.youtube.com/watch?v=yIQd2Ya0Ziw" }
  ]
}
```

## Behavior

- Cached files are stored in `./cache/`
- Only first 3600 seconds are downloaded
- Existing cache entries are reused
- `mpv` runs in background with infinite playlist loop
- PID is saved at `.mpv.pid`

## Stop playback

```bash
kill "$(cat .mpv.pid)"
rm -f .mpv.pid
```
