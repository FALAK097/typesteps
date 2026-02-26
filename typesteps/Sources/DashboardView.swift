import SwiftUI
import Charts
internal import UniformTypeIdentifiers

struct AppIconView: View {
    let bundleId: String?
    let size: CGFloat
    let borderColor: Color
    
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
        .background(Color.white.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: size * 0.25))
        .overlay(RoundedRectangle(cornerRadius: size * 0.25).stroke(borderColor.opacity(0.5), lineWidth: 0.5))
        .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
    }
}

struct DashboardView: View {
    @ObservedObject var storage = StorageManager.shared
    @ObservedObject var wakaTime = WakaTimeManager.shared
    @State private var selectedTab = 0 
    @AppStorage("app_theme_id") private var appThemeId = 0 
    @AppStorage("daily_goal") private var dailyGoal = 5000 
    
     @State private var isShowingWakaKey = false
     @State private var showWakaInfo = false
     @State private var hoveredAction: String?
     @State private var rawSelectedDate: String?
     @State private var hoveredDay: String?
     @State private var hoveredCount: Int?
     @State private var showThemePicker = false
     @State private var hoveredThemeId: Int? = nil
     
     @State private var showDataOptions = false
    
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var showAlert = false
    @State private var alertAction: (() -> Void)?
    
    private var theme: AppTheme { AppTheme.themes.first { $0.id == appThemeId } ?? AppTheme.themes[0] }
    private var previewTheme: AppTheme {
        if let hovered = hoveredThemeId {
            return AppTheme.themes.first { $0.id == hovered } ?? theme
        }
        return theme
    }
     private var accent: Color { previewTheme.accent }
     
     private var bgMain: Color { previewTheme.mainBg }
     private var bgSecondary: Color { previewTheme.secondaryBg }
     private var borderColor: Color { previewTheme.border }
     private var textColor: Color { previewTheme.text }
     private var secondaryTextColor: Color { previewTheme.secondaryText }
    
