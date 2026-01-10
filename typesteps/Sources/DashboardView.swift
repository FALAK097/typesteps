import SwiftUI
import Charts
internal import UniformTypeIdentifiers

struct AppIconView: View {
    let bundleId: String?
    let size: CGFloat
    
    var body: some View {
        Group {
            if let bundleId = bundleId,
               let appUrl = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleId) {
                Image(nsImage: NSWorkspace.shared.icon(forFile: appUrl.path))
                    .resizable()
                    .interpolation(.high)
            } else {
                Image(systemName: "keyboard")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .padding(size * 0.2)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: size, height: size)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: size * 0.25))
        .shadow(color: .black.opacity(0.1), radius: 2, y: 1)
    }
}

struct DashboardView: View {
    @ObservedObject var storage = StorageManager.shared
    @ObservedObject var wakaTime = WakaTimeManager.shared
    @State private var selectedTab = 0 
    @AppStorage("app_theme") private var appTheme = 0 
    @AppStorage("daily_goal") private var dailyGoal = 5000 
    
    @State private var isShowingWakaKey = false
    @State private var hoveredAction: String?
    @State private var rawSelectedDate: String?
    @State private var hoveredDay: String?
    @State private var hoveredCount: Int?
    
    private let accent = Color(red: 99/255, green: 102/255, blue: 241/255) 
    
    private var bgMain: Color {
        appTheme == 1 ? Color.white : Color(red: 9/255, green: 9/255, blue: 11/255)
    }
    
    private var bgSecondary: Color {
        appTheme == 1 ? Color(red: 244/255, green: 244/255, blue: 245/255) : Color(red: 24/255, green: 24/255, blue: 27/255)
    }
    
