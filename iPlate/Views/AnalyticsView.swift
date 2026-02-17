//
//  AnalyticsView.swift
//  iPlate
//
//  Created by Lukesh D on 26/01/26.
//

import SwiftUI
import Charts

struct AnalyticsView: View {
    @Environment(\.dismiss) var dismiss
    
    // Calorie chart data
    @State private var calorieChartData: [CalorieDataPoint] = []
    @State private var calorieTimePeriod: TimePeriod = .week
    @State private var caloriePeriodLabel: String = ""
    
    // Macros data
    @State private var macrosTimePeriod: TimePeriod = .week
    @State private var proteinPercent: Double = 0
    @State private var carbsPercent: Double = 0
    @State private var fatsPercent: Double = 0
    @State private var fiberPercent: Double = 0
    
    // Weight logs data
    @State private var weightLogs: [WeightDataPoint] = []
    @State private var selectedWeightPoint: WeightDataPoint?
    
    // Loading states
    @State private var isLoadingCalories = false
    @State private var isLoadingMacros = false
    @State private var isLoadingWeight = false
    
    enum TimePeriod: String, CaseIterable {
        case week = "Week"
        case month = "Month"
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Analytics")
                    .font(.title.bold())
                
                Spacer()
            }
            .padding(.horizontal)
            .padding(.top, 8)
            .padding(.bottom, 12)
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    // Calorie Chart Card
                    calorieChartCard
                    
                    // Macros Card
                    macrosCard
                    
                    // Suggestion Card
                    suggestionCard
                    
                    // Weight Chart Card
                    weightChartCard
                    
