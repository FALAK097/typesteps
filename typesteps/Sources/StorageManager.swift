import SwiftUI
import Combine
import UserNotifications

class StorageManager: ObservableObject {
    static let shared = StorageManager()
    private let statsKey = "typing_stats_daily"
    private let hourlyKey = "typing_stats_hourly"
    private let minuteKey = "typing_stats_minute"
    private let appStatsKey = "typing_stats_apps"
    private let projectStatsKey = "typing_stats_projects"
    private let appBundleMappingKey = "typing_app_bundles" 
    private let notifiedKey = "typing_notified_milestones"
    
    @AppStorage("wakatime_api_key") var wakaTimeApiKey: String = ""
    
    @Published var dailyStats: [String: Int] = [:]
    @Published var hourlyStats: [String: Int] = [:]
    @Published var minuteStats: [String: Int] = [:] 
    @Published var appStats: [String: Int] = [:]
    @Published var projectStats: [String: Int] = [:]
    @Published var appBundleMapping: [String: String] = [:] 
    
    private let minuteFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd-HH-mm"
        return formatter
    }()
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
    
    private let hourlyFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd-HH"
        return formatter
    }()
    
    init() {
        loadStats()
    }
    
    func loadStats() {
        if let daily = UserDefaults.standard.dictionary(forKey: statsKey) as? [String: Int] { self.dailyStats = daily }
        if let hourly = UserDefaults.standard.dictionary(forKey: hourlyKey) as? [String: Int] { self.hourlyStats = hourly }
        if let minute = UserDefaults.standard.dictionary(forKey: minuteKey) as? [String: Int] { self.minuteStats = minute }
        if let apps = UserDefaults.standard.dictionary(forKey: appStatsKey) as? [String: Int] { self.appStats = apps }
        if let projects = UserDefaults.standard.dictionary(forKey: projectStatsKey) as? [String: Int] { self.projectStats = projects }
        if let mapping = UserDefaults.standard.dictionary(forKey: appBundleMappingKey) as? [String: String] { self.appBundleMapping = mapping }
    }
    
    func incrementCount(for date: Date = Date(), appName: String? = nil, bundleId: String? = nil, projectName: String? = nil) {
        let dayString = dateFormatter.string(from: date)
        let hourString = hourlyFormatter.string(from: date)
        let minuteString = minuteFormatter.string(from: date)
        
        dailyStats[dayString] = (dailyStats[dayString] ?? 0) + 1
        hourlyStats[hourString] = (hourlyStats[hourString] ?? 0) + 1
        minuteStats[minuteString] = (minuteStats[minuteString] ?? 0) + 1
        
        if let appName = appName {
            appStats[appName] = (appStats[appName] ?? 0) + 1
            if let bundleId = bundleId { appBundleMapping[appName] = bundleId }
        }
        if let projectName = projectName { projectStats[projectName] = (projectStats[projectName] ?? 0) + 1 }
        
        if minuteStats.count > 120 {
            let keys = minuteStats.keys.sorted().prefix(minuteStats.count - 120)
            for key in keys { minuteStats.removeValue(forKey: key) }
        }
        
        checkMilestones(count: dailyStats[dayString] ?? 0, day: dayString)
        saveStats()
    }
    
    private func checkMilestones(count: Int, day: String) {
        let goal = UserDefaults.standard.integer(forKey: "daily_goal")
        guard goal > 0 else { return }
        let milestones = [1.0]
        var notified = UserDefaults.standard.dictionary(forKey: notifiedKey) as? [String: [Double]] ?? [:]
        var dayNotified = notified[day] ?? []
        for m in milestones {
            if Double(count) >= Double(goal) * m && !dayNotified.contains(m) {
                sendNotification()
                dayNotified.append(m)
            }
        }
        notified[day] = dayNotified
        UserDefaults.standard.set(notified, forKey: notifiedKey)
    }
    
    private func sendNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Goal Reached! 🎯"
        content.body = "Congratulations! You've reached your daily typing goal."
        content.sound = .default
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
    
    func getCount(for date: Date = Date()) -> Int { return dailyStats[dateFormatter.string(from: date)] ?? 0 }
    
    private func saveStats() {
        UserDefaults.standard.set(dailyStats, forKey: statsKey)
        UserDefaults.standard.set(hourlyStats, forKey: hourlyKey)
        UserDefaults.standard.set(minuteStats, forKey: minuteKey)
        UserDefaults.standard.set(appStats, forKey: appStatsKey)
        UserDefaults.standard.set(projectStats, forKey: projectStatsKey)
        UserDefaults.standard.set(appBundleMapping, forKey: appBundleMappingKey)
    }
    
    func getTopApps(limit: Int = 5) -> [(name: String, count: Int)] {
        return appStats.sorted { $0.value > $1.value }.prefix(limit).map { (name: $0.key, count: $0.value) }
    }
    
    private func categorize(appName: String, bundleId: String? = nil) -> AppCategory {
        let name = appName.lowercased()
        let bid = bundleId?.lowercased() ?? ""
        
        // Code / Development
        let codeApps = ["xcode", "code", "cursor", "terminal", "ghostty", "warp", "intellij", "pycharm", "webstorm", "sublime", "iterm", "vterm", "neovim", "vim", "emacs", "docker", "postman", "sequel", "tableplus", "gitkraken", "sourcetree", "tower", "github"]
        let codeBundles = ["com.apple.dt.xcode", "com.visualstudio.code", "com.todesktop.230313m78xv9jbu", "com.googlecode.iterm2", "com.github.atom"]
        if codeApps.contains(where: { name.contains($0) }) || codeBundles.contains(where: { bid.contains($0) }) { return .code }
        
        // Communicate / Social
        let communicateApps = ["slack", "discord", "telegram", "whatsapp", "teams", "mail", "messages", "zoom", "skype", "wechat", "signal", "outlook"]
        let communicateBundles = ["com.tinyspeck.slackmacgap", "com.hnc.discord", "org.telegram.desktop", "com.whatsapp.whatsapp"]
        if communicateApps.contains(where: { name.contains($0) }) || communicateBundles.contains(where: { bid.contains($0) }) { return .communicate }
        
        // Create / Design / Writing
        let createApps = ["figma", "photoshop", "illustrator", "canva", "obsidian", "notion", "linear", "trello", "jira", "craft", "bear", "pages", "keynote", "numbers", "excel", "word", "powerpoint", "blender", "unity", "unreal", "premiere", "final cut", "da vinci"]
        let createBundles = ["com.figma.Desktop", "com.adobe.Photoshop", "md.obsidian", "notion.id"]
        if createApps.contains(where: { name.contains($0) }) || createBundles.contains(where: { bid.contains($0) }) { return .create }
        
        // Browsing
        let browsingApps = ["safari", "chrome", "arc", "firefox", "browser", "edge", "opera", "vivaldi", "brave"]
        let browsingBundles = ["com.apple.safari", "com.google.chrome", "company.thebrowser.browser"]
        if browsingApps.contains(where: { name.contains($0) }) || browsingBundles.contains(where: { bid.contains($0) }) { return .browsing }
        
        // Utility / System
        let utilityApps = ["settings", "finder", "calculator", "notes", "calendar", "reminders", "dictionary", "activity monitor", "console", "app store", "music", "spotify", "tv", "photos"]
        if utilityApps.contains(where: { name.contains($0) }) || bid.contains("com.apple.") { return .utility }
        
        return .other
    }
    
    func getCategoryStats() -> [(category: AppCategory, count: Int)] {
        var counts: [AppCategory: Int] = [:]
        for (appName, count) in appStats {
            let cat = categorize(appName: appName, bundleId: appBundleMapping[appName])
            counts[cat] = (counts[cat] ?? 0) + count
        }
        return AppCategory.allCases.map { (category: $0, count: counts[$0] ?? 0) }.filter { $0.count > 0 }.sorted { $0.count > $1.count }
    }
    
    func getTopProjects(limit: Int = 5) -> [(name: String, count: Int)] {
        return projectStats.sorted { $0.value > $1.value }.prefix(limit).map { (name: $0.key, count: $0.value) }
    }
    
    func getLibraryStats() -> [(milestone: String, iterations: Double, progress: Double)] {
        let total = Double(getTotalAllTime())
        let milestones = [
            ("Keyboard Sprint (100m)", 10000.0),
            ("The Tower (Burj Khalifa)", 50000.0),
            ("City Explorer (Central Park)", 250000.0),
            ("Mountain King (Mt. Everest)", 1000000.0),
            ("Channel Swimmer (English Channel)", 5000000.0),
            ("Grand Tour (Across India)", 50000000.0)
        ]
        return milestones.map { name, chars in
            let progress = min(1.0, total / chars)
            let iterations = total / chars
            return (name, iterations, progress)
        }
    }
    
    func getNextMilestone() -> (name: String, progress: Double, remaining: Int)? {
        let total = Double(getTotalAllTime())
        let milestones = [
            ("Keyboard Sprint (100m)", 10000.0),
            ("The Tower (Burj Khalifa)", 50000.0),
            ("City Explorer (Central Park)", 250000.0),
            ("Mountain King (Mt. Everest)", 1000000.0),
            ("Channel Swimmer (English Channel)", 5000000.0),
            ("Grand Tour (Across India)", 50000000.0)
        ]
        for m in milestones { if total < m.1 { return (m.0, total / m.1, Int(m.1 - total)) } }
        return nil
    }
    
    func getProductivityBadge() -> (label: String, color: Color) {
        let streak = getCurrentStreak()
        let todayCount = getCount()
        if streak >= 30 { return ("UNSTOPPABLE", .red) }
        if streak >= 7 { return ("CONSISTENT", .orange) }
        if todayCount >= UserDefaults.standard.integer(forKey: "daily_goal") { return ("GOAL GETTER", .green) }
        return ("ON THE RISE", .blue)
    }
    
    func getMostActiveDayThisWeek() -> (date: String, count: Int)? {
        let calendar = Calendar.current
        let now = Date()
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now))!
        let weekStats = dailyStats.filter { entry in
            guard let date = dateFormatter.date(from: entry.key) else { return false }
            return date >= startOfWeek
        }
        guard let maxEntry = weekStats.max(by: { $0.value < $1.value }) else { return nil }
        return (date: maxEntry.key, count: maxEntry.value)
    }
    
    func getQuietestDay() -> (date: String, count: Int)? {
        guard !dailyStats.isEmpty else { return nil }
        guard let minEntry = dailyStats.min(by: { $0.value < $1.value }) else { return nil }
        return (date: minEntry.key, count: minEntry.value)
    }
    
    func getWeeklyTotal() -> Int {
        let calendar = Calendar.current
        let now = Date()
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now))!
        return dailyStats.reduce(0) { total, entry in
            guard let date = dateFormatter.date(from: entry.key) else { return total }
            return date >= startOfWeek ? total + entry.value : total
        }
    }
    
    func getMonthlyTotal() -> Int {
        let calendar = Calendar.current
        let now = Date()
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
        return dailyStats.reduce(0) { total, entry in
            guard let date = dateFormatter.date(from: entry.key) else { return total }
            return date >= startOfMonth ? total + entry.value : total
        }
    }
    
    func getTodayHourly() -> [(label: String, count: Int)] {
        let today = dateFormatter.string(from: Date())
        var result: [(label: String, count: Int)] = []
        for hour in 0..<24 {
            let label = String(format: "%02d:00", hour)
            let key = "\(today)-\(String(format: "%02d", hour))"
            result.append((label: label, count: hourlyStats[key] ?? 0))
        }
        return result
    }
    
    func getLastSevenDays() -> [(label: String, count: Int)] {
        let calendar = Calendar.current
        var result: [(label: String, count: Int)] = []
        let displayFormatter = DateFormatter(); displayFormatter.dateFormat = "E"
        for i in (0..<7).reversed() {
            if let date = calendar.date(byAdding: .day, value: -i, to: Date()) {
                let key = dateFormatter.string(from: date)
                result.append((label: displayFormatter.string(from: date), count: dailyStats[key] ?? 0))
            }
        }
        return result
    }
    
    func getLastSixMonths() -> [(label: String, count: Int)] {
        let calendar = Calendar.current
        var result: [(label: String, count: Int)] = []
        let displayFormatter = DateFormatter(); displayFormatter.dateFormat = "MMM"
        for i in (0..<6).reversed() {
            if let date = calendar.date(byAdding: .month, value: -i, to: Date()) {
                let month = calendar.component(.month, from: date); let year = calendar.component(.year, from: date)
                let monthTotal = dailyStats.reduce(0) { total, entry in
                    guard let d = dateFormatter.date(from: entry.key) else { return total }
                    return (calendar.component(.month, from: d) == month && calendar.component(.year, from: d) == year) ? total + entry.value : total
                }
                result.append((label: displayFormatter.string(from: date), count: monthTotal))
            }
        }
        return result
    }
    
    func getBestDay() -> (date: String, count: Int) {
        let best = dailyStats.max { $0.value < $1.value }
        return (date: best?.key ?? "N/A", count: best?.value ?? 0)
    }
    
    func getTotalAllTime() -> Int { return dailyStats.values.reduce(0, +) }
    
    func getPeakHour() -> (hour: Int, count: Int) {
        var hourCounts = [Int: Int]()
        for (key, count) in hourlyStats {
            let components = key.split(separator: "-")
            if components.count == 4, let hour = Int(components[3]) { hourCounts[hour] = (hourCounts[hour] ?? 0) + count }
        }
        if let maxEntry = hourCounts.max(by: { $0.value < $1.value }) { return (hour: maxEntry.key, count: maxEntry.value) }
        return (hour: 0, count: 0)
    }
    
    func getAveragePerHour() -> Int {
        let activeHours = hourlyStats.filter { $0.value > 0 }
        guard !activeHours.isEmpty else { return 0 }
        return activeHours.reduce(0) { $0 + $1.value } / activeHours.count
    }
    
    func getCurrentStreak() -> Int {
        let calendar = Calendar.current; var currentStreak = 0; var checkDate = Date()
        while true {
            let key = dateFormatter.string(from: checkDate)
            if let count = dailyStats[key], count > 0 {
                currentStreak += 1
                guard let nextDate = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
                checkDate = nextDate
            } else {
                if calendar.isDateInToday(checkDate) {
                    guard let nextDate = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
                    checkDate = nextDate; continue
                }
                break
            }
        }
        return currentStreak
    }
    
    func exportData() -> Data? {
        let notified = UserDefaults.standard.dictionary(forKey: notifiedKey) as? [String: [Double]] ?? [:]
        let goal = UserDefaults.standard.integer(forKey: "daily_goal")
        
        let backup = BackupData(
            dailyStats: dailyStats,
            hourlyStats: hourlyStats,
            minuteStats: minuteStats,
            appStats: appStats,
            projectStats: projectStats,
            appBundleMapping: appBundleMapping,
            notifiedMilestones: notified,
            wakaTimeApiKey: wakaTimeApiKey,
            dailyGoal: goal
        )
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        return try? encoder.encode(backup)
    }
    
    func importData(from data: Data) -> Bool {
        guard let backup = try? JSONDecoder().decode(BackupData.self, from: data) else { return false }
        
        DispatchQueue.main.async {
            self.dailyStats = backup.dailyStats
            self.hourlyStats = backup.hourlyStats
            self.minuteStats = backup.minuteStats
            self.appStats = backup.appStats
            self.projectStats = backup.projectStats
            self.appBundleMapping = backup.appBundleMapping
            self.wakaTimeApiKey = backup.wakaTimeApiKey
            
            UserDefaults.standard.set(backup.dailyGoal, forKey: "daily_goal")
            UserDefaults.standard.set(backup.notifiedMilestones, forKey: self.notifiedKey)
            
            self.saveStats()
        }
        return true
    }
    
    func resetStats() {
        dailyStats = [:]
        hourlyStats = [:]
        minuteStats = [:]
        appStats = [:]
        projectStats = [:]
        appBundleMapping = [:]
        // We generally keep the API key and Goal, but for a "hard reset" we might want to clear them or keep them?
        // Usually data reset implies stats. Let's keep settings like API key and Goal to be safe, or ask?
        // The user said "erase the data". I'll erase stats but maybe keep the key/goal to avoid re-entry annoyance, 
        // OR just wipe everything. "erase the data" usually means start fresh.
        // I'll wipe stats.
        
        UserDefaults.standard.removeObject(forKey: statsKey)
        UserDefaults.standard.removeObject(forKey: hourlyKey)
        UserDefaults.standard.removeObject(forKey: minuteKey)
        UserDefaults.standard.removeObject(forKey: appStatsKey)
        UserDefaults.standard.removeObject(forKey: projectStatsKey)
        UserDefaults.standard.removeObject(forKey: appBundleMappingKey)
        UserDefaults.standard.removeObject(forKey: notifiedKey)
        
        // Optional: Keep settings?
        // UserDefaults.standard.removeObject(forKey: "wakatime_api_key")
        // UserDefaults.standard.removeObject(forKey: "daily_goal")
        
        saveStats()
    }
}

struct BackupData: Codable {
    let dailyStats: [String: Int]
    let hourlyStats: [String: Int]
    let minuteStats: [String: Int]
    let appStats: [String: Int]
    let projectStats: [String: Int]
    let appBundleMapping: [String: String]
    let notifiedMilestones: [String: [Double]]
    let wakaTimeApiKey: String
    let dailyGoal: Int
}

