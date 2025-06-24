import Cocoa
import UserNotifications

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusBarController: StatusBarController?
    private var isRunningFromBundle: Bool {
        return Bundle.main.bundlePath.hasSuffix(".app")
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        print("🚀 AppDelegate: Application starting...")
        print("🚀 AppDelegate: Running from bundle: \(isRunningFromBundle)")
        
        // Initialize gcloud path detection once at startup
        GCloudHelper.initialize()
        
        // Request notification permissions if running from app bundle
        if isRunningFromBundle {
            requestNotificationPermissions()
        } else {
            print("⚠️ AppDelegate: Running from debug build - notifications disabled to prevent crashes")
        }
        
        // Create status bar controller
        statusBarController = StatusBarController()
        
        print("✅ AppDelegate: Application startup complete")
    }
    
    private func requestNotificationPermissions() {
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("❌ AppDelegate: Notification permission error: \(error)")
            } else {
                print("📱 AppDelegate: Notification permissions: \(granted ? "granted" : "denied")")
            }
        }
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        print("👋 AppDelegate: Application terminating...")
    }
    
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        // Don't show any windows when the app is reopened
        return false
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    // Handle notification while app is in foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter, 
                              willPresent notification: UNNotification, 
                              withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Show notification even when app is active
        completionHandler([.banner, .sound])
    }
    
    // Handle notification click
    func userNotificationCenter(_ center: UNUserNotificationCenter, 
                              didReceive response: UNNotificationResponse, 
                              withCompletionHandler completionHandler: @escaping () -> Void) {
        if response.notification.request.identifier == "auth-expired" {
            // Trigger authentication when notification is clicked
            statusBarController?.performAuthentication()
        }
        completionHandler()
    }
} 