import Foundation

struct GCloudHelper {
    
    // Cached gcloud path
    private static var cachedGCloudPath: String?
    
    // UserDefaults key for manual gcloud path
    private static let manualGCloudPathKey = "ManualGCloudPath"
    
    /// Initialize gcloud path finding - call this once at app startup
    static func initialize() {
        print("🔍 GCloudHelper: Initializing...")
        _ = getGCloudPath()
    }
    
    /// Get the manual gcloud path from settings
    static func getManualGCloudPath() -> String? {
        return UserDefaults.standard.string(forKey: manualGCloudPathKey)
    }
    
    /// Set the manual gcloud path in settings
    static func setManualGCloudPath(_ path: String?) {
        if let path = path, !path.isEmpty {
            UserDefaults.standard.set(path, forKey: manualGCloudPathKey)
        } else {
            UserDefaults.standard.removeObject(forKey: manualGCloudPathKey)
        }
        
        // Clear cache to force re-detection
        cachedGCloudPath = nil
        
        print("🔍 GCloudHelper: Manual gcloud path updated: \(path ?? "cleared")")
    }
    
    /// Get the current gcloud path (cached)
    static func getGCloudPath() -> String? {
        if let cached = cachedGCloudPath {
            return cached
        }
        
        // Check for manual override first
        if let manualPath = getManualGCloudPath() {
            print("🔍 GCloudHelper: Using manual gcloud path: \(manualPath)")
            if FileManager.default.isExecutableFile(atPath: manualPath) {
                cachedGCloudPath = manualPath
                return manualPath
            } else {
                print("⚠️ GCloudHelper: Manual path is not executable, falling back to auto-detection")
            }
        }
        
        // Auto-detect gcloud path
        cachedGCloudPath = findGCloudPath()
        return cachedGCloudPath
    }
    
    /// Get a human-readable description of where gcloud was found
    static func getGCloudPathDescription() -> String {
        if let manualPath = getManualGCloudPath() {
            if FileManager.default.isExecutableFile(atPath: manualPath) {
                return "Manual: \(manualPath)"
            } else {
                return "Manual (invalid): \(manualPath)"
            }
        }
        
        if let path = getGCloudPath() {
            return "Auto-detected: \(path)"
        }
        
        return "Not found"
    }
    
    /// Find the gcloud executable path (internal method)
    private static func findGCloudPath() -> String? {
        print("🔍 GCloudHelper: Looking for gcloud executable...")
        
        // Common gcloud installation paths
        let commonPaths = [
            // Google Cloud SDK default installation
            "\(NSHomeDirectory())/.google-cloud-sdk/bin/gcloud",
            "/usr/local/bin/gcloud",
            "/opt/homebrew/bin/gcloud",
            "/usr/local/google-cloud-sdk/bin/gcloud",
            // Homebrew paths
            "/opt/homebrew/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/bin/gcloud",
            "/usr/local/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/bin/gcloud"
        ]
        
        // Check each path
        for path in commonPaths {
            if FileManager.default.isExecutableFile(atPath: path) {
                print("✅ GCloudHelper: Found gcloud at: \(path)")
                return path
            }
        }
        
        // Try to find via shell environment
        print("🔍 GCloudHelper: Trying to find gcloud via shell...")
        if let shellPath = findGCloudViaShell() {
            print("✅ GCloudHelper: Found gcloud via shell: \(shellPath)")
            return shellPath
        }
        
        print("❌ GCloudHelper: Could not find gcloud executable")
        return nil
    }
    
    /// Try to find gcloud using shell environment
    private static func findGCloudViaShell() -> String? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        process.arguments = ["-l", "-c", "which gcloud 2>/dev/null"]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        
        do {
            try process.run()
            process.waitUntilExit()
            
            if process.terminationStatus == 0 {
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
                
                if let path = output, !path.isEmpty {
                    return path
                }
            }
        } catch {
            print("❌ GCloudHelper: Error finding gcloud via shell: \(error)")
        }
        
        return nil
    }
    
    /// Get the currently authenticated Google Cloud account
    static func getCurrentAccount() async -> String? {
        print("🔍 GCloudHelper: Getting current account...")
        
        let result = await executeGCloudCommand("config get-value account")
        
        if result.success {
            let account = result.output.trimmingCharacters(in: .whitespacesAndNewlines)
            if !account.isEmpty && account != "(unset)" {
                print("🔍 GCloudHelper: Current account: \(account)")
                return account
            }
        }
        
        print("🔍 GCloudHelper: No account configured")
        return nil
    }
    
    /// Execute a gcloud command with proper environment
    static func executeGCloudCommand(_ command: String) async -> (success: Bool, output: String, exitCode: Int32) {
        guard let gcloudPath = getGCloudPath() else {
            return (false, "gcloud executable not found", -1)
        }
        
        print("🔍 GCloudHelper: Executing gcloud command: \(command)")
        print("🔍 GCloudHelper: Using gcloud at: \(gcloudPath)")
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        
        // Load user's zsh environment and execute the command
        let fullCommand = """
        source ~/.zshrc 2>/dev/null || true
        export PATH="\(gcloudPath.replacingOccurrences(of: "/gcloud", with: "")):$PATH"
        \(gcloudPath) \(command)
        """
        
        process.arguments = ["-l", "-c", fullCommand]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        
        do {
            try process.run()
            process.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""
            
            print("🔍 GCloudHelper: Command completed with exit code: \(process.terminationStatus)")
            print("🔍 GCloudHelper: Output length: \(output.count) characters")
            
            return (process.terminationStatus == 0, output, process.terminationStatus)
        } catch {
            print("❌ GCloudHelper: Error executing gcloud command: \(error)")
            return (false, "Error executing command: \(error.localizedDescription)", -1)
        }
    }
} 