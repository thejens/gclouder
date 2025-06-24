import Cocoa
import LaunchAtLogin

class StatusBarController: NSObject {
    private var statusItem: NSStatusItem?
    private var menu: NSMenu!
    private var authChecker: AuthenticationChecker?
    private var timer: Timer?
    
    override init() {
        super.init()
        createMenu()
        setupStatusBar()
        setupAuthenticationChecker()
    }
    
    deinit {
        timer?.invalidate()
    }
    
    private func setupStatusBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem?.menu = menu
        
        // Start with a neutral state until we check authentication
        setInitialIcon()
    }
    
    private func setInitialIcon() {
        print("🔘 StatusBarController: Setting initial (checking) icon")
        DispatchQueue.main.async { [weak self] in
            guard let button = self?.statusItem?.button else { return }
            
            // Use a neutral icon while checking
            button.image = NSImage(systemSymbolName: "cloud", accessibilityDescription: "GClouder - Checking...")
            button.image?.size = NSSize(width: 18, height: 18)
            button.image?.isTemplate = true
        }
    }
    
    private func setupAuthenticationChecker() {
        authChecker = AuthenticationChecker()
        authChecker?.delegate = self
        
        // Start checking immediately
        authChecker?.checkAuthentication()
        
        // Setup timer to check every minute
        timer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { [weak self] _ in
            self?.authChecker?.checkAuthentication()
        }
    }
    
    private func createMenu() {
        menu = NSMenu()
        
        // Authentication status - dynamic item
        let statusItem = NSMenuItem(title: "Checking authentication...", action: nil, keyEquivalent: "")
        statusItem.tag = 100 // Tag to identify this item for updates
        menu.addItem(statusItem)
        
        // Account information - dynamic item
        let accountItem = NSMenuItem(title: "Account: Loading...", action: nil, keyEquivalent: "")
        accountItem.tag = 101 // Tag to identify this item for updates
        menu.addItem(accountItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Authenticate action
        let authenticateItem = NSMenuItem(title: "Authenticate GCloud", action: #selector(authenticateAction), keyEquivalent: "")
        authenticateItem.target = self
        menu.addItem(authenticateItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Debug submenu
        let debugItem = NSMenuItem(title: "Debug", action: nil, keyEquivalent: "")
        let debugSubmenu = NSMenu()
        
        // Show gcloud path
        let gcloudPathItem = NSMenuItem(title: GCloudHelper.getGCloudPathDescription(), action: nil, keyEquivalent: "")
        gcloudPathItem.tag = 200 // Tag to update this item
        debugSubmenu.addItem(gcloudPathItem)
        
        debugSubmenu.addItem(NSMenuItem.separator())
        
        // Configure gcloud path
        let configurePathItem = NSMenuItem(title: "Configure gcloud Path...", action: #selector(configureGCloudPath), keyEquivalent: "")
        configurePathItem.target = self
        debugSubmenu.addItem(configurePathItem)
        
        debugItem.submenu = debugSubmenu
        menu.addItem(debugItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Launch at startup toggle
        let launchItem = NSMenuItem(title: "Launch at Startup", action: #selector(toggleLaunchAtStartup), keyEquivalent: "")
        launchItem.target = self
        launchItem.tag = 300 // Tag to update this item
        launchItem.state = LaunchAtLogin.isEnabled ? .on : .off
        menu.addItem(launchItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Quit
        let quitItem = NSMenuItem(title: "Quit", action: #selector(quitAction), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
    }
    
    func updateIcon(isAuthenticated: Bool) {
        print("🔘 StatusBarController: updateIcon called with isAuthenticated: \(isAuthenticated)")
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            let iconName: String
            let statusText: String
            
            if isAuthenticated {
                iconName = "cloud.fill"
                statusText = "✅ Authenticated"
            } else {
                iconName = "exclamationmark.triangle.fill"
                statusText = "❌ Not authenticated"
            }
            
            // Update status bar icon
            if let image = NSImage(systemSymbolName: iconName, accessibilityDescription: nil) {
                image.size = NSSize(width: 18, height: 18)
                image.isTemplate = true
                self.statusItem?.button?.image = image
            }
            
            // Update menu status item
            if let statusMenuItem = self.menu.item(withTag: 100) {
                statusMenuItem.title = statusText
            }
            
            // Update account information
            self.updateAccountInfo(isAuthenticated: isAuthenticated)
            
            // Update gcloud path in debug menu
            if let debugItem = self.menu.items.first(where: { $0.title == "Debug" }),
               let debugSubmenu = debugItem.submenu,
               let pathItem = debugSubmenu.item(withTag: 200) {
                pathItem.title = GCloudHelper.getGCloudPathDescription()
            }
        }
    }
    
    private func updateAccountInfo(isAuthenticated: Bool) {
        Task {
            let accountText: String
            
            if isAuthenticated {
                if let account = await GCloudHelper.getCurrentAccount() {
                    accountText = "Account: \(account)"
                } else {
                    accountText = "Account: Unknown"
                }
            } else {
                accountText = "Account: Not authenticated"
            }
            
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                
                // Update account menu item
                if let accountMenuItem = self.menu.item(withTag: 101) {
                    accountMenuItem.title = accountText
                }
            }
        }
    }
    

    
    @objc private func authenticateAction() {
        print("🔐 StatusBarController: Authenticate action triggered")
        Task {
            await GCloudAuthenticator.authenticate()
        }
    }
    
    @objc private func configureGCloudPath() {
        print("🔧 StatusBarController: Configure gcloud path triggered")
        
        let alert = NSAlert()
        alert.messageText = "Configure gcloud Path"
        alert.informativeText = "Enter the full path to your gcloud executable:"
        alert.alertStyle = .informational
        
        let textField = NSTextField(frame: NSRect(x: 0, y: 0, width: 300, height: 24))
        textField.stringValue = GCloudHelper.getManualGCloudPath() ?? ""
        textField.placeholderString = "e.g., /usr/local/bin/gcloud"
        alert.accessoryView = textField
        
        alert.addButton(withTitle: "Save")
        alert.addButton(withTitle: "Auto-detect")
        alert.addButton(withTitle: "Cancel")
        
        let response = alert.runModal()
        
        switch response {
        case .alertFirstButtonReturn: // Save
            let path = textField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
            GCloudHelper.setManualGCloudPath(path.isEmpty ? nil : path)
            updateDebugMenu() // Update debug menu
            
        case .alertSecondButtonReturn: // Auto-detect
            GCloudHelper.setManualGCloudPath(nil)
            updateDebugMenu() // Update debug menu
            
        default: // Cancel
            break
        }
    }
    
    private func updateDebugMenu() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // Update gcloud path in debug menu
            if let debugItem = self.menu.items.first(where: { $0.title == "Debug" }),
               let debugSubmenu = debugItem.submenu,
               let pathItem = debugSubmenu.item(withTag: 200) {
                pathItem.title = GCloudHelper.getGCloudPathDescription()
            }
        }
    }
    
    @objc private func toggleLaunchAtStartup() {
        print("🚀 StatusBarController: Toggle launch at startup triggered")
        LaunchAtLogin.isEnabled.toggle()
        updateLaunchAtStartupMenuItem()
    }
    
    private func updateLaunchAtStartupMenuItem() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // Update launch at startup menu item
            if let launchMenuItem = self.menu.item(withTag: 300) {
                launchMenuItem.state = LaunchAtLogin.isEnabled ? .on : .off
            }
        }
    }
    
    @objc private func quitAction() {
        print("👋 StatusBarController: Quit action triggered")
        NSApplication.shared.terminate(nil)
    }
    
    // Public method for external calls (e.g., from notifications)
    func performAuthentication() {
        print("🔘 StatusBarController: performAuthentication() called")
        Task {
            await GCloudAuthenticator.authenticate()
            // Force an immediate check after authentication attempt
            try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
            authChecker?.checkAuthentication()
        }
    }
}

extension StatusBarController: AuthenticationCheckerDelegate {
    func authenticationStatusChanged(isAuthenticated: Bool) {
        updateIcon(isAuthenticated: isAuthenticated)
    }
} 