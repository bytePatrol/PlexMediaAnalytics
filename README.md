<p align="center">
  <img src="Plex Library Analytics/Logo.png" width="128" alt="Plex Library Analytics">
</p>

<h1 align="center">Plex Library Analytics</h1>

<p align="center">
  A powerful macOS application that gives you deep insights into your Plex media library — quality breakdowns, storage analysis, codec distributions, and more.
</p>

<p align="center">
  <img src="https://img.shields.io/badge/macOS-14.0%2B-blue?style=flat-square&logo=apple" />
  <img src="https://img.shields.io/badge/Swift-5.0-orange?style=flat-square&logo=swift" />
  <img src="https://img.shields.io/badge/SwiftUI-native-green?style=flat-square" />
  <img src="https://img.shields.io/badge/license-MIT-lightgrey?style=flat-square" />
</p>

---

## Screenshots

| Dashboard | Library Browser |
|-----------|----------------|
| ![Dashboard](docs/screenshots/dashboard.png) | ![Library](docs/screenshots/library.png) |

| Analytics | Media Detail |
|-----------|-------------|
| ![Analytics](docs/screenshots/analytics.png) | ![Detail](docs/screenshots/detail.png) |

---

## Features

### Dashboard
- **At-a-glance stats** — total item count, storage used, 4K content percentage, and recently added items
- **Library overview cards** — per-library quality distribution pie charts with last-added media previews
- **Recent activity chart** — 30-day bar chart of items added to your server

### Library Browser
- **Full media table** — browse every item across all libraries with columns for title, date added, file size, resolution, codec, bitrate, audio format, and HDR
- **Live search** — filter by title, year, codec, or resolution instantly
- **Sidebar filters** — narrow by library, resolution, video codec, file size range, and date added
- **Multi-column sorting** — sort ascending or descending by any column
- **Pagination** — configurable page size for large libraries
- **Media detail sheet** — full technical breakdown per item including video, audio, subtitles, and file metadata
- **Open in Plex** — deep-link directly to any item in the Plex web player
- **Show in Finder** — reveal the media file in Finder (local servers), or copy the path to clipboard (remote servers)
- **CSV export** — export the current filtered view to a spreadsheet

### Analytics
- **Storage by library** — horizontal bar chart comparing library sizes
- **Quality distribution** — donut chart breaking down 4K / 1080p / 720p / SD across your entire library
- **Content over time** — line and area chart showing library growth
- **Audio codec breakdown** — visualise Dolby Atmos, DTS-X, TrueHD, and more
- **File size distribution** — histogram of file sizes across your collection
- **Summary stat boxes** — average bitrate, average file size, HDR percentage, and total duration

### Connectivity
- **Plex OAuth sign-in** — secure browser-based sign-in via plex.tv; no password ever stored in the app
- **Automatic server discovery** — fetches all servers linked to your Plex account after sign-in
- **Manual server entry** — connect directly with host, port, and token for advanced setups
- **Self-signed certificate support** — works with local Plex servers using HTTPS and self-signed certs
- **Token storage in Keychain** — authentication tokens are stored securely in the macOS Keychain, never in plain text
- **Auto-reconnect** — remembers your last server and reconnects on launch
- **Configurable auto-refresh** — keep stats up to date automatically (5 min, 15 min, 30 min, 1 hour)

### Settings
- **General** — default tab, page size, thumbnail toggle
- **Servers** — manage saved servers, add or remove connections
- **Display** — UI preferences
- **Performance** — auto-refresh interval

---

## Requirements

| Requirement | Version |
|-------------|---------|
| macOS | 14.0 Sonoma or later |
| Plex Media Server | Any recent version |
| Xcode (to build) | 15.0 or later |

---

## Installation

### Option A — DMG (Recommended)

1. Download **`Plex Library Analytics.dmg`** from the [latest release](https://github.com/bytePatrol/PlexMediaAnalytics/releases/latest)
2. Open the DMG and drag **Plex Library Analytics.app** to your **Applications** folder
3. Launch the app, click **Connect Server**, and sign in with your Plex account

> **First launch:** macOS may show a Gatekeeper warning because the app is not notarised. Right-click the app → **Open** → **Open** to bypass it.

### Option B — Build from Source

```bash
# Clone the repository
git clone https://github.com/bytePatrol/PlexMediaAnalytics.git
cd PlexMediaAnalytics

# Generate the Xcode project (requires XcodeGen)
brew install xcodegen
xcodegen generate

# Open in Xcode
open "Plex Library Analytics.xcodeproj"
```

Then build and run with **⌘R** in Xcode, or from the command line:

```bash
xcodebuild -project "Plex Library Analytics.xcodeproj" \
           -scheme "Plex Library Analytics" \
           -configuration Release \
           build
```

---

## Getting Started

1. **Launch** the app — it opens in Demo Mode with sample data so you can explore the UI immediately
2. Click **Connect Server** in the welcome banner (or via the **Server** menu)
3. Choose **Sign in with Plex** to authenticate via plex.tv, or enter your server details manually
4. Your libraries will load automatically after connecting
5. Use the **Dashboard**, **Libraries**, and **Analytics** tabs to explore your collection

---

## Project Structure

```
Plex Library Analytics/
├── App/                        # App entry point and root view
├── Models/                     # Data models (PlexServer, PlexLibrary, MediaItem)
├── Services/
│   ├── PlexAPIClient.swift     # REST API client with self-signed cert support
│   ├── PlexRepository.swift    # Data layer with Combine publishers
│   ├── PlexOAuthService.swift  # Plex OAuth PIN-based authentication
│   ├── KeychainManager.swift   # Secure token storage
│   └── MockDataProvider.swift  # Demo data for offline preview
├── ViewModels/                 # MVVM view models (AppState, Dashboard, Library, Analytics)
├── Views/
│   ├── Dashboard/              # Dashboard tab views
│   ├── Library/                # Library browser, table, filters, detail sheet
│   ├── Analytics/              # Charts and analytics views
│   ├── Settings/               # Settings window
│   ├── Onboarding/             # Server setup / OAuth flow
│   └── Components/             # Shared UI components
├── Utilities/
│   ├── Theme.swift             # Design tokens and view modifiers
│   └── Formatters.swift        # Number, date, and size formatters
└── Resources/
    └── Assets.xcassets         # App icon and colour assets
```

---

## Architecture

- **Pattern:** MVVM with a Repository layer
- **State management:** `AppState` as a shared `@EnvironmentObject` with Combine publishers
- **Navigation:** Tab-based (`Dashboard`, `Libraries`, `Analytics`) via `ContentView`
- **Networking:** `URLSession` with a custom `URLSessionDelegate` for self-signed TLS certificates
- **Security:** OAuth tokens stored exclusively in the macOS Keychain via `SecItemAdd` / `SecItemCopyMatching`
- **Charts:** Native Swift Charts framework (no third-party dependencies)

---

## Privacy & Security

- **No data leaves your network** — the app communicates only with your Plex server and plex.tv for authentication
- **No telemetry or analytics** — zero tracking, zero third-party SDKs
- **Keychain storage** — auth tokens are stored in the macOS Keychain, not UserDefaults or files
- **Read-only** — the app never modifies your Plex library or metadata

---

## License

MIT License — see [LICENSE](LICENSE) for details.
