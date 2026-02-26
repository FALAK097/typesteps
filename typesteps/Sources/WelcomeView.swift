import SwiftUI
import ServiceManagement
import ApplicationServices

struct WelcomeView: View {
    @Binding var showOnboarding: Bool
    @State private var currentStep: Int = 0
    @State private var isCheckingPermission = false
    @State private var permissionGranted = false
    @State private var loginItemEnabled = false
    @State private var permissionCheckTimer: Timer?
    @State private var showLoginItemError = false
    @AppStorage("app_theme_id") private var appThemeId = 0
    
    private var theme: AppTheme { AppTheme.themes.first { $0.id == appThemeId } ?? AppTheme.themes[0] }
    
    var body: some View {
        VStack(spacing: 0) {
            headerView
            
            Spacer()
            
            contentView
                .onChange(of: currentStep) { _, newValue in
                    if newValue == 1 {
                        loginItemEnabled = SMAppService.mainApp.status == .enabled
                    }
                }
            
            Spacer()
            
            bottomView
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(theme.mainBg)
        .foregroundColor(theme.text)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .onAppear {
            print("[DEBUG] WelcomeView appeared!")
            startPermissionCheck()
        }
    }
    
    private var headerView: some View {
        VStack(spacing: 16) {
            if let appIcon = NSImage(named: "AppIcon") {
                Image(nsImage: appIcon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                    // The macOS app icon usually has transparent borders or its own shape
            } else {
                Image(systemName: "keyboard")
                    .font(.system(size: 52, weight: .semibold))
                    .foregroundColor(theme.accent)
            }
            
            Text("Welcome to TypeSteps")
                .font(.title.bold())
                .foregroundColor(theme.text)
            
            Text("Track your typing activity with precision")
                .font(.subheadline)
                .foregroundColor(theme.secondaryText)
        }
        .padding(.top, 40)
    }
    
    @ViewBuilder
    private var contentView: some View {
        VStack(spacing: 20) {
            if currentStep == 0 {
                accessibilityStepView
            } else {
                loginItemStepView
            }
        }
        .padding(.horizontal, 40)
    }
    
    private var accessibilityStepView: some View {
        VStack(spacing: 20) {
            Text("Accessibility Permission Required")
                .font(.headline.bold())
                .foregroundColor(theme.text)
            
            Text("TypeSteps needs Accessibility permission to track your typing activity across all applications. This allows the app to detect which keys you type and in which apps.")
                .font(.subheadline)
                .foregroundColor(theme.secondaryText)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
            
            VStack(alignment: .leading, spacing: 20) {
                HStack(alignment: .center, spacing: 16) {
                    Image(systemName: "eye")
                        .font(.system(size: 20, weight: .regular))
                        .foregroundColor(theme.accent)
                        .frame(width: 28)
                    Text("Monitors keyboard input globally")
                        .font(.body)
                        .foregroundColor(theme.text)
                }
                HStack(alignment: .center, spacing: 16) {
                    Image(systemName: "lock.shield")
                        .font(.system(size: 20, weight: .regular))
                        .foregroundColor(theme.accent)
                        .frame(width: 28)
                    Text("All data stays on your device securely")
                        .font(.body)
                        .foregroundColor(theme.text)
                }
                HStack(alignment: .center, spacing: 16) {
                    Image(systemName: "app.badge.checkmark")
                        .font(.system(size: 20, weight: .regular))
                        .foregroundColor(theme.accent)
                        .frame(width: 28)
                    Text("Revoke permission anytime in Settings")
                        .font(.body)
                        .foregroundColor(theme.text)
                }
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 20)
            
            if isCheckingPermission {
                HStack(spacing: 10) {
                    ProgressView()
                        .scaleEffect(0.85)
                    Text("Checking permission...")
                        .font(.subheadline)
                        .foregroundColor(theme.secondaryText)
                }
                .padding(.top, 8)
            } else if permissionGranted {
                HStack(spacing: 10) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Permission granted!")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.green)
                }
                .padding(.top, 8)
            }
        }
    }
    
    private var loginItemStepView: some View {
        VStack(spacing: 20) {
            Text("Start Automatically on Login")
                .font(.headline.bold())
                .foregroundColor(theme.text)
            
            Text("Enable \"Open at Login\" to automatically start TypeSteps when you turn on your Mac each day. This way you'll never miss tracking your typing activity.")
                .font(.subheadline)
                .foregroundColor(theme.secondaryText)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
            
            VStack(alignment: .leading, spacing: 20) {
                HStack(alignment: .center, spacing: 16) {
                    Image(systemName: "clock")
                        .font(.system(size: 20, weight: .regular))
                        .foregroundColor(theme.accent)
                        .frame(width: 28)
                    Text("Starts automatically in the background")
                        .font(.body)
                        .foregroundColor(theme.text)
                }
                HStack(alignment: .center, spacing: 16) {
                    Image(systemName: "battery.100")
                        .font(.system(size: 20, weight: .regular))
                        .foregroundColor(theme.accent)
                        .frame(width: 28)
                    Text("Lightweight - won't affect Mac performance")
                        .font(.body)
                        .foregroundColor(theme.text)
                }
                HStack(alignment: .center, spacing: 16) {
                    Image(systemName: "gearshape.2")
                        .font(.system(size: 20, weight: .regular))
                        .foregroundColor(theme.accent)
                        .frame(width: 28)
                    Text("You can change this anytime in Settings")
                        .font(.body)
                        .foregroundColor(theme.text)
                }
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 20)
            
            if loginItemEnabled {
                HStack(spacing: 10) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Open at Login enabled!")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.green)
                }
                .padding(.top, 8)
            } else {
                Toggle(isOn: $loginItemEnabled) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Enable Open at Login")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(theme.text)
                        Text("Automatically start TypeSteps when you log in")
                            .font(.caption)
                            .foregroundColor(theme.secondaryText)
                    }
                }
                .toggleStyle(.switch)
                .onChange(of: loginItemEnabled) { _, newValue in
                    if newValue {
                        enableLoginItem()
                    } else {
                        disableLoginItem()
                    }
                }
            }
        }
    }
    
    private var bottomView: some View {
        HStack(spacing: 12) {
            if currentStep == 1 {
                Button(action: completeOnboarding) {
                    Text("Skip for now")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(theme.secondaryText)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(theme.secondaryBg)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(theme.border, lineWidth: 0.5)
                        )
                }
                .buttonStyle(.plain)
            }
            
            Spacer()
            
            if currentStep == 0 {
                Button(action: openAccessibilitySettings) {
                    Text("Open System Settings")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(theme.accent)
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)
            } else {
                Button(action: completeOnboarding) {
                    Text("Get Started")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(theme.accent)
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 40)
        .padding(.bottom, 32)
    }
    
    private func startPermissionCheck() {
        checkPermissionStatus()
        
        permissionCheckTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            checkPermissionStatus()
        }
    }
    
    private func checkPermissionStatus() {
        let granted = AXIsProcessTrusted()
        
        if granted && !permissionGranted {
            permissionGranted = true
            isCheckingPermission = false
            permissionCheckTimer?.invalidate()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                withAnimation {
                    currentStep = 1
                }
            }
        }
    }
    
    private func openAccessibilitySettings() {
        isCheckingPermission = true
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        _ = AXIsProcessTrustedWithOptions(options as CFDictionary)
    }
    
    private func enableLoginItem() {
        do {
            if SMAppService.mainApp.status == .enabled {
                loginItemEnabled = true
            } else {
                try SMAppService.mainApp.register()
                loginItemEnabled = SMAppService.mainApp.status == .enabled
            }
        } catch {
            print("Failed to enable login item: \(error)")
        }
    }
    
    private func disableLoginItem() {
        do {
            try SMAppService.mainApp.unregister()
            loginItemEnabled = SMAppService.mainApp.status != .enabled
        } catch {
            print("Failed to disable login item: \(error)")
        }
    }
    
    private func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: "has_completed_onboarding")
        
        NotificationCenter.default.post(name: .onboardingCompleted, object: nil)
        
        showOnboarding = false
    }
}
