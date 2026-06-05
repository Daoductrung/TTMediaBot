# TTMediaBot Project Analysis

## Overview
**TTMediaBot** is a media streaming bot designed for TeamTalk 5. This repository is a fork by João Almeida of the original TTMediaBot by gumerov-amir. It provides a robust, containerized solution to playing music in TeamTalk channels from various sources.

## Core Architecture
- **Language**: Python 3.10
- **Framework/Libraries**: 
  - TeamTalk 5 SDK (`libTeamTalk5.so`, `TeamTalkPy` wrapper).
  - Media extraction: `yt-dlp` (master branch for latest fixes).
  - Search: `py-yt-search` (YouTube) and `ytmusicapi` (YouTube Music).
  - Playback backend: `libmpv` (via `mpv.py`) and `ffmpeg` / `pulseaudio`.
- **Environment**: Containerized using Docker (`debian:bullseye-slim` based image) to ensure dependency isolation, especially for native libraries.
- **Entry Point**: `TTMediaBot.py`, which initializes the `Bot` class from `bot/__init__.py`.

## Key Features & Modifications in this Fork
1. **YouTube Music Exclusive Support**: A highly requested feature over vanilla YouTube. It allows switching between search services via the `sv yt` and `sv ytm` commands.
2. **Link-Based Downloading**: An advanced queueing system that lets users stash links (`aad`, `ad`) and selectively download them directly to the TeamTalk server or server host (`ads`, `adsc`), with ZIP compression options.
3. **Cookie Authentication**: Crucial for bypassing YouTube restrictions. The bot requires a `cookies.txt` file from a verified Google account to play YouTube / YT Music streams without arbitrary blocking.
4. **Stripped Features**: Removed Yandex Music and VK integration to focus on performance and stability.

## Project Structure
- `bot/`: Core logic folder.
  - `commands/`: Implementations for the various user and admin commands.
  - `config/`: Configuration parsing and default settings generation.
  - `connectors/`: Connection management.
  - `player/`: Media playback logic (MPV bindings, track queuing, state enums).
  - `services/`: Specific music service integrations (e.g., `yt.py`, `ytm.py`).
- `TeamTalkPy/`: Python wrapper and types for the TeamTalk SDK.
- `tools/`: Utility scripts, such as compiling locales (`compile_locales.py`).
- `locale/`: Support for 8 different languages (ar, en, es, hu, id, pt_BR, ru, tr).
- `ttbotdocker.sh` / `update.sh`: Bash scripts for setting up, managing, duplicating, and updating bot instances across Docker containers.

## Operational Workflow
- Each bot instance runs in its own Docker container.
- Configurations, caches, logs, and cookies are mounted as volumes from the `bots/[bot_name]` directory on the host to `/home/ttbot/TTMediaBot/data` in the container.
- The `config.json` stores all connection data, credentials, admin user IDs, and playback preferences.
- Administration scripts make it simple to batch-create multiple bot instances or perform rolling updates.

## Development & Maintenance Notes
- **Updating Dependencies**: The Dockerfile uses a `CACHEBUST` arg to enforce reinstalling `-U requirements.txt` and `yt-dlp` from master to keep up with YouTube API changes.
- **Node.js**: The container includes Node.js (v20), primarily used by certain `yt-dlp` extractors or local scripts to evaluate complex JS challenges from media sites.
- **Audio System**: Uses PulseAudio within the container to route sound properly into the TeamTalk channels.

This context document will serve as a reference for any future additions or bug fixes required on the project.
