import SwiftUI
import Combine
import ApplicationServices

class KeystrokeListener: ObservableObject {
    static let shared = KeystrokeListener()
    
    @Published var isAuthorized: Bool = false
    private var eventMonitor: Any?
    
    init() {
        // Don't check permissions during init to avoid blocking the main thread
    }
    
    func checkPermissions() {
        // Check if the app has accessibility permissions
        // kAXTrustedCheckOptionPrompt: true will show the system dialog if missing
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        let trusted = AXIsProcessTrustedWithOptions(options as CFDictionary)
        
        DispatchQueue.main.async {
            self.isAuthorized = trusted
        }
    }
    
    func startListening() {
        guard eventMonitor == nil else { return }
        
        // Monitor system-wide key down events
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
        // We only care about characters (A-Z, 0-9)
        // Privacy focus: we NEVER store the characters, just increment a counter
        guard let characters = event.charactersIgnoringModifiers else { return }
        
        for char in characters {
            if char.isLetter || char.isNumber {
                DispatchQueue.main.async {
                    StorageManager.shared.incrementCount()
                }
            }
        }
    }
}
