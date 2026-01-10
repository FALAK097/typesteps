import SwiftUI
import Combine
import UserNotifications

class StorageManager: ObservableObject {
    static let shared = StorageManager()
    private let statsKey = "typing_stats_daily"
    private let hourlyKey = "typing_stats_hourly"
    private let appStatsKey = "typing_stats_apps"
    private let notifiedKey = "typing_notified_milestones"
    
    @Published var dailyStats: [String: Int] = [:]
    @Published var hourlyStats: [String: Int] = [:]
    @Published var appStats: [String: Int] = [:] 
    
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
        if let apps = UserDefaults.standard.dictionary(forKey: appStatsKey) as? [String: Int] {
            self.appStats = apps
        }
    }
    
    func incrementCount(for date: Date = Date(), appName: String? = nil) {
        let dayString = dateFormatter.string(from: date)
        let hourString = hourlyFormatter.string(from: date)
        
        dailyStats[dayString] = (dailyStats[dayString] ?? 0) + 1
        hourlyStats[hourString] = (hourlyStats[hourString] ?? 0) + 1
        
        if let appName = appName {
            appStats[appName] = (appStats[appName] ?? 0) + 1
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
        UserDefaults.standard.set(appStats, forKey: appStatsKey)
    }
    
    // MARK: - Aggregation
    
    func getTopApps(limit: Int = 5) -> [(name: String, count: Int)] {
        return appStats.sorted { $0.value > $1.value }
            .prefix(limit)
            .map { (name: $0.key, count: $0.value) }
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