    private let lightThemeIds = [0, 12, 13, 14, 15, 17, 18, 19, 20, 21, 22, 23]
    
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
                                    leftColumn; rightColumn
                                }
                            } else {
                                VStack(alignment: .leading, spacing: 40) {
                                    leftColumn; rightColumn
                                }
                            }
                        }
                        .padding(geo.size.width > 900 ? 40 : 24)
                    }
                }
             }
             .foregroundStyle(textColor)
             .colorScheme(lightThemeIds.contains(theme.id) ? .light : .dark)
             .animation(.easeOut(duration: 0.15), value: previewTheme.id)
         }
         .tint(accent)
         .alert(alertTitle, isPresented: $showAlert) {
            if let action = alertAction {
                Button("Cancel", role: .cancel) { alertAction = nil }
                Button("Reset", role: .destructive) { action(); alertAction = nil }
            } else {
                Button("OK", role: .cancel) { }
            }
        } message: {
            Text(alertMessage)
        }
    }
    
    private var header: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("TypeSteps").font(.system(size: 14, weight: .semibold))
                    if let hoveredAction { Text(hoveredAction).font(.system(size: 8, weight: .black)).foregroundStyle(accent).transition(.opacity) }
                }
                Spacer()
                
                themeSelector
                
                HStack(spacing: 8) {
                    Button(action: shareStats) { Image(systemName: "square.and.arrow.up").font(.system(size: 11)).foregroundStyle(secondaryTextColor).frame(width: 28, height: 28).background(bgSecondary).clipShape(Circle()).overlay(Circle().stroke(borderColor, lineWidth: 1)) }
                        .buttonStyle(.plain).onHover { h in hoveredAction = h ? "SHARE SNAPSHOT" : nil }
                    Button { showDataOptions.toggle() } label: {
                        Image(systemName: "doc.text").font(.system(size: 11)).foregroundStyle(secondaryTextColor).frame(width: 28, height: 28).background(bgSecondary).clipShape(Circle()).overlay(Circle().stroke(borderColor, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                    .popover(isPresented: $showDataOptions, arrowEdge: .bottom) {
                        VStack(alignment: .leading, spacing: 4) {
                            HoverButton(title: "Backup Data", icon: "arrow.down.doc", action: { showDataOptions = false; exportJSON() })
                            HoverButton(title: "Restore Data", icon: "arrow.up.doc", action: { showDataOptions = false; importJSON() })
                            Divider().padding(.vertical, 4)
                            HoverButton(title: "Reset Data", icon: "trash", color: .red, action: { showDataOptions = false; confirmReset() })
                        }
                        .padding(8)
                        .background(bgMain)
                    }
                    .onHover { h in hoveredAction = h ? "DATA OPTIONS" : nil }
                }.padding(.trailing, 8)
                
                Picker("", selection: $selectedTab) { Text("Day").tag(0); Text("Week").tag(1); Text("Month").tag(2) }
                    .pickerStyle(.segmented)
                    .frame(width: 200)
                    .onHover { h in hoveredAction = h ? "SWITCH VIEW" : nil }
            }
     .padding(.horizontal, 24).padding(.vertical, 12).animation(.easeInOut(duration: 0.2), value: hoveredAction)
             Divider().background(borderColor).opacity(0.5)
         }
     }
     
     private var themeSelector: some View {
         Button {
             showThemePicker.toggle()
         } label: {
             HStack(spacing: 8) {
                 Circle().fill(previewTheme.accent).frame(width: 8, height: 8)
                 Text(previewTheme.name).font(.system(size: 10, weight: .bold))
             }
             .padding(.horizontal, 12).padding(.vertical, 8)
             .frame(width: 120, alignment: .center)
             .background(previewTheme.secondaryBg)
             .clipShape(RoundedRectangle(cornerRadius: 8))
             .overlay(RoundedRectangle(cornerRadius: 8).stroke(previewTheme.border, lineWidth: 1))
         }
         .buttonStyle(.plain)
         .onHover { h in hoveredAction = h ? "CHANGE THEME" : nil }
         .padding(.trailing, 8)
         .popover(isPresented: $showThemePicker, arrowEdge: .top) {
             themePickerPopover
         }
     }
     
     private var themePickerPopover: some View {
         ZStack {
             bgMain.ignoresSafeArea()
             
             VStack(alignment: .leading, spacing: 16) {
                 Text("THEME")
                     .font(.system(size: 10, weight: .medium))
                     .kerning(1.5)
                     .foregroundStyle(secondaryTextColor)
                 
                 VStack(alignment: .leading, spacing: 12) {
                     Text("Light")
                         .font(.system(size: 9, weight: .medium))
                         .kerning(0.8)
                         .foregroundStyle(secondaryTextColor)
                         .padding(.leading, 4)
                     
                     LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                         ForEach(AppTheme.themes.filter { lightThemeIds.contains($0.id) }) { t in
                             themeOption(t)
                         }
                     }
                 }
                 
                 VStack(alignment: .leading, spacing: 12) {
                     Text("Dark")
                         .font(.system(size: 9, weight: .medium))
                         .kerning(0.8)
                         .foregroundStyle(secondaryTextColor)
                         .padding(.leading, 4)
                     
                     LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                         ForEach(AppTheme.themes.filter { !lightThemeIds.contains($0.id) }) { t in
                             themeOption(t)
                         }
                     }
                 }
             }
             .padding(16)
             .foregroundStyle(textColor)
         }
         .frame(width: 280)
         .colorScheme(lightThemeIds.contains(previewTheme.id) ? .light : .dark)
     }
     
     private func themeOption(_ t: AppTheme) -> some View {
         let isSelected = appThemeId == t.id
         let isHovered = hoveredThemeId == t.id
         
         return Button {
             appThemeId = t.id
             showThemePicker = false
         } label: {
             VStack(spacing: 8) {
                 HStack(spacing: 8) {
                     VStack(spacing: 3) {
                         RoundedRectangle(cornerRadius: 1.5)
                             .fill(t.mainBg)
                             .frame(height: 8)
                             .overlay(RoundedRectangle(cornerRadius: 1.5).stroke(borderColor.opacity(0.3), lineWidth: 0.5))
                         
                         HStack(spacing: 2) {
                             RoundedRectangle(cornerRadius: 1)
                                 .fill(t.accent)
                                 .frame(height: 4)
                             RoundedRectangle(cornerRadius: 1)
                                 .fill(t.accent.opacity(0.4))
                                 .frame(height: 4)
                             RoundedRectangle(cornerRadius: 1)
                                 .fill(t.accent.opacity(0.2))
                                 .frame(height: 4)
                         }
                     }
                     
                      VStack(alignment: .leading, spacing: 0) {
                          Text(t.name)
                              .font(.system(size: 10, weight: isSelected ? .semibold : .regular))
                              .foregroundStyle(t.text)
                              .lineLimit(1)
                      }
                     
                     Spacer()
                     
                     if isSelected {
                         Image(systemName: "checkmark.circle.fill")
                             .font(.system(size: 12, weight: .semibold))
                             .foregroundStyle(t.accent)
                     }
                 }
                 .padding(10)
                 .background(isHovered ? t.secondaryBg : t.mainBg)
                 .clipShape(RoundedRectangle(cornerRadius: 10))
                 .overlay(
                     RoundedRectangle(cornerRadius: 10)
                         .stroke(
                             isSelected ? t.accent :
                             (isHovered ? borderColor.opacity(0.5) : borderColor.opacity(0.2)),
                             lineWidth: isSelected ? 1.5 : 1
                         )
                 )
              }
          }
          .buttonStyle(.plain)
          .onHover { hovering in
              withAnimation(.easeOut(duration: 0.15)) {
                  hoveredThemeId = hovering ? t.id : nil
              }
          }
      }
    
    private var leftColumn: some View {
        VStack(alignment: .leading, spacing: 48) {
            VStack(alignment: .leading, spacing: 32) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .lastTextBaseline) {
                        Text(currentLabel.uppercased()).font(.system(size: 10, weight: .medium)).kerning(1.5).foregroundStyle(secondaryTextColor)
                        Spacer(); Text(dateSubtitle).font(.system(size: 10)).foregroundStyle(secondaryTextColor)
                    }
                    HStack(alignment: .bottom) {
                        Text("\(currentMainCount)").font(.system(size: 56, weight: .bold)).contentTransition(.numericText())
                        if selectedTab == 0 { Spacer(); goalProgressCircle }
                    }
                }
                
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("ACTIVITY TREND").font(.system(size: 10, weight: .medium)).kerning(1.5).foregroundStyle(secondaryTextColor)
                        if let selectedValue = selectedPointValue { Spacer(); Text("\(selectedValue) letters").font(.system(size: 10, weight: .bold)).foregroundStyle(accent) }
                    }
                    Chart {
                        ForEach(chartData) { point in
                            if selectedTab == 0 {
                                AreaMark(x: .value("T", point.label), y: .value("C", point.count))
                                    .interpolationMethod(.monotone)
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [accent.opacity(0.35), accent.opacity(0.02)],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                LineMark(x: .value("T", point.label), y: .value("C", point.count))
                                    .interpolationMethod(.monotone)
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [accent, accent.opacity(0.8)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
                                PointMark(x: .value("T", point.label), y: .value("C", point.count))
                                    .interpolationMethod(.monotone)
                                    .foregroundStyle(accent)
                                    .symbolSize(selectedPointValue != nil && rawSelectedDate == point.label ? 100 : 40)
                            } else {
                                BarMark(x: .value("L", point.label), y: .value("C", point.count))
                                    .foregroundStyle(accent.gradient)
                                    .cornerRadius(2)
                            }
                        }
                        if let rawSelectedDate { 
                            RuleMark(x: .value("Selected", rawSelectedDate))
                                .foregroundStyle(secondaryTextColor.opacity(0.25))
                                .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                        }
                    }
                    .frame(height: 200)
                    .chartYAxis { AxisMarks(position: .leading) { 
                        AxisGridLine()
                            .foregroundStyle(borderColor.opacity(0.25))
                        AxisValueLabel()
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundStyle(secondaryTextColor) 
                    } }
                    .chartXAxis { if selectedTab == 0 { AxisMarks(values: ["00:00", "04:00", "08:00", "12:00", "16:00", "20:00"]) { _ in 
                        AxisGridLine()
                            .foregroundStyle(borderColor.opacity(0.25))
                        AxisValueLabel()
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundStyle(secondaryTextColor) 
                    } }
                        else { AxisMarks { _ in 
                        AxisGridLine()
                            .foregroundStyle(borderColor.opacity(0.25))
                        AxisValueLabel()
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundStyle(secondaryTextColor) 
                    } } }
                    .chartXSelection(value: $rawSelectedDate)
                    .animation(.easeOut(duration: 0.35), value: selectedTab)
                }
            }
            
            HStack(alignment: .top, spacing: 48) {
                VStack(alignment: .leading, spacing: 48) { heatmapSection; journeySection }.frame(maxWidth: .infinity)
                topAppsSection.frame(width: 350)
            }
        }
    }
    
    private var journeySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("THE WORLD TOUR").font(.system(size: 10, weight: .medium)).kerning(1.5).foregroundStyle(secondaryTextColor)
            VStack(spacing: 12) {
                let stats = storage.getLibraryStats()
                ForEach(stats, id: \.milestone) { item in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(item.milestone).font(.system(size: 11, weight: .semibold))
                            Spacer()
                            if item.progress >= 1.0 { Text("\(Int(item.iterations))x completed").font(.system(size: 9, weight: .bold)).foregroundStyle(.green) }
                            else { Text("\(Int(item.progress * 100))%").font(.system(size: 9)).foregroundStyle(secondaryTextColor) }
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
                Text("INSIGHTS").font(.system(size: 10, weight: .medium)).kerning(1.5).foregroundStyle(secondaryTextColor)
                InsightRow(label: "BEST DAY", value: "\(storage.getBestDay().count)", icon: "arrow.up.right", color: accent, secondaryTextColor: secondaryTextColor)
                InsightRow(label: "STREAK", value: "\(storage.getCurrentStreak()) days", icon: "flame", color: accent, secondaryTextColor: secondaryTextColor)
                InsightRow(label: "PEAK HOUR", value: String(format: "%02d:00", storage.getPeakHour().hour), icon: "clock", color: accent, secondaryTextColor: secondaryTextColor)
                InsightRow(label: "AVG / HOUR", value: "\(storage.getAveragePerHour())", icon: "bolt", color: accent, secondaryTextColor: secondaryTextColor)
                InsightRow(label: "DAILY GOAL", value: "\(dailyGoal)", icon: "target", color: accent, secondaryTextColor: secondaryTextColor)
                HStack { Slider(value: Binding(get: { Double(dailyGoal) }, set: { dailyGoal = Int($0) }), in: 1000...20000, step: 500).tint(accent); Text("\(dailyGoal/1000)k").font(.system(size: 10, design: .monospaced)).foregroundStyle(secondaryTextColor) }.padding(.top, -12)
            }
            highlightsSection; wakaTimeSection
        }.frame(maxWidth: 350)
    }
    
    private var wakaTimeSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("WAKATIME").font(.system(size: 10, weight: .medium)).kerning(1.5).foregroundStyle(secondaryTextColor)
                Button {
                    showWakaInfo.toggle()
                } label: {
                    Image(systemName: "info.circle")
                        .font(.system(size: 10))
                        .foregroundStyle(accent)
                }
                .buttonStyle(.plain)
                 .popover(isPresented: $showWakaInfo, arrowEdge: .top) {
                     VStack(alignment: .leading, spacing: 12) {
                         VStack(alignment: .leading, spacing: 8) {
                             Text("What is WakaTime?").font(.system(size: 11, weight: .bold)).foregroundStyle(textColor)
                             Text("Automatically tracks your coding activity to measure productivity and focus.").font(.system(size: 10)).foregroundStyle(secondaryTextColor)
                         }
                         
                         Divider().frame(height: 1).background(borderColor.opacity(0.5))
                         
                         VStack(alignment: .leading, spacing: 8) {
                             HStack(alignment: .top, spacing: 8) {
                                 Text("●").font(.system(size: 8)).foregroundStyle(accent)
                                 VStack(alignment: .leading, spacing: 2) {
                                     Text("ACTIVE").font(.system(size: 9, weight: .bold)).foregroundStyle(textColor)
                                     Text("Total time spent coding").font(.system(size: 9)).foregroundStyle(secondaryTextColor)
                                 }
                             }
                             HStack(alignment: .top, spacing: 8) {
                                 Text("●").font(.system(size: 8)).foregroundStyle(accent)
                                 VStack(alignment: .leading, spacing: 2) {
                                     Text("DENSITY").font(.system(size: 9, weight: .bold)).foregroundStyle(textColor)
                                     Text("Keystrokes per minute (higher = more focused)").font(.system(size: 9)).foregroundStyle(secondaryTextColor)
                                 }
                             }
                         }
                         
                         Divider().frame(height: 1).background(borderColor.opacity(0.5))
                         
                         VStack(alignment: .leading, spacing: 6) {
                             Text("Get Started:").font(.system(size: 9, weight: .bold)).foregroundStyle(textColor)
                             Link("1. Get your API key from wakatime.com/api", destination: URL(string: "https://wakatime.com/api")!)
                                 .font(.system(size: 9))
                                 .foregroundStyle(accent)
                             Text("2. Paste it in the API key field below").font(.system(size: 9)).foregroundStyle(secondaryTextColor)
                         }
                     }
                     .padding(12)
                     .frame(maxWidth: 280)
                     .background(bgSecondary)
                     .cornerRadius(10)
                 }
                Spacer()
                HStack(spacing: 12) {
                    if !storage.wakaTimeApiKey.isEmpty { Link(destination: URL(string: "https://wakatime.com/dashboard")!) { Image(systemName: "arrow.up.right.square").font(.system(size: 10)).foregroundStyle(accent) } }
                    if wakaTime.isFetching { ProgressView().scaleEffect(0.5) }
                    else { Button { wakaTime.fetchTodayStats(apiKey: storage.wakaTimeApiKey) } label: { Image(systemName: "arrow.clockwise").font(.system(size: 10)) }.buttonStyle(.plain) }
                }
            }
            VStack(alignment: .leading, spacing: 12) {
                if storage.wakaTimeApiKey.isEmpty { Text("Enter API Key for density stats.").font(.system(size: 11)).foregroundStyle(secondaryTextColor) }
                else {
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 8) { HStack { Image(systemName: "clock.fill").font(.system(size: 10)).foregroundStyle(.blue); Text("ACTIVE").font(.system(size: 8, weight: .black)).foregroundStyle(secondaryTextColor) }; Text(formatWakaTime(minutes: wakaTime.totalMinutesToday)).font(.system(size: 18, weight: .bold, design: .rounded)) }
                        .padding(12).frame(maxWidth: .infinity, alignment: .leading).background(Color.blue.opacity(0.1)).clipShape(RoundedRectangle(cornerRadius: 12))
                        VStack(alignment: .leading, spacing: 8) { HStack { Image(systemName: "gauge.with.needle.fill").font(.system(size: 10)).foregroundStyle(.purple); Text("DENSITY").font(.system(size: 8, weight: .black)).foregroundStyle(secondaryTextColor) }; let density = wakaTime.totalMinutesToday > 0 ? Double(storage.getCount()) / wakaTime.totalMinutesToday : 0; Text("\(Int(density)) s/m").font(.system(size: 18, weight: .bold, design: .rounded)) }
                        .padding(12).frame(maxWidth: .infinity, alignment: .leading).background(Color.purple.opacity(0.1)).clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                HStack {
                    if isShowingWakaKey { TextField("API Key", text: $storage.wakaTimeApiKey).textFieldStyle(.plain).font(.system(size: 10, design: .monospaced)).padding(4).background(bgMain.opacity(0.5)).clipShape(RoundedRectangle(cornerRadius: 4)) }
                    else { Text(storage.wakaTimeApiKey.isEmpty ? "No Key" : "••••••••••••••••").font(.system(size: 10, design: .monospaced)).foregroundStyle(secondaryTextColor) }
                    Spacer(); Button(isShowingWakaKey ? "SAVE" : "EDIT") { isShowingWakaKey.toggle(); if !isShowingWakaKey { wakaTime.fetchTodayStats(apiKey: storage.wakaTimeApiKey) } }.font(.system(size: 9, weight: .black)).buttonStyle(.plain).foregroundStyle(accent)
                }.padding(.horizontal, 12).padding(.vertical, 10).background(bgSecondary.opacity(0.5)).clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
    }
    
    private func formatWakaTime(minutes: Double) -> String { let hrs = Int(minutes) / 60; let mins = Int(minutes) % 60; return hrs > 0 ? "\(hrs)h \(mins)m" : "\(mins)m" }
    private var highlightsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("WEEKLY HIGHLIGHTS").font(.system(size: 10, weight: .medium)).kerning(1.5).foregroundStyle(secondaryTextColor)
            HStack(spacing: 12) {
                if let mostActive = storage.getMostActiveDayThisWeek() { HighlightCard(title: "MOST ACTIVE", subtitle: mostActive.date, value: "\(mostActive.count)", icon: "bolt.fill", color: .orange, secondaryTextColor: secondaryTextColor) }
                if let quietest = storage.getQuietestDay() { HighlightCard(title: "QUIETEST", subtitle: quietest.date, value: "\(quietest.count)", icon: "leaf.fill", color: .green, secondaryTextColor: secondaryTextColor) }
            }
        }
    }
    
    private var heatmapSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("2026 CONSISTENCY").font(.system(size: 10, weight: .medium)).kerning(1.5).foregroundStyle(secondaryTextColor)
                Spacer(); if let hoveredDay, let hoveredCount { Text("\(hoveredDay): \(hoveredCount) steps").font(.system(size: 10, weight: .bold)).foregroundStyle(accent) }
                else { Text("\(storage.getTotalAllTime()) Total").font(.system(size: 10, weight: .bold)).foregroundStyle(secondaryTextColor) }
            }
            ScrollView(.horizontal, showsIndicators: false) { LazyHGrid(rows: Array(repeating: GridItem(.fixed(10), spacing: 3), count: 7), spacing: 3) { ForEach(0..<365, id: \.self) { i in heatmapCell(dayOfYear: i) } }.padding(.vertical, 4) }.frame(height: 95)
        }
    }
    
    private var topAppsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("TOP APPLICATIONS").font(.system(size: 10, weight: .medium)).kerning(1.5).foregroundStyle(secondaryTextColor)
            let topApps = storage.getTopApps(limit: 100)
            if topApps.isEmpty { Text("No app data yet").font(.system(size: 12)).foregroundStyle(secondaryTextColor) }
            else {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 8) {
                        ForEach(topApps, id: \.name) { app in
                            HStack(spacing: 12) {
                                AppIconView(bundleId: storage.appBundleMapping[app.name], size: 28, borderColor: borderColor)
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack { Text(app.name).font(.system(size: 12, weight: .bold)); Spacer(); Text("\(app.count)").font(.system(size: 11, design: .monospaced)).foregroundStyle(secondaryTextColor) }
                                    let total = storage.appStats.values.reduce(0, +); let percentage = total > 0 ? Double(app.count) / Double(total) : 0
                                    GeometryReader { barGeo in ZStack(alignment: .leading) { Capsule().fill(borderColor).frame(height: 4); Capsule().fill(accent.gradient).frame(width: barGeo.size.width * percentage, height: 4) } }.frame(height: 4)
                                }
                            }.padding(10).background(bgSecondary.opacity(0.4)).clipShape(RoundedRectangle(cornerRadius: 12)).overlay(RoundedRectangle(cornerRadius: 12).stroke(borderColor.opacity(0.5), lineWidth: 0.5))
                        }
                    }
                }
                .frame(maxHeight: 500)
            }
        }
    }
    
    private func heatmapCell(dayOfYear: Int) -> some View {
        let calendar = Calendar.current; var components = DateComponents(); components.year = 2026; components.day = dayOfYear + 1
        let date = calendar.date(from: components)!; let formatter = DateFormatter(); formatter.dateFormat = "yyyy-MM-dd"; let key = formatter.string(from: date); let count = storage.dailyStats[key] ?? 0; let intensity = min(1.0, Double(count) / Double(max(1, dailyGoal))); let isFuture = date > Date()
        return RoundedRectangle(cornerRadius: 1.5).fill(count > 0 ? accent.opacity(0.2 + intensity * 0.8) : (isFuture ? Color.clear : borderColor.opacity(0.3))).frame(width: 10, height: 10)
            .onHover { hovering in if hovering { hoveredDay = key; hoveredCount = count } else { hoveredDay = nil; hoveredCount = nil } }
            .help("\(key): \(count) letters")
    }
    
    private var currentMainCount: Int { switch selectedTab { case 0: return storage.getCount(); case 1: return storage.getWeeklyTotal(); case 2: return storage.getMonthlyTotal(); default: return 0 } }
    private var currentLabel: String { switch selectedTab { case 0: return "Letters Today"; case 1: return "This Week"; case 2: return "This Month"; default: return "" } }
    private var dateSubtitle: String {
        let formatter = DateFormatter(); let now = Date()
        switch selectedTab {
        case 0: formatter.dateFormat = "MMM d, yyyy"; return formatter.string(from: now)
        case 1: let components = Calendar.current.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now); let startOfWeek = Calendar.current.date(from: components)!; formatter.dateFormat = "MMM d"; return "\(formatter.string(from: startOfWeek)) - \(formatter.string(from: now))"
        case 2: formatter.dateFormat = "MMMM yyyy"; return formatter.string(from: now); default: return ""
        }
    }
    
    private var selectedPointValue: Int? { guard let rawSelectedDate else { return nil }; return chartData.first(where: { $0.label == rawSelectedDate })?.count }
    private var goalProgressCircle: some View {
        let progress = min(1.0, Double(storage.getCount()) / Double(max(1, dailyGoal)))
        return ZStack { Circle().stroke(borderColor, lineWidth: 4); Circle().trim(from: 0, to: progress).stroke(accent, style: StrokeStyle(lineWidth: 4, lineCap: .round)).rotationEffect(.degrees(-90)).animation(.easeOut(duration: 1.0), value: progress)
            VStack(spacing: 2) { Text("\(Int(progress * 100))%").font(.system(size: 10, weight: .bold)); Text("GOAL").font(.system(size: 6)).foregroundStyle(secondaryTextColor) }
        }.frame(width: 48, height: 48).padding(.bottom, 8)
    }
    
    private var chartData: [ActivityPoint] {
        let rawData: [(label: String, count: Int)]
        switch selectedTab { case 0: rawData = storage.getTodayHourly(); case 1: rawData = storage.getLastSevenDays(); case 2: rawData = storage.getLastSixMonths(); default: rawData = [] }
        return rawData.map { ActivityPoint(label: $0.label, count: $0.count) }
    }
    
    private func shareStats() {
        let badge = storage.getProductivityBadge()
        let topCat = storage.getCategoryStats().first?.category.rawValue ?? "Other"
        let card = ShareCard(count: currentMainCount, label: currentLabel, themeId: appThemeId, topApps: storage.getTopApps(limit: 3), streak: storage.getCurrentStreak(), badge: badge.label, badgeColor: badge.color, topCategory: topCat)
        let renderer = ImageRenderer(content: card); renderer.scale = 3.0
        if let image = renderer.nsImage { let picker = NSSharingServicePicker(items: [image]); picker.show(relativeTo: NSRect.zero, of: NSApp.keyWindow?.contentView ?? NSView(), preferredEdge: NSRectEdge.minY) }
    }
    
    private func exportJSON() {
        guard let data = storage.exportData() else {
            alertTitle = "Export Failed"; alertMessage = "Could not generate backup data."; showAlert = true
            return
        }
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.json]
        savePanel.nameFieldStringValue = "typesteps_backup.json"
        savePanel.begin { result in
            if result == .OK, let url = savePanel.url {
                do {
                    try data.write(to: url)
                    alertTitle = "Backup Successful"; alertMessage = "Your data has been safely saved."; showAlert = true
                } catch {
                    alertTitle = "Export Failed"; alertMessage = error.localizedDescription; showAlert = true
                }
            }
        }
    }

    private func importJSON() {
        let openPanel = NSOpenPanel()
        openPanel.allowedContentTypes = [.json]
        openPanel.begin { result in
            if result == .OK, let url = openPanel.url {
                do {
                    let data = try Data(contentsOf: url)
                    if storage.importData(from: data) {
                        alertTitle = "Restore Successful"; alertMessage = "Your data has been restored."; alertAction = nil; showAlert = true
                    } else {
                        alertTitle = "Restore Failed"; alertMessage = "The file format was invalid."; alertAction = nil; showAlert = true
                    }
                } catch {
                    alertTitle = "Restore Failed"; alertMessage = error.localizedDescription; alertAction = nil; showAlert = true
                }
            }
        }
    }
    
    private func confirmReset() {
        alertTitle = "Reset Data?"
        alertMessage = "This will permanently erase all your tracking statistics. This action cannot be undone."
        alertAction = { storage.resetStats() }
        showAlert = true
    }
}