                    Spacer().frame(height: 100)
                }
                .padding(.horizontal)
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationBarHidden(true)
        .task {
            await loadAllData()
        }
        .onChange(of: calorieTimePeriod) { _, _ in
            Task { await loadCalorieData() }
        }
        .onChange(of: macrosTimePeriod) { _, _ in
            Task { await loadMacrosData() }
        }
    }
    
    // MARK: - Calorie Chart Card
    private var calorieChartCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Calorie")
                    .font(.title2.bold())
                
                Spacer()
                
                timePeriodPicker(selection: $calorieTimePeriod)
            }
            
            if isLoadingCalories {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .frame(height: 200)
            } else {
                Chart(calorieChartData) { point in
                    LineMark(
                        x: .value("Date", point.dateLabel),
                        y: .value("Calories", point.calories)
                    )
                    .foregroundStyle(Color.purple.opacity(0.7))
                    .interpolationMethod(.catmullRom)
                    
                    PointMark(
                        x: .value("Date", point.dateLabel),
                        y: .value("Calories", point.calories)
                    )
                    .foregroundStyle(Color.purple)
                    .symbolSize(30)
                }
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 7))
                }
                .frame(height: 220)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
        )
    }
    
    // MARK: - Macros Card
    private var macrosCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Macros")
                    .font(.title2.bold())
                
                Spacer()
                
                timePeriodPicker(selection: $macrosTimePeriod)
            }
            
            if isLoadingMacros {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .frame(height: 200)
            } else {
                // Pie Chart
                HStack {
                    Spacer()
                    pieChart
                        .frame(width: 180, height: 180)
                    Spacer()
                }
                
                // Legend
                macrosLegend
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
        )
    }
    
    // MARK: - Pie Chart
    private var pieChart: some View {
        let data: [(String, Double, Color)] = [
            ("Protein", proteinPercent, Color.orange.opacity(0.7)),
            ("Carbs", carbsPercent, Color.green.opacity(0.6)),
            ("Fats", fatsPercent, Color.pink.opacity(0.5)),
            ("Fiber", fiberPercent, Color.cyan.opacity(0.5))
        ]
        
        let total = data.reduce(0) { $0 + $1.1 }
        
        return GeometryReader { geo in
            ZStack {
                if total > 0 {
                    ForEach(0..<data.count, id: \.self) { index in
                        let startAngle = startAngle(for: index, data: data, total: total)
                        let endAngle = endAngle(for: index, data: data, total: total)
                        
                        PieSlice(startAngle: startAngle, endAngle: endAngle)
                            .fill(data[index].2)
                    }
                } else {
                    Circle()
                        .fill(Color.gray.opacity(0.2))
                }
            }
        }
    }
    
    private func startAngle(for index: Int, data: [(String, Double, Color)], total: Double) -> Angle {
        var angle: Double = -90
        for i in 0..<index {
            angle += (data[i].1 / total) * 360
        }
        return .degrees(angle)
    }
    
    private func endAngle(for index: Int, data: [(String, Double, Color)], total: Double) -> Angle {
        var angle: Double = -90
        for i in 0...index {
            angle += (data[i].1 / total) * 360
        }
        return .degrees(angle)
    }
    
    // MARK: - Macros Legend
    private var macrosLegend: some View {
        let columns = [
            GridItem(.flexible()),
            GridItem(.flexible())
        ]
        
        return LazyVGrid(columns: columns, spacing: 16) {
            macroLegendItem(color: .orange.opacity(0.7), name: "Protein", value: proteinPercent)
            macroLegendItem(color: .green.opacity(0.6), name: "Carbs", value: carbsPercent)
            macroLegendItem(color: .pink.opacity(0.5), name: "Fats", value: fatsPercent)
            macroLegendItem(color: .cyan.opacity(0.5), name: "Fiber", value: fiberPercent)
        }
    }
    
    private func macroLegendItem(color: Color, name: String, value: Double) -> some View {
        HStack(spacing: 8) {
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text("\(Int(value))%")
                    .font(.title3.bold())
            }
            
            Spacer()
        }
    }
    
    // MARK: - Suggestion Card
    private var suggestionCard: some View {
        HStack(spacing: 12) {
            Image(systemName: "lightbulb")
                .font(.title2)
                .foregroundColor(.orange)
            
            Text("A little more protein could give your progress a great push! Think lean meats, legumes, or eggs.")
                .font(.subheadline)
                .foregroundColor(.brown)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.yellow.opacity(0.2))
        )
    }
    
    // MARK: - Weight Chart Card
    private var weightChartCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Weight")
                .font(.title2.bold())
            
            if isLoadingWeight {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .frame(height: 150)
            } else if weightLogs.isEmpty {
                Text("No weight logs recorded")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 150)
            } else {
                Chart(weightLogs) { point in
                    LineMark(
                        x: .value("Date", point.date),
                        y: .value("Weight", point.weight)
                    )
                    .foregroundStyle(Color.purple.opacity(0.7))
                    .interpolationMethod(.catmullRom)
                    
                    PointMark(
                        x: .value("Date", point.date),
                        y: .value("Weight", point.weight)
                    )
                    .foregroundStyle(Color.purple)
                    .symbolSize(40)
                    .annotation(position: .top) {
                        if let selected = selectedWeightPoint, selected.id == point.id {
                            VStack(spacing: 2) {
                                Text("\(Int(point.weight))kgs")
                                    .font(.caption.bold())
                                Text(point.monthLabel)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            .padding(8)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color(.systemBackground))
                                    .shadow(radius: 4)
                            )
                        }
                    }
                }
                .chartYScale(domain: weightYAxisDomain)
                .chartYAxis {
                    AxisMarks(position: .leading, values: .automatic(desiredCount: 4))
                }
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 5))
                }
                .chartOverlay { proxy in
                    GeometryReader { geo in
                        Rectangle()
                            .fill(Color.clear)
                            .contentShape(Rectangle())
                            .onTapGesture { location in
                                selectWeightPoint(at: location, proxy: proxy, geo: geo)
                            }
                    }
                }
                .frame(height: 180)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
        )
    }
    
    private var weightYAxisDomain: ClosedRange<Double> {
        guard !weightLogs.isEmpty else { return 0...100 }
        let weights = weightLogs.map { $0.weight }
        let minW = (weights.min() ?? 50) - 2
        let maxW = (weights.max() ?? 80) + 2
        return minW...maxW
    }
    
    private func selectWeightPoint(at location: CGPoint, proxy: ChartProxy, geo: GeometryProxy) {
        guard let plotFrame = proxy.plotFrame else { return }
        let xPosition = location.x - geo[plotFrame].origin.x
        
        guard let date: Date = proxy.value(atX: xPosition) else { return }
        
        // Find closest point
        if let closest = weightLogs.min(by: {
            abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date))
        }) {
            selectedWeightPoint = closest
        }
    }
    
    // MARK: - Time Period Picker
    private func timePeriodPicker(selection: Binding<TimePeriod>) -> some View {
        HStack(spacing: 0) {
            ForEach(TimePeriod.allCases, id: \.self) { period in
                Button(action: { selection.wrappedValue = period }) {
                    Text(period.rawValue)
                        .font(.subheadline.weight(.medium))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            selection.wrappedValue == period
                                ? Color.orange.opacity(0.2)
                                : Color.clear
                        )
                        .foregroundColor(
                            selection.wrappedValue == period
                                ? .orange
                                : .primary
                        )
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    
    // MARK: - Data Loading
    private func loadAllData() async {
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await loadCalorieData() }
            group.addTask { await loadMacrosData() }
            group.addTask { await loadWeightData() }
        }
    }
    
    private func loadCalorieData() async {
        await MainActor.run { isLoadingCalories = true }
        
        await withCheckedContinuation { continuation in
            let completion: (Result<[String: Any], Error>) -> Void = { result in
                DispatchQueue.main.async {
                    self.isLoadingCalories = false
                    
                    switch result {
                    case .success(let json):
                        self.parseCalorieData(json)
                    case .failure(let error):
                        print("Calorie data error: \(error)")
                        self.calorieChartData = []
                    }
                    continuation.resume()
                }
            }
            
            if calorieTimePeriod == .week {
                MealService.shared.fetchWeeklyCalories(completion: completion)
            } else {
                MealService.shared.fetchMonthlyCalories(completion: completion)
            }
        }
    }
    
    private func parseCalorieData(_ json: [String: Any]) {
        guard let dailyCalories = json["daily_calories"] as? [[String: Any]] else {
            calorieChartData = []
            return
        }
        
        if let period = json["period"] as? String {
            caloriePeriodLabel = period
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        let displayFormatter = DateFormatter()
        displayFormatter.dateFormat = calorieTimePeriod == .week ? "d MMM" : "d MMM"
        
        var points: [CalorieDataPoint] = []
        
        for item in dailyCalories {
            guard let dateStr = item["date"] as? String,
                  let calories = item["calories"] as? Double,
                  let date = dateFormatter.date(from: dateStr) else { continue }
            
            let label = displayFormatter.string(from: date)
            points.append(CalorieDataPoint(date: date, dateLabel: label, calories: calories))
        }
        
        // Sort by date and take appropriate sample for display
        points.sort { $0.date < $1.date }
        
        if calorieTimePeriod == .month && points.count > 8 {
            // Sample every few days for monthly view
            let step = points.count / 7
            var sampled: [CalorieDataPoint] = []
            for i in stride(from: 0, to: points.count, by: max(step, 1)) {
                sampled.append(points[i])
            }
            calorieChartData = sampled
        } else {
            calorieChartData = points
        }
    }
    
    private func loadMacrosData() async {
        await MainActor.run { isLoadingMacros = true }
        
        await withCheckedContinuation { continuation in
            let completion: (Result<[String: Any], Error>) -> Void = { result in
                DispatchQueue.main.async {
                    self.isLoadingMacros = false
                    
                    switch result {
                    case .success(let json):
                        self.parseMacrosData(json)
                    case .failure(let error):
                        print("Macros data error: \(error)")
                        self.resetMacros()
                    }
                    continuation.resume()
                }
            }
            
            if macrosTimePeriod == .week {
                MealService.shared.fetchWeeklySummary(completion: completion)
            } else {
                MealService.shared.fetchMonthlySummary(completion: completion)
            }
        }
    }
    
    private func parseMacrosData(_ json: [String: Any]) {
        guard let summary = json["total_summary"] as? [String: Any] else {
            resetMacros()
            return
        }
        
        let protein = summary["protein"] as? Double ?? 0
        let carbs = summary["carbs"] as? Double ?? 0
        let fat = summary["fat"] as? Double ?? 0
        let fiber = summary["fiber"] as? Double ?? 0
        
        let total = protein + carbs + fat + fiber
        
        if total > 0 {
            proteinPercent = (protein / total) * 100
            carbsPercent = (carbs / total) * 100
            fatsPercent = (fat / total) * 100
            fiberPercent = (fiber / total) * 100
        } else {
            resetMacros()
        }
    }
    
    private func resetMacros() {
        proteinPercent = 0
        carbsPercent = 0
        fatsPercent = 0
        fiberPercent = 0
    }
    
    private func loadWeightData() async {
        await MainActor.run { isLoadingWeight = true }
        
        await withCheckedContinuation { continuation in
            MealService.shared.fetchWeightLogs { result in
                DispatchQueue.main.async {
                    self.isLoadingWeight = false
                    
                    switch result {
                    case .success(let json):
                        self.parseWeightData(json)
                    case .failure(let error):
                        print("Weight data error: \(error)")
                        self.weightLogs = []
                    }
                    continuation.resume()
                }
            }
        }
    }
    
    private func parseWeightData(_ json: [String: Any]) {
        guard let weights = json["weights"] as? [[String: Any]] else {
            weightLogs = []
            return
        }
        
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        let fallbackFormatter = ISO8601DateFormatter()
        fallbackFormatter.formatOptions = [.withInternetDateTime]
        
        let monthFormatter = DateFormatter()
        monthFormatter.dateFormat = "MMMM"
        
        var points: [WeightDataPoint] = []
        
        for item in weights {
            guard let id = item["id"] as? String,
                  let weightKg = item["weight_kg"] as? Double,
                  let recordedAt = item["recorded_at"] as? String else { continue }
            
            var date: Date?
            date = isoFormatter.date(from: recordedAt) ?? fallbackFormatter.date(from: recordedAt)
            
            guard let validDate = date else { continue }
            
            let monthLabel = monthFormatter.string(from: validDate)
            points.append(WeightDataPoint(id: id, date: validDate, weight: weightKg, monthLabel: monthLabel))
        }
        
        // Sort by date ascending
        points.sort { $0.date < $1.date }
        weightLogs = points
    }
}

// MARK: - Data Models
struct CalorieDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let dateLabel: String
    let calories: Double
}

struct WeightDataPoint: Identifiable {
    let id: String
    let date: Date
    let weight: Double
    let monthLabel: String
}

// MARK: - Pie Slice Shape
struct PieSlice: Shape {
    var startAngle: Angle
    var endAngle: Angle
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        
        path.move(to: center)
        path.addArc(center: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: false)
        path.closeSubpath()
        
        return path
    }
}

#Preview {
    AnalyticsView()
}
