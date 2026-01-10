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
    @Published var minuteStats: [String: Int] = [:] // Last 60 minutes
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
        if let daily = UserDefaults.standard.dictionary(forKey: statsKey) as? [String: Int] {
            self.dailyStats = daily
        }
        if let hourly = UserDefaults.standard.dictionary(forKey: hourlyKey) as? [String: Int] {
            self.hourlyStats = hourly
        }
        if let minute = UserDefaults.standard.dictionary(forKey: minuteKey) as? [String: Int] {
            self.minuteStats = minute
        }
        if let apps = UserDefaults.standard.dictionary(forKey: appStatsKey) as? [String: Int] {
            self.appStats = apps
        }
        if let projects = UserDefaults.standard.dictionary(forKey: projectStatsKey) as? [String: Int] {
            self.projectStats = projects
        }
        if let mapping = UserDefaults.standard.dictionary(forKey: appBundleMappingKey) as? [String: String] {
            self.appBundleMapping = mapping
        }
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
            if let bundleId = bundleId {
                appBundleMapping[appName] = bundleId
            }
        }
        
        if let projectName = projectName {
            projectStats[projectName] = (projectStats[projectName] ?? 0) + 1
        }
        
        // Clean up old minute stats (keep last 120 minutes just in case)
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
                sendNotification(milestone: Int(m * 100))
                dayNotified.append(m)
            }
        }
        
        notified[day] = dayNotified
        UserDefaults.standard.set(notified, forKey: notifiedKey)
    }
    
    private func sendNotification(milestone: Int) {
        let content = UNMutableNotificationContent()
        content.title = "Goal Reached! 🎯"
        content.body = "Congratulations! You've reached your daily typing goal."
        content.sound = .default
        
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
    
    func getCount(for date: Date = Date()) -> Int {
        return dailyStats[dateFormatter.string(from: date)] ?? 0
    }
    
    private func saveStats() {
        UserDefaults.standard.set(dailyStats, forKey: statsKey)
        UserDefaults.standard.set(hourlyStats, forKey: hourlyKey)
        UserDefaults.standard.set(minuteStats, forKey: minuteKey)
        UserDefaults.standard.set(appStats, forKey: appStatsKey)
        UserDefaults.standard.set(projectStats, forKey: projectStatsKey)
        UserDefaults.standard.set(appBundleMapping, forKey: appBundleMappingKey)
    }
    
    // MARK: - Aggregation
    
    func getTopApps(limit: Int = 5) -> [(name: String, count: Int)] {
        return appStats.sorted { $0.value > $1.value }
            .prefix(limit)
            .map { (name: $0.key, count: $0.value) }
    }
    
    func getTopProjects(limit: Int = 5) -> [(name: String, count: Int)] {
        return projectStats.sorted { $0.value > $1.value }
            .prefix(limit)
            .map { (name: $0.key, count: $0.value) }
    }
    
    func getPulseData() -> [ActivityPoint] {
        var points: [ActivityPoint] = []
        let now = Date()
        for i in (0..<60).reversed() {
            if let date = Calendar.current.date(byAdding: .minute, value: -i, to: now) {
                let key = minuteFormatter.string(from: date)
                let count = minuteStats[key] ?? 0
                let label = i % 10 == 0 ? "\(i)m" : ""
                points.append(ActivityPoint(label: label, count: count))
            }
        }
        return points
    }
    
    func getCurrentKPM() -> Int {
        let key = minuteFormatter.string(from: Date())
        return minuteStats[key] ?? 0
    }
    
    func isInFlow() -> Bool {
        // Flow: typing in at least 10 of the last 15 minutes
        let now = Date()
        var activeMinutes = 0
        for i in 0..<15 {
            if let date = Calendar.current.date(byAdding: .minute, value: -i, to: now) {
                let key = minuteFormatter.string(from: date)
                if (minuteStats[key] ?? 0) > 20 { // More than 20 chars per min
                    activeMinutes += 1
                }
            }
        }
        return activeMinutes >= 10
    }
    
    func getLibraryStats() -> [(book: String, pages: Double, progress: Double)] {
        let total = Double(getTotalAllTime())
        let milestones = [
            ("Hello World", 100.0),
            ("First Script", 1000.0),
            ("Standard Library", 10000.0),
            ("Framework Architect", 100000.0),
            ("Open Source Legend", 1000000.0)
        ]
        
        return milestones.map { name, chars in
            let progress = min(1.0, total / chars)
            // Show how many "versions" or "iterations" of this milestone you've done
            let iterations = total / chars
            return (name, iterations, progress)
        }
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
    
    // MARK: - Chart Data
    
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
        let displayFormatter = DateFormatter()
        displayFormatter.dateFormat = "E"
        
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
        let displayFormatter = DateFormatter()
        displayFormatter.dateFormat = "MMM"
        
        for i in (0..<6).reversed() {
            if let date = calendar.date(byAdding: .month, value: -i, to: Date()) {
                let month = calendar.component(.month, from: date)
                let year = calendar.component(.year, from: date)
                
                let monthTotal = dailyStats.reduce(0) { total, entry in
                    guard let d = dateFormatter.date(from: entry.key) else { return total }
                    let entryMonth = calendar.component(.month, from: d)
                    let entryYear = calendar.component(.year, from: d)
                    return (entryMonth == month && entryYear == year) ? total + entry.value : total
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
    
    func getTotalAllTime() -> Int {
        return dailyStats.values.reduce(0, +)
    }
    
    func getPeakHour() -> (hour: Int, count: Int) {
        var hourCounts = [Int: Int]()
        for (key, count) in hourlyStats {
            // key format: yyyy-MM-dd-HH
            let components = key.split(separator: "-")
            if components.count == 4, let hour = Int(components[3]) {
                hourCounts[hour] = (hourCounts[hour] ?? 0) + count
            }
        }
        if let maxEntry = hourCounts.max(by: { $0.value < $1.value }) {
            return (hour: maxEntry.key, count: maxEntry.value)
        }
        return (hour: 0, count: 0)
    }
    
    func getAveragePerHour() -> Int {
        let activeHours = hourlyStats.filter { $0.value > 0 }
        guard !activeHours.isEmpty else { return 0 }
        let total = activeHours.reduce(0) { $0 + $1.value }
        return total / activeHours.count
    }
    
    func getCurrentStreak() -> Int {
        let calendar = Calendar.current
        var currentStreak = 0
        var checkDate = Date()
        
        while true {
            let key = dateFormatter.string(from: checkDate)
            if let count = dailyStats[key], count > 0 {
                currentStreak += 1
                guard let nextDate = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
                checkDate = nextDate
            } else {
                // If the checkDate is TODAY and count is 0, we don't break yet, 
                // we check YESTERDAY to see if the streak is still alive.
                if calendar.isDateInToday(checkDate) {
                    guard let nextDate = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
                    checkDate = nextDate
                    continue
                }
                break
            }
        }
        return currentStreak
    }
}
