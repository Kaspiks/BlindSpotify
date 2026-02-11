# BeatDrop

A Rails application for importing Spotify playlists, generating QR codes for tracks, and playing music "blindly" without revealing track info.

## Features (Planned)

- **Spotify OAuth**: Connect with Spotify using Authorization Code with PKCE
- **Playlist Import**: Import playlists from Spotify Web API
- **QR Code Generation**: Generate unique QR codes for each track (tokenized URLs)
- **Blind Listening UI**: Play tracks without seeing artist, title, or album art
- **Admin/Curator UI**: View tracks with thumbnails and QR generation controls
- **Live Progress**: Real-time QR generation progress via Turbo Streams

## Tech Stack

- **Rails 8** with Hotwire (Turbo + Stimulus)
- **Tailwind CSS** for styling
- **PostgreSQL** (production) / SQLite (development)
- **Redis** for session storage and background jobs
- **Solid Queue** for background job processing
- **RSpec** for testing

## Ruby Version

- Ruby 3.2.3
- Rails 8.0

## Development Setup

### Using Docker (recommended)

```bash
docker compose up --build
```

This starts:
- Rails development server at http://localhost:3024
- PostgreSQL database
- Redis for session storage

### Local Development

Requires Ruby 3.2.3 installed locally. Uses SQLite by default.

```bash
bundle install
rails db:prepare
rails server
```

For Redis session storage (recommended):
```bash
export REDIS_SESSION_STORE_URL=redis://localhost:6371/0
rails server
```

## Running Tests

### Using Docker

```bash
docker compose up -d
docker compose exec test bash
bundle exec rspec
```

### Local

```bash
export REDIS_SESSION_STORE_URL=redis://localhost:6371/0
bundle exec rspec
```

## Environment Variables

| Variable | Required | Description |
|----------|----------|-------------|
| `REDIS_SESSION_STORE_URL` | Yes (dev/test) | Redis URL for session storage |
| `DATABASE_ADAPTER` | No | Set to `postgresql` to use PostgreSQL instead of SQLite |
| `DATABASE_HOST` | If PostgreSQL | PostgreSQL host |
| `DATABASE_PORT` | If PostgreSQL | PostgreSQL port (default: 5421) |
| `DATABASE_NAME` | If PostgreSQL | Database name |
| `DATABASE_USERNAME` | If PostgreSQL | Database username |
| `DATABASE_PASSWORD` | If PostgreSQL | Database password |
| `SPOTIFY_CLIENT_ID` | For Spotify | Spotify App Client ID |
| `SPOTIFY_CLIENT_SECRET` | For Spotify | Spotify App Client Secret |
| `ARUCO_GENERATOR_URL` | No | Optional URL for on-demand ArUco marker images (e.g. on Hetzner). If unset, pre-generated PNGs in `vendor/assets/aruco/` are used. |

## ArUco printable cards (optional)

Card fronts can use **ArUco markers** instead of (or in addition to) text. When a user scans a track QR and opens the player, they can tap **Scan deck** to take a photo of their physical cards; the app detects marker IDs and shows an overview by year (artist – song).

- **Pre-generated markers** (recommended for Render): run once to create PNGs in `vendor/assets/aruco/`:
  ```bash
  pip install -r scripts/aruco/requirements.txt
  python scripts/aruco/generate_markers.py --count 200
  # or: bundle exec rake aruco:generate[200]
  ```
- **Deck scan** requires Python 3 and OpenCV with contrib on the server (e.g. Hetzner). The endpoint runs `scripts/aruco/detect_markers.py` on the uploaded image. If Python/OpenCV are not available, the scan returns no cards (graceful fallback).
- **Optional generator service** (Hetzner): set `ARUCO_GENERATOR_URL` to a service that serves `GET /marker/:id.png` to generate markers on demand and avoid committing many PNGs.

## Project Structure

```
app/
├── controllers/        # Request handlers
├── decorators/         # View decorators (SimpleDelegator-based)
├── forms/              # Form objects for complex forms
├── helpers/            # View helpers
├── javascript/         # Stimulus controllers
├── jobs/               # Background jobs
├── lib/                # Application-specific libraries
├── models/             # ActiveRecord models
├── policies/           # Pundit authorization policies
├── presenters/         # View presenters
├── services/           # Service objects
│   └── spotify/        # Spotify API integration (placeholder)
└── views/
    ├── playlists/      # Playlist views (placeholder)
    └── track_qr_codes/ # QR code views (placeholder)
```

## Architecture Patterns

This boilerplate includes several patterns for building maintainable Rails applications:

- **Service Objects**: `app/services/` - Encapsulate business logic
- **Form Objects**: `app/forms/` - Handle complex form logic
- **Decorators**: `app/decorators/` - Add view logic to models
- **Presenters**: `app/presenters/` - Prepare data for views
- **Policies**: `app/policies/` - Authorization with Pundit

## Icons

Uses [Tabler Icons](https://tabler.io/icons) bundled as an SVG sprite.

To add new icons:
1. Edit `icons/build-sprite.js`
2. Run: `docker compose run --rm node sh -c "npm install && node build-sprite.js"`

## License

Private project.
