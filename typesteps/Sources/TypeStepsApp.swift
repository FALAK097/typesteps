import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        KeystrokeListener.shared.startListening()
        // Ensure the app icon is visible in Mission Control/App Switcher
        NSApp.setActivationPolicy(.regular)
    }
}

@main
struct TypeStepsApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var storage = StorageManager.shared
    @AppStorage("app_theme") private var appTheme = 0
    @Environment(\.openWindow) var openWindow
    
    var body: some Scene {
        MenuBarExtra {
            Text("Today: \(storage.getCount())")
            
            Divider()
            
            Button("Open Dashboard") {
                NSApp.activate(ignoringOtherApps: true)
                openWindow(id: "dashboard")
            }
            .keyboardShortcut("d")
            
            Divider()
            
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q")
        } label: {
            HStack {
                Image(systemName: "keyboard")
                Text("\(storage.getCount())")
            }
        }
        
        Window("TypeSteps", id: "dashboard") {
            DashboardView()
                .preferredColorScheme(appTheme == 0 ? nil : (appTheme == 1 ? .light : .dark))
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 400, height: 600)
        
        // Customizing the Menu Bar Menu
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button("About TypeSteps") {
                    showCustomAbout()
                }
            }
            CommandGroup(replacing: .appSettings) {
                // Settings removed as requested
            }
        }
    }
    
    private func showCustomAbout() {
        let alert = NSAlert()
        alert.messageText = "About TypeSteps"
        alert.informativeText = """
        Version 1.0.0
        
        A minimal keyboard activity tracker for macOS.
        Built with ❤️ by falakgala.dev
        
        Performance: <1% CPU Usage
        Size: ~5MB
        """
        alert.addButton(withTitle: "Visit Website")
        alert.addButton(withTitle: "OK")
        
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            if let url = URL(string: "https://falakgala.dev") {
                NSWorkspace.shared.open(url)
            }
        }
    }
}
