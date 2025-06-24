import Foundation
import UserNotifications

@MainActor
protocol AuthenticationCheckerDelegate: AnyObject {
    func authenticationStatusChanged(isAuthenticated: Bool)
}

class AuthenticationChecker {
    weak var delegate: AuthenticationCheckerDelegate?
    private var lastAuthStatus: Bool?
    
    // Check if we're running from a proper app bundle
    private var isRunningFromAppBundle: Bool {
        return Bundle.main.bundlePath.hasSuffix(".app")
    }
    
    func checkAuthentication() {
        print("🔍 AuthenticationChecker: Starting authentication check")
        Task {
            let isAuthenticated = await checkGCloudAuth()
            print("🔍 AuthenticationChecker: Auth check result: \(isAuthenticated)")
            
            // Check if auth status changed
            if lastAuthStatus != isAuthenticated {
                let previousStatus = lastAuthStatus
                lastAuthStatus = isAuthenticated
                
                print("🔍 AuthenticationChecker: Status changed from \(previousStatus?.description ?? "nil") to \(isAuthenticated)")
                
                await delegate?.authenticationStatusChanged(isAuthenticated: isAuthenticated)
                
                // Send notification only when auth expires (true -> false) and we're in app bundle
                if previousStatus == true && isAuthenticated == false && isRunningFromAppBundle {
                    await sendAuthExpiredNotification()
                } else if previousStatus == true && isAuthenticated == false {
                    print("📱 [DEBUG MODE] Would send auth expired notification")
                }
            } else {
                print("🔍 AuthenticationChecker: Status unchanged: \(isAuthenticated)")
            }
        }
    }
    
    private func checkGCloudAuth() async -> Bool {
        print("🔍 AuthenticationChecker: Running gcloud auth check...")
        
        let result = await GCloudHelper.executeGCloudCommand("auth application-default print-access-token")
        
        print("🔍 AuthenticationChecker: gcloud exit status: \(result.exitCode)")
        print("🔍 AuthenticationChecker: gcloud output length: \(result.output.count) chars")
        
        // If we can successfully get an access token, we're authenticated
        let isAuthenticated = result.success && !result.output.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        print("🔍 AuthenticationChecker: Final auth result: \(isAuthenticated)")
        return isAuthenticated
    }
    
    @MainActor
    private func sendAuthExpiredNotification() async {
        print("📱 AuthenticationChecker: Sending auth expired notification")
        let content = UNMutableNotificationContent()
        content.title = "GClouder Authentication Expired"
        content.body = "Your Google Cloud authentication has expired. Click to re-authenticate."
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: "auth-expired",
            content: content,
            trigger: nil // Show immediately
        )
        
        do {
            try await UNUserNotificationCenter.current().add(request)
            print("📱 AuthenticationChecker: Auth expired notification sent")
        } catch {
            print("❌ AuthenticationChecker: Error sending notification: \(error)")
        }
    }
} 