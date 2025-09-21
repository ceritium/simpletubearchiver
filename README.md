# Simple Tuve Archiver

A Rails application for archiving video content from YouTube channels and playlists. The app allows you to subscribe to channels or playlists and automatically downloads videos for offline viewing and archival purposes.

It is still a work in progress.

## Features

- **Channel & Playlist Subscriptions**: Subscribe to YouTube channels or playlists by URL
- **Automatic Video Discovery**: Automatically fetches new videos from subscribed sources
- **Video Downloads**: Downloads videos using yt-dlp for offline viewing
- **Background Processing**: Uses Solid Queue for handling downloads and metadata fetching
- **Web Interface**: Simple web UI for managing subscriptions and viewing archived content
- **Thumbnail Support**: Automatically fetches and stores video thumbnails
- **Real-time Updates**: Uses Turbo Streams for live status updates

## Tech Stack

- **Ruby on Rails 8.0** - Web framework
- **SQLite** - Database (with Solid Cache and Solid Queue)
- **yt-dlp** - Video downloading engine
- **Active Storage** - File storage for videos and thumbnails
- **Turbo/Stimulus** - Real-time UI updates
- **Docker** - Containerized deployment

## Requirements

- Ruby 3.2.2 (see `.ruby-version`)
- Docker (for containerized deployment)
- yt-dlp (automatically installed in Docker)


docker run --rm -p 80:80 -e DISABLE_SSL=true -e RAILS_MASTER_KEY=$(cat config/master.key) -v $(pwd)/storage:/rails/storage --name simpletuvearchiver simpletuvearchiver
docker run --rm -e DISABLE_SSL=true -e RAILS_MASTER_KEY=$(cat config/master.key) -v $(pwd)/storage:/rails/storage --name simpletuvearchiver-jobs simpletuvearchiver -- ./bin/jobs

## Running with Docker Compose

This project includes a `docker-compose.yml` for easy setup of the Rails server and background jobs. No external database is required; SQLite is used and persisted in the `storage/` directory.

### 1. Set your Rails master key

```bash
export RAILS_MASTER_KEY=$(cat config/master.key)
```

### 2. Build and start all services

```bash
docker compose up --build
```

- The Rails server will be available at http://localhost:80
- Background jobs will run in a separate container
- Uploaded files and the SQLite database are persisted in the `storage/` directory

### 3. Stopping services

Press `Ctrl+C` or run:
```bash
docker compose down
```

### 4. Useful commands

- Rebuild after code changes:
  ```bash
  docker compose build
  ```
- View logs for a service:
  ```bash
  docker compose logs web
  docker compose logs jobs
  ```
- Run Rails console:
  ```bash
  docker compose exec web rails console
  ```

## Generating a Rails master key for Docker deployment

To deploy this app as a Docker image, you need a Rails master key for encrypted credentials.

1. Generate a master key (if you don't have one):
   ```bash
   bin/rails credentials:edit
   ```
   This will create `config/master.key` and `config/credentials.yml.enc` if they do not exist.

2. Use the master key for Docker:
   ```bash
   export RAILS_MASTER_KEY=$(cat config/master.key)
   ```
   Then pass it to Docker:
   ```bash
   docker run -e RAILS_MASTER_KEY=$RAILS_MASTER_KEY ...
   ```
