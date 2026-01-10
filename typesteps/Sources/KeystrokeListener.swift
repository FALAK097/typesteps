import SwiftUI
import Combine
import ApplicationServices

class KeystrokeListener: ObservableObject {
    static let shared = KeystrokeListener()
    
    @Published var isAuthorized: Bool = false
    @Published var isPaused: Bool = false
    private var eventMonitor: Any?
    
    init() {}
    
    func checkPermissions() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        let trusted = AXIsProcessTrustedWithOptions(options as CFDictionary)
        DispatchQueue.main.async {
            self.isAuthorized = trusted
        }
    }
    
    func startListening() {
        guard eventMonitor == nil else { return }
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { event in
            self.handle(event: event)
        }
    }
    
    func stopListening() {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
    }
    
    private func handle(event: NSEvent) {
        // Respect the pause state
        guard !isPaused else { return }
        
        let frontmost = NSWorkspace.shared.frontmostApplication
        let appName = frontmost?.localizedName ?? "Unknown"
        let bundleId = frontmost?.bundleIdentifier
        
        guard let characters = event.charactersIgnoringModifiers else { return }
        for char in characters {
            if char.isLetter || char.isNumber {
                DispatchQueue.main.async {
                    StorageManager.shared.incrementCount(appName: appName, bundleId: bundleId)
                }
            }
        }
    }
}
