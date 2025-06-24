# Changelog

All notable changes to GClouder will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.0.1] - 2025-01-03

### Added
- Initial release of GClouder - macOS menu bar utility for Google Cloud authentication
- Menu bar icon with authentication status indicator (cloud icon when authenticated, warning when not)
- Automatic authentication checking every minute
- Smart notifications when authentication expires (only on status changes, not every check)
- Clickable notifications to re-authenticate
- "Launch at Startup" functionality with checkbox indicator
- One-click Google Cloud authentication via `gcloud auth login --enable-gdrive-access --update-adc`
- Current Google Cloud account display in menu
- Debug submenu with:
  - Current gcloud path detection and display
  - Manual gcloud path configuration with persistent settings
  - Auto-detection fallback
- Optimized gcloud path detection (cached at startup, not on every command)
- Environment-aware execution (works in both debug and app bundle modes)
- Custom app icon for GClouder (cloud-themed icon in multiple resolutions)
- Debug authentication testing with `make test-auth` command
- Comprehensive debug logging for authentication flow troubleshooting
- Support for macOS 13.0+
- GitHub Actions for automated testing and releases

### Technical Features
- Intelligent gcloud executable detection across common installation paths
- UserDefaults persistence for manual gcloud path configuration
- Bundle detection to prevent notification crashes in debug mode
- Proper shell environment loading for gcloud commands
- Asynchronous authentication checking and account retrieval

### Security
- Ad-hoc code signing for local distribution
- Support for Developer ID signing when available

[Unreleased]: https://github.com/thejens/gclouder/compare/v0.0.1...HEAD
[0.0.1]: https://github.com/thejens/gclouder/releases/tag/v0.0.1 