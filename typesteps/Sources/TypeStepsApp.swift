import SwiftUI
import UserNotifications

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        KeystrokeListener.shared.startListening()
        
        // This keeps the app running as a background utility (no Dock icon)
        NSApp.setActivationPolicy(.accessory)
        
        // Request notification permissions
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }
}

@main
struct TypeStepsApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var storage = StorageManager.shared
    @StateObject private var listener = KeystrokeListener.shared
    
    @AppStorage("app_theme") private var appTheme = 0
    @Environment(\.openWindow) var openWindow
    
    var body: some Scene {
        MenuBarExtra {
            Text("Today: \(storage.getCount())")
            if storage.isInFlow() {
                Text("FLOW STATE 🔥").foregroundStyle(.orange)
            }
            Text("This Week: \(storage.getWeeklyTotal())")
            Text("This Month: \(storage.getMonthlyTotal())")
            
            Divider()
            
            Button(listener.isPaused ? "Resume Tracking" : "Pause Tracking") {
                listener.isPaused.toggle()
            }
            .keyboardShortcut("p", modifiers: [.command, .shift])
            
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
                Image(systemName: listener.isPaused ? "keyboard.badge.ellipsis" : "keyboard")
                Text("\(storage.getCount())")
            }
        }
        
        Window("TypeSteps", id: "dashboard") {
            DashboardView()
                .preferredColorScheme(appTheme == 0 ? nil : (appTheme == 1 ? .light : .dark))
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 1200, height: 850)
        
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button("About TypeSteps") {
                    showCustomAbout()
                }
            }
        }
    }
    
    private func showCustomAbout() {
        let alert = NSAlert()
        alert.messageText = "About TypeSteps"
        alert.informativeText = """
        A minimalist macOS app that passively tracks your daily typing activity and shows insights across days, weeks, and months.
        
        Version 1.2.0
        Built by falakgala.dev
        """
        alert.addButton(withTitle: "Visit Website")
        alert.addButton(withTitle: "OK")
        if alert.runModal() == .alertFirstButtonReturn {
            if let url = URL(string: "https://falakgala.dev") {
                NSWorkspace.shared.open(url)
            }
        }
    }
}
