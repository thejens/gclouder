# GClouder

[![Test](https://github.com/thejens/gclouder/actions/workflows/test.yml/badge.svg)](https://github.com/thejens/gclouder/actions/workflows/test.yml)
[![Release](https://github.com/thejens/gclouder/actions/workflows/release.yml/badge.svg)](https://github.com/thejens/gclouder/actions/workflows/release.yml)

A lightweight macOS menu bar utility for managing Google Cloud authentication status.

![GClouder Icon](AppIcons/appstore.png)

<img width="300" alt="GClouder Screenshot" src="https://via.placeholder.com/300x200?text=GClouder+Menu+Bar">

## Features

- 🔐 **Authentication Monitoring**: Automatically checks your Google Cloud authentication status every minute
- 🚨 **Visual Status Indicator**: Shows a red warning icon when not authenticated, normal cloud icon when authenticated
- 🔔 **Smart Notifications**: Get notified when your authentication expires (only once, not every minute!)
- 👆 **Clickable Notifications**: Click the notification to immediately re-authenticate
- 🔄 **Quick Authentication**: One-click authentication with Google Cloud from the menu bar
- 🚀 **Launch at Login**: Option to automatically start GClouder when you log in to your Mac
- 🎯 **Minimal and Efficient**: Runs quietly in your menu bar without cluttering your dock

## Requirements

- macOS 13.0 (Ventura) or later
- Google Cloud SDK (`gcloud`) installed and configured
- Swift 5.9 or later (for building from source)

## Installation

### Option 1: Download Pre-built Release

1. Download the latest release from the [Releases](https://github.com/thejens/gclouder/releases) page
2. Unzip the downloaded file
3. Drag `GClouder.app` to your Applications folder
4. Launch GClouder from your Applications folder

### Option 2: Build from Source

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/gclouder.git
   cd gclouder
   ```

2. Build and install using make:
   ```bash
   make install
   ```

   This will build the app and install it to `/Applications`

3. Launch GClouder from your Applications folder

## Usage

Once launched, GClouder will appear in your menu bar:

- **Cloud Icon**: You're authenticated with Google Cloud
- **Red Warning Icon**: You're not authenticated

Click the icon to access the menu:
- **Authenticate GCloud**: Opens browser for Google Cloud authentication
- **Launch at Login**: Toggle whether GClouder starts automatically
- **Quit**: Exit the application

### Notifications

GClouder will send a notification when your authentication expires. The notification:
- Only appears when your auth status changes (not every check)
- Is clickable - clicking it will start the authentication process
- Requires notification permissions (you'll be prompted on first launch)

## Building

### Available Make Commands

- `make` or `make build` - Build the application in release mode
- `make dev` - Build the application in debug mode
- `make test` - Run tests (falls back to build verification if XCTest unavailable)
- `make test-auth` - Test the authentication flow interactively
- `make run` - Build and run the debug version
- `make install` - Build and install to /Applications
- `make uninstall` - Remove from /Applications
- `make clean` - Clean build artifacts
- `make release` - Create a distributable .zip file

## How It Works

GClouder periodically checks your Google Cloud authentication status by attempting to retrieve an access token using:
```bash
gcloud auth application-default print-access-token
```

When you click "Authenticate GCloud", it runs:
```bash
gcloud auth login --enable-gdrive-access --update-adc
```

This opens your default browser for authentication and updates your Application Default Credentials.

## Troubleshooting

### Authentication Issues

#### "Authentication Failed" message
This can happen for several reasons:
1. **Browser closed too quickly**: Make sure to complete the authentication flow in your browser
2. **Popup blockers**: Ensure your browser allows popups from accounts.google.com
3. **gcloud SDK issues**: Try running `gcloud auth login` manually in Terminal to test

#### Debugging Authentication Issues
Use the built-in debug command to test authentication:
```bash
make test-auth
```
This will:
- Check if gcloud is installed and accessible
- Show current authentication status
- Run the app's authentication flow with detailed logging
- Verify final authentication status

#### GClouder shows not authenticated even after logging in
- The app checks authentication status every minute - wait a moment for it to update
- Click the menu bar icon to force an immediate check
- Make sure you have the latest version of Google Cloud SDK
- Try running `gcloud auth application-default login` manually in Terminal
- Check that your credentials haven't expired

### The app doesn't appear in the menu bar
- Check that you've granted necessary permissions in System Preferences > Security & Privacy
- Look for notification permissions - the app needs these to alert you
- Try launching the app again from your Applications folder

## Development

### Project Structure
```
gclouder/
├── Sources/
│   └── Gclouder/
│       ├── main.swift
│       ├── AppDelegate.swift
│       ├── StatusBarController.swift
│       ├── AuthenticationChecker.swift
│       ├── GCloudAuthenticator.swift
│       └── Resources/
│           └── Info.plist
├── Tests/
│   └── GclouderTests/
├── Package.swift
├── Makefile
└── README.md
```

### Running Tests
```bash
make test
```

> **Note**: Full test execution requires Xcode with XCTest framework. If XCTest is not available, the command will verify that the code compiles successfully.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

### Development Workflow

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Automated Testing

- Tests run automatically on all PRs and pushes to main
- Ensure all tests pass before submitting PR

### Creating a Release

1. Update version in `Resources/Info.plist` (CFBundleShortVersionString)
2. Commit the version change
3. Create and push a tag:
   ```bash
   git tag -a v1.0.1 -m "Release version 1.0.1"
   git push origin v1.0.1
   ```
4. GitHub Actions will automatically build and create a release

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Uses [LaunchAtLogin](https://github.com/sindresorhus/LaunchAtLogin) for startup functionality
- Built with Swift and SwiftUI for macOS 