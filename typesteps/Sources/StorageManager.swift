import SwiftUI
import Combine

class StorageManager: ObservableObject {
    static let shared = StorageManager()
    private let statsKey = "typing_stats_daily"
    private let hourlyKey = "typing_stats_hourly"
    
    @Published var dailyStats: [String: Int] = [:]
    @Published var hourlyStats: [String: Int] = [:]
    
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
    }
    
    func incrementCount(for date: Date = Date()) {
        let dayString = dateFormatter.string(from: date)
        let hourString = hourlyFormatter.string(from: date)
        
        dailyStats[dayString] = (dailyStats[dayString] ?? 0) + 1
        hourlyStats[hourString] = (hourlyStats[hourString] ?? 0) + 1
        
        saveStats()
    }
    
    func getCount(for date: Date = Date()) -> Int {
        return dailyStats[dateFormatter.string(from: date)] ?? 0
    }
    
    private func saveStats() {
        UserDefaults.standard.set(dailyStats, forKey: statsKey)
        UserDefaults.standard.set(hourlyStats, forKey: hourlyKey)
    }
    
    // MARK: - Aggregation
    
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
        let calendar = Calendar.current
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
    
    func getLastThirtyDays() -> [(label: String, count: Int)] {
        let calendar = Calendar.current
        var result: [(label: String, count: Int)] = []
        
        for i in (0..<30).reversed() {
            if let date = calendar.date(byAdding: .day, value: -i, to: Date()) {
                let key = dateFormatter.string(from: date)
                let day = calendar.component(.day, from: date)
                result.append((label: "\(day)", count: dailyStats[key] ?? 0))
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
}