struct HoverButton: View {
    let title: String
    let icon: String
    var color: Color = .primary
    let action: () -> Void
    @State private var isHovering = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon).font(.system(size: 12))
                Text(title).font(.system(size: 12))
                Spacer()
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(isHovering ? Color.secondary.opacity(0.1) : Color.clear)
            .cornerRadius(6)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(color)
        .onHover { isHovering = $0 }
    }
}

struct InsightRow: View {
    let label: String; let value: String; let icon: String; let color: Color; let secondaryTextColor: Color
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon).font(.system(size: 14)).foregroundStyle(color).frame(width: 24)
            VStack(alignment: .leading, spacing: 2) { Text(label).font(.system(size: 9, weight: .bold)).foregroundStyle(secondaryTextColor); Text(value).font(.system(size: 18, weight: .semibold, design: .rounded)) }
        }
    }
}

struct HighlightCard: View {
    let title: String; let subtitle: String; let value: String; let icon: String; let color: Color; let secondaryTextColor: Color
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack { Image(systemName: icon).font(.system(size: 10, weight: .bold)).foregroundStyle(color); Text(title).font(.system(size: 8, weight: .black)).kerning(1).foregroundStyle(secondaryTextColor) }
            VStack(alignment: .leading, spacing: 0) { Text(value).font(.system(size: 16, weight: .bold, design: .rounded)); Text(subtitle).font(.system(size: 9)).foregroundStyle(secondaryTextColor) }
        }.padding(12).frame(maxWidth: .infinity, alignment: .leading).background(color.opacity(0.1)).clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct ShareCard: View {
    let count: Int; let label: String; let themeId: Int; let topApps: [(name: String, count: Int)]; let streak: Int; let badge: String; let badgeColor: Color; let topCategory: String
    private var theme: AppTheme { AppTheme.themes.first { $0.id == themeId } ?? AppTheme.themes[0] }
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Image(systemName: "keyboard").font(.system(size: 24, weight: .bold)).foregroundStyle(theme.accent)
                Text("TypeSteps").font(.system(size: 20, weight: .black, design: .rounded))
                Spacer()
                Text(badge).font(.system(size: 8, weight: .black)).foregroundStyle(.white).padding(.horizontal, 8).padding(.vertical, 4).background(badgeColor).clipShape(Capsule())
            }.padding(.bottom, 40)
            HStack(alignment: .lastTextBaseline, spacing: 24) {
                VStack(alignment: .leading, spacing: 4) { Text("\(count)").font(.system(size: 72, weight: .bold, design: .rounded)); Text(label.uppercased()).font(.system(size: 12, weight: .semibold)).kerning(2).foregroundStyle(theme.secondaryText) }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) { Text("\(streak)").font(.system(size: 32, weight: .bold, design: .rounded)); Text("DAY STREAK").font(.system(size: 8, weight: .black)).foregroundStyle(theme.secondaryText) }
            }.padding(.bottom, 40)
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) { Text("TOP CATEGORY").font(.system(size: 7, weight: .black)).foregroundStyle(theme.secondaryText); Text(topCategory.uppercased()).font(.system(size: 12, weight: .bold)).foregroundStyle(theme.accent) }.frame(maxWidth: .infinity, alignment: .leading).padding(16).background(theme.accent.opacity(0.05)).clipShape(RoundedRectangle(cornerRadius: 12))
                VStack(alignment: .leading, spacing: 4) { Text("AVG INTENSITY").font(.system(size: 7, weight: .black)).foregroundStyle(theme.secondaryText); Text("\(count/12) s/h").font(.system(size: 12, weight: .bold)).foregroundStyle(theme.accent) }.frame(maxWidth: .infinity, alignment: .leading).padding(16).background(theme.accent.opacity(0.05)).clipShape(RoundedRectangle(cornerRadius: 12))
            }.padding(.bottom, 32)
            if !topApps.isEmpty {
                VStack(alignment: .leading, spacing: 10) { Text("APP BREAKDOWN").font(.system(size: 8, weight: .black)).kerning(1.5).foregroundStyle(theme.secondaryText)
                    ForEach(topApps, id: \.name) { app in HStack { Text(app.name).font(.system(size: 13, weight: .medium)); Spacer(); Text("\(app.count)").font(.system(size: 13, design: .monospaced)).foregroundStyle(theme.accent) } }
                }.padding(24).background(Color.secondary.opacity(0.05)).clipShape(RoundedRectangle(cornerRadius: 16))
            }
            Spacer()
            HStack {
                VStack(alignment: .leading, spacing: 2) { Text("TRACKED ON MACOS").font(.system(size: 8, weight: .bold)).foregroundStyle(theme.secondaryText); Text("falakgala.dev/typesteps").font(.system(size: 10, weight: .medium)) }
                Spacer(); Image(systemName: "applelogo").font(.system(size: 16)).foregroundStyle(theme.secondaryText)
            }
        }.padding(48).frame(width: 500, height: 700).background(theme.mainBg).foregroundStyle(theme.text)
    }
}