    private var borderColor: Color {
        appTheme == 1 ? Color(red: 228/255, green: 228/255, blue: 231/255) : Color(red: 39/255, green: 39/255, blue: 42/255)
    }
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                bgMain.ignoresSafeArea()
                VStack(spacing: 0) {
                    header
                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 40) {
                            if geo.size.width > 900 {
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
                        .padding(geo.size.width > 900 ? 40 : 24)
                    }
                }
            }
        }
        .tint(accent)
    }
    
    private var header: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("TypeSteps")
                        .font(.system(size: 14, weight: .semibold))
                    if let hoveredAction {
                        Text(hoveredAction)
                            .font(.system(size: 8, weight: .black))
                            .foregroundStyle(accent)
                            .transition(.opacity)
                    }
                }
                Spacer()
                HStack(spacing: 8) {
                    Button(action: shareStats) {
                        Image(systemName: "square.and.arrow.up").font(.system(size: 11)).foregroundStyle(.secondary).frame(width: 28, height: 28).background(bgSecondary).clipShape(Circle()).overlay(Circle().stroke(borderColor, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                    .onHover { h in hoveredAction = h ? "SHARE SNAPSHOT" : nil }
                    
                    Button(action: exportCSV) {
                        Image(systemName: "doc.text").font(.system(size: 11)).foregroundStyle(.secondary).frame(width: 28, height: 28).background(bgSecondary).clipShape(Circle()).overlay(Circle().stroke(borderColor, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                    .onHover { h in hoveredAction = h ? "EXPORT CSV" : nil }
                }
                .padding(.trailing, 8)
                
                Button {
                    appTheme = (appTheme + 1) % 3
                } label: {
                    Image(systemName: themeIcon).font(.system(size: 11)).foregroundStyle(.secondary).frame(width: 28, height: 28).background(bgSecondary).clipShape(Circle()).overlay(Circle().stroke(borderColor, lineWidth: 1))
                }
                .buttonStyle(.plain)
                .padding(.trailing, 8)
                .onHover { h in hoveredAction = h ? "TOGGLE THEME" : nil }
                
                Picker("", selection: $selectedTab) {
                    Text("Day").tag(0)
                    Text("Week").tag(1)
                    Text("Month").tag(2)
                }
                .pickerStyle(.segmented).frame(width: 160).tint(accent).scaleEffect(0.9)
                .onHover { h in hoveredAction = h ? "SWITCH VIEW" : nil }
            }
            .padding(.horizontal, 24).padding(.vertical, 12).animation(.easeInOut(duration: 0.2), value: hoveredAction)
            Divider().opacity(0.5)
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
        VStack(alignment: .leading, spacing: 48) {
            VStack(alignment: .leading, spacing: 32) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .lastTextBaseline) {
                        Text(currentLabel.uppercased()).font(.system(size: 10, weight: .medium)).kerning(1.5).foregroundStyle(.secondary)
                        Spacer()
                        Text(dateSubtitle).font(.system(size: 10)).foregroundStyle(.secondary)
                    }
                    HStack(alignment: .bottom) {
                        Text("\(currentMainCount)").font(.system(size: 56, weight: .bold)).contentTransition(.numericText())
                        if selectedTab == 0 {
                            Spacer()
                            goalProgressCircle
                        }
                    }
                }
                
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("ACTIVITY TREND").font(.system(size: 10, weight: .medium)).kerning(1.5).foregroundStyle(.secondary)
                        if let selectedValue = selectedPointValue {
                            Spacer()
                            Text("\(selectedValue) letters").font(.system(size: 10, weight: .bold)).foregroundStyle(accent)
                        }
                    }
                    Chart {
                        ForEach(chartData) { point in
                            if selectedTab == 0 {
                                AreaMark(x: .value("T", point.label), y: .value("C", point.count)).interpolationMethod(.monotone).foregroundStyle(accent.opacity(0.1).gradient)
                                LineMark(x: .value("T", point.label), y: .value("C", point.count)).interpolationMethod(.monotone).foregroundStyle(accent)
                            } else {
                                BarMark(x: .value("L", point.label), y: .value("C", point.count)).foregroundStyle(accent.gradient).cornerRadius(2)
                            }
                        }
                        if let rawSelectedDate {
                            RuleMark(x: .value("Selected", rawSelectedDate)).foregroundStyle(Color.secondary.opacity(0.3))
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
                        if selectedTab == 0 {
                            AxisMarks(values: ["00:00", "04:00", "08:00", "12:00", "16:00", "20:00"]) { _ in
                                AxisGridLine().foregroundStyle(borderColor)
                                AxisValueLabel().font(.system(size: 9))
                            }
                        } else {
                            AxisMarks { _ in
                                AxisGridLine().foregroundStyle(borderColor)
                                AxisValueLabel().font(.system(size: 9))
                            }
                        }
                    }
                    .chartXSelection(value: $rawSelectedDate)
                }
            }
            HStack(alignment: .top, spacing: 48) {
                VStack(alignment: .leading, spacing: 48) {
                    heatmapSection
                    journeySection
                }
                .frame(maxWidth: .infinity)
                topAppsSection
                    .frame(width: 350)
            }
        }
    }
    
    private var journeySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("THE WORLD TOUR").font(.system(size: 10, weight: .medium)).kerning(1.5).foregroundStyle(.secondary)
            VStack(spacing: 12) {
                ForEach(storage.getLibraryStats(), id: \.book) { item in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(item.book).font(.system(size: 11, weight: .semibold))
                            Spacer()
                            if item.progress >= 1.0 {
                                Text("\(Int(item.pages))x completed").font(.system(size: 9, weight: .bold)).foregroundStyle(.green)
                            } else {
                                Text("\(Int(item.progress * 100))%").font(.system(size: 9)).foregroundStyle(.secondary)
                            }
                        }
                        ProgressView(value: item.progress).tint(item.progress >= 1.0 ? .green : accent.opacity(0.8)).scaleEffect(x: 1, y: 0.5, anchor: .center)
                    }
                }
            }
        }
    }

    private var rightColumn: some View {
        VStack(alignment: .leading, spacing: 40) {
            VStack(alignment: .leading, spacing: 24) {
                Text("INSIGHTS").font(.system(size: 10, weight: .medium)).kerning(1.5).foregroundStyle(.secondary)
                InsightRow(label: "BEST DAY", value: "\(storage.getBestDay().count)", icon: "arrow.up.right")
                InsightRow(label: "STREAK", value: "\(storage.getCurrentStreak()) days", icon: "flame")
                InsightRow(label: "PEAK HOUR", value: String(format: "%02d:00", storage.getPeakHour().hour), icon: "clock")
                InsightRow(label: "AVG / HOUR", value: "\(storage.getAveragePerHour())", icon: "bolt")
                InsightRow(label: "DAILY GOAL", value: "\(dailyGoal)", icon: "target")
                HStack {
                    Slider(value: Binding(get: { Double(dailyGoal) }, set: { dailyGoal = Int($0) }), in: 1000...20000, step: 500).tint(accent)
                    Text("\(dailyGoal/1000)k").font(.system(size: 10, design: .monospaced)).foregroundStyle(.secondary)
                }
                .padding(.top, -12)
            }
            highlightsSection
            wakaTimeSection
        }
        .frame(maxWidth: 350)
    }
    
    private var wakaTimeSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("WAKATIME INTEGRATION").font(.system(size: 10, weight: .medium)).kerning(1.5).foregroundStyle(.secondary)
                Spacer()
                HStack(spacing: 12) {
                    if !storage.wakaTimeApiKey.isEmpty {
                        Link(destination: URL(string: "https://wakatime.com/dashboard")!) { Image(systemName: "arrow.up.right.square").font(.system(size: 10)).foregroundStyle(accent) }
                    }
                    if wakaTime.isFetching {
                        ProgressView().scaleEffect(0.5)
                    } else {
                        Button { wakaTime.fetchTodayStats(apiKey: storage.wakaTimeApiKey) } label: { Image(systemName: "arrow.clockwise").font(.system(size: 10)) }.buttonStyle(.plain)
                    }
                }
            }
            VStack(alignment: .leading, spacing: 12) {
                if storage.wakaTimeApiKey.isEmpty {
                    Text("Enter your API Key to see typing density and active time.").font(.system(size: 11)).foregroundStyle(.secondary)
                } else {
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack { Image(systemName: "clock.fill").font(.system(size: 10)).foregroundStyle(.blue); Text("ACTIVE TIME").font(.system(size: 8, weight: .black)).foregroundStyle(.secondary) }
                            Text(formatWakaTime(minutes: wakaTime.totalMinutesToday)).font(.system(size: 18, weight: .bold, design: .rounded))
                        }
                        .padding(12).frame(maxWidth: .infinity, alignment: .leading).background(Color.blue.opacity(0.1)).clipShape(RoundedRectangle(cornerRadius: 12))
                        VStack(alignment: .leading, spacing: 8) {
                            HStack { Image(systemName: "gauge.with.needle.fill").font(.system(size: 10)).foregroundStyle(.purple); Text("DENSITY").font(.system(size: 8, weight: .black)).foregroundStyle(.secondary) }
                            let density = wakaTime.totalMinutesToday > 0 ? Double(storage.getCount()) / wakaTime.totalMinutesToday : 0
                            Text("\(Int(density)) s/m").font(.system(size: 18, weight: .bold, design: .rounded))
                        }
                        .padding(12).frame(maxWidth: .infinity, alignment: .leading).background(Color.purple.opacity(0.1)).clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                HStack {
                    if isShowingWakaKey {
                        TextField("WakaTime API Key", text: $storage.wakaTimeApiKey).textFieldStyle(.plain).font(.system(size: 10, design: .monospaced)).padding(4).background(bgMain.opacity(0.5)).clipShape(RoundedRectangle(cornerRadius: 4))
                    } else {
                        Text(storage.wakaTimeApiKey.isEmpty ? "No API Key" : "••••••••••••••••••••••••••••••••").font(.system(size: 10, design: .monospaced)).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button(isShowingWakaKey ? "SAVE" : "EDIT") {
                        isShowingWakaKey.toggle()
                        if !isShowingWakaKey { wakaTime.fetchTodayStats(apiKey: storage.wakaTimeApiKey) }
                    }
                    .font(.system(size: 9, weight: .black)).buttonStyle(.plain).foregroundStyle(accent)
                }
                .padding(.horizontal, 12).padding(.vertical, 10).background(bgSecondary.opacity(0.5)).clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
    }
    
    private func formatWakaTime(minutes: Double) -> String {
        let hrs = Int(minutes) / 60
        let mins = Int(minutes) % 60
        return hrs > 0 ? "\(hrs)h \(mins)m" : "\(mins)m"
    }
    
    private var highlightsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("WEEKLY HIGHLIGHTS").font(.system(size: 10, weight: .medium)).kerning(1.5).foregroundStyle(.secondary)
            HStack(spacing: 12) {
                if let mostActive = storage.getMostActiveDayThisWeek() { HighlightCard(title: "MOST ACTIVE", subtitle: mostActive.date, value: "\(mostActive.count)", icon: "bolt.fill", color: .orange) }
                if let quietest = storage.getQuietestDay() { HighlightCard(title: "QUIETEST", subtitle: quietest.date, value: "\(quietest.count)", icon: "leaf.fill", color: .green) }
            }
        }
    }
    
    private var heatmapSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("2026 CONSISTENCY").font(.system(size: 10, weight: .medium)).kerning(1.5).foregroundStyle(.secondary)
                Spacer()
                if let hoveredDay, let hoveredCount { Text("\(hoveredDay): \(hoveredCount) steps").font(.system(size: 10, weight: .bold)).foregroundStyle(accent) }
                else { Text("\(storage.getTotalAllTime()) Total").font(.system(size: 10, weight: .bold)).foregroundStyle(.secondary) }
            }
            let daysIn2026 = 365
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHGrid(rows: Array(repeating: GridItem(.fixed(10), spacing: 3), count: 7), spacing: 3) {
                    ForEach(0..<daysIn2026, id: \.self) { i in heatmapCell(dayOfYear: i) }
                }
                .padding(.vertical, 4)
            }
            .frame(height: 95)
        }
    }
    
    private var topAppsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("TOP APPLICATIONS").font(.system(size: 10, weight: .medium)).kerning(1.5).foregroundStyle(.secondary)
                Spacer()
                if !storage.projectStats.isEmpty { Text("PROJECTS").font(.system(size: 10, weight: .medium)).foregroundStyle(accent) }
            }
            let topApps = storage.getTopApps()
            if topApps.isEmpty { Text("No app data yet").font(.system(size: 12)).foregroundStyle(.secondary) }
            else {
                VStack(spacing: 8) {
                    ForEach(topApps, id: \.name) { app in
                        HStack(spacing: 12) {
                            AppIconView(bundleId: storage.appBundleMapping[app.name], size: 28)
                            VStack(alignment: .leading, spacing: 4) {
                                HStack { Text(app.name).font(.system(size: 12, weight: .bold)); Spacer(); Text("\(app.count)").font(.system(size: 11, design: .monospaced)).foregroundStyle(.secondary) }
                                let total = storage.appStats.values.reduce(0, +)
                                let percentage = total > 0 ? Double(app.count) / Double(total) : 0
                                GeometryReader { barGeo in ZStack(alignment: .leading) { Capsule().fill(borderColor).frame(height: 4); Capsule().fill(accent.gradient).frame(width: barGeo.size.width * percentage, height: 4) } }.frame(height: 4)
                            }
                        }
                        .padding(10).background(bgSecondary.opacity(0.4)).clipShape(RoundedRectangle(cornerRadius: 12)).overlay(RoundedRectangle(cornerRadius: 12).stroke(borderColor.opacity(0.5), lineWidth: 0.5))
                    }
                }
            }
            let topProjects = storage.getTopProjects(limit: 3)
            if !topProjects.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(topProjects, id: \.name) { project in
                        HStack { Image(systemName: "folder.fill").font(.system(size: 10)).foregroundStyle(accent); Text(project.name).font(.system(size: 11, weight: .medium)); Spacer(); Text("\(project.count) steps").font(.system(size: 10, design: .monospaced)).foregroundStyle(.secondary) }.padding(.horizontal, 8)
                    }
                }
                .padding(.top, 8)
            }
        }
    }
    
    private func heatmapCell(dayOfYear: Int) -> some View {
        let calendar = Calendar.current
        var components = DateComponents(); components.year = 2026; components.day = dayOfYear + 1
        let date = calendar.date(from: components)!
        let formatter = DateFormatter(); formatter.dateFormat = "yyyy-MM-dd"
        let key = formatter.string(from: date); let count = storage.dailyStats[key] ?? 0
        let intensity = min(1.0, Double(count) / Double(max(1, dailyGoal))); let isFuture = date > Date()
        return RoundedRectangle(cornerRadius: 1.5).fill(count > 0 ? accent.opacity(0.2 + intensity * 0.8) : (isFuture ? Color.clear : borderColor.opacity(0.3))).frame(width: 10, height: 10)
            .onHover { hovering in if hovering { hoveredDay = key; hoveredCount = count } else { hoveredDay = nil; hoveredCount = nil } }
            .help("\(key): \(count) letters")
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
    
    private var dateSubtitle: String {
        let formatter = DateFormatter(); let now = Date()
        switch selectedTab {
        case 0: formatter.dateFormat = "MMM d, yyyy"; return formatter.string(from: now)
        case 1: let components = Calendar.current.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now); let startOfWeek = Calendar.current.date(from: components)!; formatter.dateFormat = "MMM d"; return "\(formatter.string(from: startOfWeek)) - \(formatter.string(from: now))"
        case 2: formatter.dateFormat = "MMMM yyyy"; return formatter.string(from: now)
        default: return ""
        }
    }
    
    private var selectedPointValue: Int? {
        guard let rawSelectedDate else { return nil }
        return chartData.first(where: { $0.label == rawSelectedDate })?.count
    }
    
    private var goalProgressCircle: some View {
        let progress = min(1.0, Double(storage.getCount()) / Double(max(1, dailyGoal)))
        return ZStack {
            Circle().stroke(borderColor, lineWidth: 4)
            Circle().trim(from: 0, to: progress).stroke(accent, style: StrokeStyle(lineWidth: 4, lineCap: .round)).rotationEffect(.degrees(-90)).animation(.easeOut(duration: 1.0), value: progress)
            VStack(spacing: 2) { Text("\(Int(progress * 100))%").font(.system(size: 10, weight: .bold)); Text("GOAL").font(.system(size: 6)).foregroundStyle(.secondary) }
        }
        .frame(width: 48, height: 48).padding(.bottom, 8)
    }

    private var chartData: [ActivityPoint] {
        let rawData: [(label: String, count: Int)]
        switch selectedTab {
        case 0: rawData = storage.getTodayHourly()
        case 1: rawData = storage.getLastSevenDays()
        case 2: rawData = storage.getLastSixMonths()
        default: rawData = []
        }; return rawData.map { ActivityPoint(label: $0.label, count: $0.count) }
    }
    
    private func shareStats() {
        let badge = storage.getProductivityBadge()
        let card = ShareCard(count: currentMainCount, label: currentLabel, theme: appTheme, topApps: storage.getTopApps(limit: 3), streak: storage.getCurrentStreak(), badge: badge.label, badgeColor: badge.color)
        let renderer = ImageRenderer(content: card); renderer.scale = 3.0
        if let image = renderer.nsImage { let picker = NSSharingServicePicker(items: [image]); picker.show(relativeTo: NSRect.zero, of: NSApp.keyWindow?.contentView ?? NSView(), preferredEdge: NSRectEdge.minY) }
    }
    
    private func exportCSV() {
        var csvString = "Date,Count\n"
        let sortedKeys = storage.dailyStats.keys.sorted(by: >); for key in sortedKeys { csvString += "\(key),\(storage.dailyStats[key] ?? 0)\n" }
        let savePanel = NSSavePanel(); savePanel.allowedContentTypes = [.commaSeparatedText]; savePanel.nameFieldStringValue = "typesteps_export.csv"
        savePanel.begin { result in if result == .OK, let url = savePanel.url { try? csvString.write(to: url, atomically: true, encoding: .utf8) } }
    }
}

