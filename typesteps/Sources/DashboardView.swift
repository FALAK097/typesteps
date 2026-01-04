import SwiftUI
import Charts

struct ActivityPoint: Identifiable {
    let id = UUID()
    let label: String
    let count: Int
}

struct DashboardView: View {
    @ObservedObject var storage = StorageManager.shared
    @State private var selectedTab = 0 
    @AppStorage("app_theme") private var appTheme = 0 
    @AppStorage("daily_goal") private var dailyGoal = 5000 
    
    private var bgMain: Color {
        appTheme == 1 ? Color.white : Color(red: 9/255, green: 9/255, blue: 11/255)
    }
    
    private var bgSecondary: Color {
        appTheme == 1 ? Color(red: 244/255, green: 244/255, blue: 245/255) : Color(red: 24/255, green: 24/255, blue: 27/255)
    }
    
    private var borderColor: Color {
        appTheme == 1 ? Color(red: 228/255, green: 228/255, blue: 231/255) : Color(red: 39/255, green: 39/255, blue: 42/255)
    }
    
    private let accent = Color(red: 99/255, green: 102/255, blue: 241/255) 
    
    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 0) {
                header
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 40) {
                        if geo.size.width > 600 {
                            HStack(alignment: .top, spacing: 48) {
                                leftColumn
                                rightColumn
                            }
                        } else {
                            VStack(alignment: .leading, spacing: 40) {
                                leftColumn
                                rightColumn
                            }
                        }
                    }
                    .padding(geo.size.width > 600 ? 40 : 24)
                }
            }
        }
        .background(bgMain)
    }
    
    private var header: some View {
        VStack(spacing: 0) {
            HStack {
                Text("TypeSteps")
                    .font(.system(size: 14, weight: .semibold))
                
                Spacer()
                
                Button {
                    appTheme = (appTheme + 1) % 3
                } label: {
                    Image(systemName: themeIcon)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                        .frame(width: 28, height: 28)
                        .background(bgSecondary)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(borderColor, lineWidth: 1))
                }
                .buttonStyle(.plain)
                .padding(.trailing, 8)
                
                Picker("", selection: $selectedTab) {
                    Text("Day").tag(0)
                    Text("Week").tag(1)
                    Text("Month").tag(2)
                }
                .pickerStyle(.segmented)
                .frame(width: 160)
                .scaleEffect(0.9)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            
            Divider().background(borderColor)
        }
    }
    
    private var themeIcon: String {
        switch appTheme {
        case 1: return "sun.max"
        case 2: return "moon"
        default: return "desktopcomputer"
        }
    }
    
    private var leftColumn: some View {
        VStack(alignment: .leading, spacing: 32) {
            HStack(alignment: .bottom, spacing: 24) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(currentLabel.uppercased())
                        .font(.system(size: 10, weight: .medium))
                        .kerning(1.5)
                        .foregroundStyle(.secondary)
                    
                    Text("\(currentMainCount)")
                        .font(.system(size: 56, weight: .bold))
                }
                
                if selectedTab == 0 {
                    Spacer()
                    goalProgressCircle
                }
            }
            
            VStack(alignment: .leading, spacing: 16) {
                Text("ACTIVITY TREND")
                    .font(.system(size: 10, weight: .medium))
                    .kerning(1.5)
                    .foregroundStyle(.secondary)
                
                Chart(chartData) { point in
                    if selectedTab == 0 {
                        AreaMark(x: .value("T", point.label), y: .value("C", point.count))
                            .interpolationMethod(.monotone)
                            .foregroundStyle(accent.opacity(0.1).gradient)
                        LineMark(x: .value("T", point.label), y: .value("C", point.count))
                            .interpolationMethod(.monotone)
                            .foregroundStyle(accent)
                    } else {
                        BarMark(x: .value("L", point.label), y: .value("C", point.count))
                            .foregroundStyle(point.label == currentDayLabel ? accent : Color.secondary.opacity(0.2))
                            .cornerRadius(2)
                    }
                }
                .frame(height: 200)
                .chartYAxis {
                    AxisMarks(position: .leading) {
                        AxisGridLine().foregroundStyle(borderColor)
                        AxisValueLabel().font(.system(size: 9))
                    }
                }
                .chartXAxis {
                    AxisMarks { AxisValueLabel().font(.system(size: 9)) }
                }
            }
        }
    }
    
    private var goalProgressCircle: some View {
        let progress = min(1.0, Double(storage.getCount()) / Double(max(1, dailyGoal)))
        return ZStack {
            Circle()
                .stroke(borderColor, lineWidth: 4)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(accent, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .rotationEffect(.degrees(-90))
            
            VStack(spacing: 2) {
                Text("\(Int(progress * 100))%")
                    .font(.system(size: 10, weight: .bold))
                Text("GOAL")
                    .font(.system(size: 6))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 48, height: 48)
        .padding(.bottom, 8)
    }
    
    private var rightColumn: some View {
        VStack(alignment: .leading, spacing: 40) {
            VStack(alignment: .leading, spacing: 24) {
                Text("INSIGHTS")
                    .font(.system(size: 10, weight: .medium))
                    .kerning(1.5)
                    .foregroundStyle(.secondary)
                
                InsightRow(label: "BEST DAY", value: "\(storage.getBestDay().count)", icon: "arrow.up.right")
                InsightRow(label: "DAILY GOAL", value: "\(dailyGoal)", icon: "target")
                
                HStack {
                    Slider(value: Binding(get: { Double(dailyGoal) }, set: { dailyGoal = Int($0) }), in: 1000...20000, step: 500)
                        .accentColor(accent)
                    Text("\(dailyGoal/1000)k")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
                .padding(.top, -12)
            }
            
            Spacer()
            
            Button(action: shareStats) {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                    Text("Share Image Card")
                }
                .font(.system(size: 13, weight: .medium))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(bgSecondary)
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(borderColor, lineWidth: 1))
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: 400)
    }
    
    private var currentMainCount: Int {
        switch selectedTab {
        case 0: return storage.getCount()
        case 1: return storage.getWeeklyTotal()
        case 2: return storage.getMonthlyTotal()
        default: return 0
        }
    }
    
    private var currentLabel: String {
        switch selectedTab {
        case 0: return "Letters Today"
        case 1: return "This Week"
        case 2: return "This Month"
        default: return ""
        }
    }
    
    private var currentDayLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return formatter.string(from: Date())
    }
    
    private var chartData: [ActivityPoint] {
        let rawData: [(label: String, count: Int)]
        switch selectedTab {
        case 0: rawData = storage.getTodayHourly()
        case 1: rawData = storage.getLastSevenDays()
        case 2: rawData = storage.getLastThirtyDays()
        default: rawData = []
        }
        return rawData.map { ActivityPoint(label: $0.label, count: $0.count) }
    }
    
    private func shareStats() {
        let card = ShareCard(count: currentMainCount, label: currentLabel, theme: appTheme)
        let renderer = ImageRenderer(content: card)
        renderer.scale = 3.0
        if let image = renderer.nsImage {
            let picker = NSSharingServicePicker(items: [image])
            picker.show(relativeTo: NSRect.zero, of: NSApp.keyWindow?.contentView ?? NSView(), preferredEdge: NSRectEdge.minY)
        }
    }
}

struct InsightRow: View {
    let label: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(Color(red: 99/255, green: 102/255, blue: 241/255))
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
            }
        }
    }
}

struct ShareCard: View {
    let count: Int
    let label: String
    let theme: Int
    
    var body: some View {
        VStack(spacing: 32) {
            HStack(spacing: 12) {
                Image(systemName: "keyboard")
                    .font(.title)
                    .foregroundStyle(Color(red: 99/255, green: 102/255, blue: 241/255))
                Text("TypeSteps")
                    .font(.system(size: 24, weight: .black, design: .rounded))
            }
            
            VStack(spacing: 8) {
                Text("\(count)")
                    .font(.system(size: 84, weight: .bold, design: .rounded))
                Text(label.uppercased())
                    .font(.system(size: 14, weight: .semibold))
                    .kerning(3)
                    .foregroundStyle(.secondary)
            }
            
            Text("falakgala.dev")
                .font(.system(size: 12, weight: .bold))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(.indigo.opacity(0.1))
                .clipShape(Capsule())
        }
        .frame(width: 500, height: 500)
        .background(theme == 1 ? Color.white : Color(red: 9/255, green: 9/255, blue: 11/255))
        .foregroundStyle(theme == 1 ? .black : .white)
    }
}
