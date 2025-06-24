import Foundation
import Cocoa
import UserNotifications

struct GCloudAuthenticator {
    // Flag to determine if we're in test mode (skip notifications)
    static var isTestMode: Bool = false
    
    // Check if we're running from a proper app bundle
    private static var isRunningFromAppBundle: Bool {
        return Bundle.main.bundlePath.hasSuffix(".app")
    }
    
    // Check if notifications should be used
    private static var shouldUseNotifications: Bool {
        return !isTestMode && isRunningFromAppBundle
    }
    
    static func authenticate() async {
        print("🔐 GCloudAuthenticator: Starting authentication process")
        
        // Send notification that auth is starting (skip in test mode or debug builds)
        if shouldUseNotifications {
            await sendAuthStartNotification()
        } else {
            print("📱 [DEBUG/TEST MODE] Would send auth start notification")
        }
        
        // Run gcloud auth login - it will handle browser opening and OAuth flow
        await withCheckedContinuation { continuation in
            Task {
                print("🔐 GCloudAuthenticator: Running gcloud auth command")
                
                let result = await GCloudHelper.executeGCloudCommand("auth login --enable-gdrive-access --update-adc")
                
                print("🔐 GCloudAuthenticator: Process completed with status: \(result.exitCode)")
                print("🔐 GCloudAuthenticator: Output: \(result.output)")
                
                if result.success {
                    print("✅ GCloud authentication completed successfully")
                    if shouldUseNotifications {
                        await sendAuthSuccessNotification()
                    } else {
                        print("📱 [DEBUG/TEST MODE] Would send auth success notification")
                    }
                } else {
                    print("❌ GCloud authentication ended with status: \(result.exitCode)")
                    
                    // Check if user cancelled
                    if result.output.contains("cancelled") || result.output.contains("aborted") || result.output.contains("closed") {
                        print("ℹ️ User cancelled authentication")
                    } else {
                        print("❌ Authentication failed with output: \(result.output)")
                        if shouldUseNotifications {
                            await sendAuthFailedNotification(details: result.output)
                        } else {
                            print("📱 [DEBUG/TEST MODE] Would send auth failed notification")
                        }
                    }
                }
                
                print("🔐 GCloudAuthenticator: Resuming continuation")
                continuation.resume()
            }
        }
        
        print("🔐 GCloudAuthenticator: Authentication process completed")
    }
    
    @MainActor
    private static func sendAuthStartNotification() async {
        print("📱 Sending auth start notification")
        let content = UNMutableNotificationContent()
        content.title = "GClouder"
        content.body = "Opening browser for Google Cloud authentication..."
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: "auth-start",
            content: content,
            trigger: nil
        )
        
        do {
            try await UNUserNotificationCenter.current().add(request)
            print("📱 Auth start notification sent")
        } catch {
            print("❌ Failed to send auth start notification: \(error)")
        }
    }
    
    @MainActor
    private static func sendAuthSuccessNotification() async {
        print("📱 Sending auth success notification")
        let content = UNMutableNotificationContent()
        content.title = "Authentication Successful"
        content.body = "You are now authenticated with Google Cloud."
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: "auth-success",
            content: content,
            trigger: nil
        )
        
        do {
            try await UNUserNotificationCenter.current().add(request)
            print("📱 Auth success notification sent")
        } catch {
            print("❌ Failed to send auth success notification: \(error)")
        }
    }
    
    @MainActor
    private static func sendAuthFailedNotification(details: String) async {
        print("📱 Sending auth failed notification")
        let content = UNMutableNotificationContent()
        content.title = "Authentication Failed"
        content.body = "Please try authenticating again from the menu."
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: "auth-failed",
            content: content,
            trigger: nil
        )
        
        do {
            try await UNUserNotificationCenter.current().add(request)
            print("📱 Auth failed notification sent")
        } catch {
            print("❌ Failed to send auth failed notification: \(error)")
        }
    }
} 