struct InsightRow: View {
    let label: String; let value: String; let icon: String
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon).font(.system(size: 14)).foregroundStyle(Color(red: 99/255, green: 102/255, blue: 241/255)).frame(width: 24)
            VStack(alignment: .leading, spacing: 2) { Text(label).font(.system(size: 9, weight: .bold)).foregroundStyle(.secondary); Text(value).font(.system(size: 18, weight: .semibold, design: .rounded)) }
        }
    }
}

struct HighlightCard: View {
    let title: String; let subtitle: String; let value: String; let icon: String; let color: Color
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack { Image(systemName: icon).font(.system(size: 10, weight: .bold)).foregroundStyle(color); Text(title).font(.system(size: 8, weight: .black)).kerning(1).foregroundStyle(.secondary) }
            VStack(alignment: .leading, spacing: 0) { Text(value).font(.system(size: 16, weight: .bold, design: .rounded)); Text(subtitle).font(.system(size: 9)).foregroundStyle(.secondary) }
        }
        .padding(12).frame(maxWidth: .infinity, alignment: .leading).background(color.opacity(0.1)).clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct ShareCard: View {
    let count: Int; let label: String; let theme: Int; let topApps: [(name: String, count: Int)]; let streak: Int; let badge: String; let badgeColor: Color
    private let accent = Color(red: 99/255, green: 102/255, blue: 241/255)
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Image(systemName: "keyboard").font(.system(size: 24, weight: .bold)).foregroundStyle(accent)
                Text("TypeSteps").font(.system(size: 20, weight: .black, design: .rounded))
                Spacer()
                Text(badge).font(.system(size: 8, weight: .black)).foregroundStyle(.white).padding(.horizontal, 8).padding(.vertical, 4).background(badgeColor).clipShape(Capsule())
            }
            .padding(.bottom, 40)
            HStack(alignment: .lastTextBaseline, spacing: 24) {
                VStack(alignment: .leading, spacing: 4) { Text("\(count)").font(.system(size: 72, weight: .bold, design: .rounded)); Text(label.uppercased()).font(.system(size: 12, weight: .semibold)).kerning(2).foregroundStyle(.secondary) }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) { Text("\(streak)").font(.system(size: 32, weight: .bold, design: .rounded)); Text("DAY STREAK").font(.system(size: 8, weight: .black)).foregroundStyle(.secondary) }
            }
            .padding(.bottom, 48)
            if !topApps.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("ACTIVITY DISTRIBUTION").font(.system(size: 9, weight: .bold)).kerning(1.5).foregroundStyle(.secondary)
                    ForEach(topApps, id: \.name) { app in HStack { Text(app.name).font(.system(size: 13, weight: .medium)); Spacer(); Text("\(app.count)").font(.system(size: 13, design: .monospaced)).foregroundStyle(accent) } }
                }
                .padding(24).background(accent.opacity(0.05)).clipShape(RoundedRectangle(cornerRadius: 16))
            }
            Spacer()
            HStack {
                VStack(alignment: .leading, spacing: 2) { Text("TRACKED ON MACOS").font(.system(size: 8, weight: .bold)).foregroundStyle(.secondary); Text("falakgala.dev/typesteps").font(.system(size: 10, weight: .medium)) }
                Spacer()
                Image(systemName: "applelogo").font(.system(size: 16)).foregroundStyle(.secondary)
            }
        }
        .padding(48).frame(width: 500, height: 600).background(theme == 1 ? Color.white : Color(red: 9/255, green: 9/255, blue: 11/255)).foregroundStyle(theme == 1 ? .black : .white)
    }
}
