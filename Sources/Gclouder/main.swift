import Cocoa

// Check for command line arguments
let arguments = CommandLine.arguments

if arguments.contains("--test-auth") {
    print("🧪 Testing authentication flow...")
    
    // Enable test mode to skip notifications
    GCloudAuthenticator.isTestMode = true
    
    // Create a simple run loop for testing
    Task {
        await GCloudAuthenticator.authenticate()
        print("🧪 Authentication test completed, exiting...")
        exit(0)
    }
    
    // Keep the app running until authentication completes
    RunLoop.main.run()
} else {
    // Normal app execution
    let app = NSApplication.shared
    let delegate = AppDelegate()
    app.delegate = delegate
    app.setActivationPolicy(.accessory) // Hide from dock, only show in menu bar
    app.run()
} 