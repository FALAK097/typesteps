import SwiftUI
import UserNotifications
import ServiceManagement

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.checkAndStartTracking()
        }
    }
    
    private func checkAndStartTracking() {
        let hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "has_completed_onboarding")
        
        if hasCompletedOnboarding {
            // Only start tracking if onboarding was already done and permission granted
            if KeystrokeListener.shared.checkPermissionsSilently() {
                KeystrokeListener.shared.startListening()
            }
        } else {
            // If onboarding not done, trigger the onboarding flow
            NotificationCenter.default.post(name: .showOnboarding, object: nil)
        }
    }
}

extension Notification.Name {
    static let showOnboarding = Notification.Name("showOnboarding")
    static let onboardingCompleted = Notification.Name("onboardingCompleted")
    static let accessibilityGranted = Notification.Name("accessibilityGranted")
}

@main
struct TypeStepsApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var storage = StorageManager.shared
    @StateObject private var listener = KeystrokeListener.shared
    @State private var showOnboarding = false
    @State private var loginItemEnabled = false
    @State private var hasInitialized = false
    
    @AppStorage("app_theme") private var appTheme = 0
    @Environment(\.openWindow) var openWindow
    
    init() {
        // We will handle onboarding checking dynamically via AppDelegate
        // to prevent UI layout initialization issues before the window is fully ready.
    }
    
    var body: some Scene {
        MenuBarExtra {
            Text("Today: \(storage.getCount())")
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
            
            Toggle("Open at Login", isOn: $loginItemEnabled)
                .onChange(of: loginItemEnabled) { _, newValue in
                    updateLoginItem(enabled: newValue)
                }
            
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
            .onReceive(NotificationCenter.default.publisher(for: .showOnboarding)) { _ in
                showOnboarding = true
                openWindow(id: "dashboard")
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    NSApp.activate(ignoringOtherApps: true)
                }
            }
        }
        .onChange(of: showOnboarding) { _, newValue in
            if newValue {
                // Open dashboard window with onboarding overlay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    openWindow(id: "dashboard")
                }
            } else {
                // Sync login state when onboarding closes
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    syncLoginItemState()
                }
            }
        }
        
        Window("TypeSteps", id: "dashboard") {
            ZStack {
                DashboardView()
                    .preferredColorScheme(appTheme == 0 ? nil : (appTheme == 1 ? .light : .dark))
                
                // Show onboarding overlay on top of dashboard
                if showOnboarding {
                    Color.black
                        .opacity(0.4)
                        .ignoresSafeArea()
                    
                    VStack {
                        WelcomeView(showOnboarding: $showOnboarding)
                            .frame(width: 440, height: 500)
                            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                            .shadow(color: Color.black.opacity(0.15), radius: 24, y: 12)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .onboardingCompleted)) { _ in
                if KeystrokeListener.shared.checkPermissionsSilently() {
                    KeystrokeListener.shared.startListening()
                }
            }
            .onAppear {
                // Open window immediately if onboarding needs to be shown
                if !hasInitialized && showOnboarding {
                    hasInitialized = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        NSApp.activate(ignoringOtherApps: true)
                    }
                }
            }
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
    
    private func syncLoginItemState() {
        loginItemEnabled = SMAppService.mainApp.status == .enabled
    }
    
    private func updateLoginItem(enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            print("Failed to toggle login item: \(error)")
            // Revert the toggle if it fails
            loginItemEnabled = !enabled
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
