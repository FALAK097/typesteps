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
        let projectName = getProjectName(for: appName)
        
        guard let characters = event.charactersIgnoringModifiers else { return }
        for char in characters {
            if char.isLetter || char.isNumber {
                DispatchQueue.main.async {
                    StorageManager.shared.incrementCount(appName: appName, bundleId: bundleId, projectName: projectName)
                }
            }
        }
    }
    
    private func getProjectName(for appName: String) -> String? {
        let systemWideElement = AXUIElementCreateSystemWide()
        var focusedElement: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(systemWideElement, kAXFocusedApplicationAttribute as CFString, &focusedElement)
        
        guard result == .success, let focusedElement = focusedElement as! AXUIElement? else { return nil }
        
        var windowTitle: CFTypeRef?
        AXUIElementCopyAttributeValue(focusedElement, kAXTitleAttribute as CFString, &windowTitle)
        
        guard let title = windowTitle as? String else { return nil }
        
        // Strategy: Extract based on app
        if appName == "Xcode" {
            // Xcode titles often look like "ProjectName — FileName.swift"
            let components = title.components(separatedBy: " — ")
            return components.first
        } else if appName == "Visual Studio Code" || appName == "Cursor" {
            // VS Code usually "FileName - ProjectName"
            let components = title.components(separatedBy: " - ")
            if components.count >= 2 {
                return components[components.count - 2]
            }
        }
        
        return nil
    }
}
