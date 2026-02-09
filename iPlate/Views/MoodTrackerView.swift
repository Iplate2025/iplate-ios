//
//  MoodTrackerView.swift
//  iPlate
//
//  Created by Lukesh D on 26/01/26.
//

import SwiftUI

// MARK: - Mood Tracker Main View
struct MoodTrackerView: View {
    @Environment(\.dismiss) var dismiss
    @State private var currentStep = 0
    @State private var moodValues = MoodInput(calm: 1, focus: 1, energized: 1, fatigue: 1, excited:1)
    @State private var suggestions: [MoodSuggestion] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()

            VStack {
                if currentStep == 0 {
                    MoodInputView(
                        moodValues: $moodValues,
                        onContinue: {
                            currentStep = 1
                        }
                    )
                } else if currentStep == 1 {
                    MoodResultsView(
                        moodValues: moodValues,
                        predictedMood: predictMood(),
                        onContinue: {
                            submitMood()
                        }
                    )
                } else {
                    MoodSuggestionsView(
                        suggestions: suggestions,
                        isLoading: isLoading,
                        errorMessage: errorMessage,
                        onContinue: {
                            dismiss()
                        }
                    )
                }
            }
        }
    }

    private func predictMood() -> String {
        let calm = moodValues.calm
        let focus = moodValues.focus
        let energized = moodValues.energized
        let fatigue = moodValues.fatigue
        let excited = moodValues.excited

        let positiveAffect = Double(calm + focus + energized + excited) / 4.0
        let negativeAffect = Double(fatigue + (6 - calm) + (6 - focus)) / 3.0

        if positiveAffect >= 4 && negativeAffect <= 2 { return "Happy" }
        if fatigue >= 4 { return "Tired & Anxious" }
        if energized >= 4 && calm >= 4 { return "Energetic & Calm" }

        return "Balanced Mood"
    }
//    private func predictMood() -> String {
//        let calm = moodValues.calm
//        let focus = moodValues.focus
//        let energized = moodValues.energized
//        let fatigue = moodValues.fatigue
//        let excited = moodValues.excited
//
//        let positiveAffect = Double(calm + focus + energized + excited) / 4.0
//        let negativeAffect = Double(fatigue + (6 - calm) + (6 - focus)) / 3.0
//
//        // 1. Depressed Mood
//        if fatigue >= 4 && calm <= 2 && focus <= 2 {
//            return "Depressed Mood"
//        }
//
//        // 2. Stressed
//        if fatigue >= 4 && calm <= 3 {
//            return "Stressed"
//        }
//
//        // 3. Craving (high excitement, low calm)
//        if excited >= 4 && calm <= 2 {
//            return "Craving"
//        }
//
//        // 4. Happy, Tired & Anxious
//        if positiveAffect <= 2 && fatigue >= 4 {
//            return "Tired & Anxious"
//        }
//
//        // 5. Happy
//        if positiveAffect >= 4 && negativeAffect <= 2 {
//            return "Happy"
//        }
//
//        // 6. Happy, Balanced Mood
////        if positiveAffect >= 4 && negativeAffect <= 3 {
////            return "Happy,Balanced Mood"
////        }
//
//        // Existing condition
//        if energized >= 4 && calm >= 4 {
//            return "Energetic & Calm"
//        }
//
//        return "Balanced Mood"
//    }


    private func submitMood() {
        isLoading = true
        errorMessage = nil
        currentStep = 2

        let mood = predictMood()
        fetchMoodSuggestions(mood: mood)
    }

    private func fetchMoodSuggestions(mood: String) {
        guard let url = URL(string: "https://server-dev-161863711321.asia-south1.run.app/mood/suggestions") else {
            errorMessage = "Invalid URL"
            isLoading = false
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(ProfileViewModel.shared.userID ?? "", forHTTPHeaderField: "X-User-ID")
        request.setValue(ProfileViewModel.shared.email ?? "", forHTTPHeaderField: "X-User-Email")

        let body: [String: Any] = ["current_mood": mood]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            errorMessage = "Failed to encode request"
            isLoading = false
            return
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                self.isLoading = false

                if let error = error {
                    self.errorMessage = error.localizedDescription
                    return
                }

                guard let data = data else {
                    self.errorMessage = "No data received"
                    return
                }

                // Debug: Print raw response
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("📥 API Response: \(jsonString)")
                }

                do {
                    let decoded = try JSONDecoder().decode(MoodAPIResponse.self, from: data)

                    // Check if response contains an error message
                    if let message = decoded.message {
                        self.errorMessage = message
                        return
                    }

                    // Check if suggestions exist
                    if let items = decoded.suggestions, !items.isEmpty {
                        self.suggestions = items.map { item in
                            MoodSuggestion(
                                foodName: item.food_name,
                                description: item.description
                            )
                        }
                    } else {
                        self.errorMessage = "No food suggestions available for your mood"
                    }
                } catch {
                    self.errorMessage = "Failed to parse response: \(error.localizedDescription)"
                    print("❌ Decoding error: \(error)")
                }
            }
        }.resume()
    }
}

// MARK: - API Response Models (FIXED - Only one declaration)
// MARK: - API Response Models
private struct MoodAPIResponse: Codable {
    let message: String?
    let meal_type: String?
    let suggestions: [MoodAPIItem]?
}

private struct MoodAPIItem: Codable {
    let food_name: String
    let description: String
}

// MARK: - Mood Input View
struct MoodInputView: View {
    @Binding var moodValues: MoodInput
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            Text("How's your Mood today?")
                .font(.title)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .padding(.top, 40)

            VStack(spacing: 24) {
                MoodSlider(title: "Calm", value: $moodValues.calm)
                MoodSlider(title: "Focus", value: $moodValues.focus)
                MoodSlider(title: "Energized", value: $moodValues.energized)
                MoodSlider(title: "Fatigue", value: $moodValues.fatigue)
                MoodSlider(title: "Excited", value: $moodValues.excited)
            }
            .padding(.horizontal, 24)

            Spacer()

            Button(action: onContinue) {
                Text("Continue")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.orange)
                    .cornerRadius(30)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }
}

// MARK: - Mood Slider
struct MoodSlider: View {
    let title: String
    @Binding var value: Int
    
    var body: some View {
        GeometryReader { geometry in
            let totalWidth = geometry.size.width
            
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(title)
                        .font(.body)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    Text("\(value)")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                }
                
                ZStack(alignment: .leading) {
                    // Background track
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.gray.opacity(0.15))
                        .frame(height: 16)
                    
                    // Filled track
                    RoundedRectangle(cornerRadius: 10)
                        .fill(
                            LinearGradient(
                                colors: [Color.orange.opacity(0.8), Color.orange],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: CGFloat(value) / 5 * totalWidth, height: 16)
                    
                    // Thumb (draggable circle)
                    Circle()
                        .fill(Color.white)
                        .frame(width: 28, height: 28)
                        .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                        .overlay(
                            Circle()
                                .stroke(Color.orange, lineWidth: 2)
                        )
                        .offset(x: CGFloat(value - 1) / 4 * (totalWidth - 28))
                        .gesture(
                            DragGesture()
                                .onChanged { gesture in
                                    let newValue = Int(round((gesture.location.x / totalWidth) * 4)) + 1
                                    value = max(1, min(5, newValue))
                                }
                        )
                }
                
                // Scale labels
                HStack {
                    ForEach(1...5, id: \.self) { num in
                        Text("\(num)")
                            .font(.caption2)
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity)
                    }
                }
            }
        }
        .frame(height: 70)
    }
}

// MARK: - Mood Results View
struct MoodResultsView: View {
    let moodValues: MoodInput
    let predictedMood: String
    let onContinue: () -> Void

    private var chartData: [Double] {
        [Double(moodValues.calm), Double(moodValues.focus), Double(moodValues.energized), Double(moodValues.fatigue), Double(moodValues.excited)]
    }

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Text("Here's your mood results!")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.top, 40)

            Text(predictedMood)
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.orange)

            MoodChartView(data: chartData)
                .frame(height: 300)
                .padding(.horizontal, 24)

            HStack(spacing: 12) {
                Image(systemName: "sparkles")
                    .foregroundColor(.orange)
                    .font(.title3)

                Text(getMoodMessage())
                    .font(.body)
                    .multilineTextAlignment(.leading)
            }
            .padding()
            .background(Color.green.opacity(0.1))
            .cornerRadius(12)
            .padding(.horizontal, 24)

            Spacer()

            Button(action: onContinue) {
                Text("Continue")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.orange)
                    .cornerRadius(30)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }

    private func getMoodMessage() -> String {
        switch predictedMood {
        case "Happy":
            return "You're in a great mood — perfect time to crush your goals!"
        case "Energetic & Calm":
            return "You're feeling balanced and energized — ideal for productivity!"
        case "Tired & Anxious":
            return "Take it easy — rest and recharge when you need to."
        case "Neutral Mood":
            return "Your mood is balanced — a good time for routine activities."
        default:
            return "Track your mood to understand yourself better."
        }
    }
}

// MARK: - Mood Chart View
struct MoodChartView: View {
    let data: [Double]
    let labels = ["Calm", "Focus", "Energy", "Fatigue", "Excited"]

    var body: some View {
        VStack(spacing: 0) {
            // Chart container with border
            ZStack {
                // Background grid with dotted lines
                VStack(spacing: 0) {
                    ForEach(0..<6, id: \.self) { i in
                        HStack(spacing: 0) {
                            Text("\(5 - i)")
                                .font(.caption2)
                                .foregroundColor(.gray)
                                .frame(width: 16, alignment: .trailing)
                            
                            // Dotted line
                            GeometryReader { geo in
                                Path { path in
                                    path.move(to: CGPoint(x: 8, y: 0))
                                    path.addLine(to: CGPoint(x: geo.size.width, y: 0))
                                }
                                .stroke(style: StrokeStyle(lineWidth: 1, dash: [2, 2]))
                                .foregroundColor(Color.gray.opacity(0.3))
                            }
                            .frame(height: 1)
                        }
                        if i < 5 {
                            Spacer()
                        }
                    }
                }
                .padding(.trailing, 8)
                
                // Chart area
                GeometryReader { geometry in
                    let chartWidth = geometry.size.width - 28
                    let chartHeight = geometry.size.height
                    let maxValue: Double = 5
                    let pointSpacing = chartWidth / CGFloat(data.count - 1)
                    let startX: CGFloat = 28
                    
                    // Get points for smooth curve
                    let points = data.enumerated().map { index, value -> CGPoint in
                        let x = startX + pointSpacing * CGFloat(index)
                        let y = chartHeight - (chartHeight * CGFloat(value) / CGFloat(maxValue))
                        return CGPoint(x: x, y: y)
                    }
                    
                    // Smooth filled area using Catmull-Rom
                    Path { path in
                        guard points.count > 1 else { return }
                        
                        path.move(to: CGPoint(x: points[0].x, y: chartHeight))
                        path.addLine(to: points[0])
                        
                        // Use Catmull-Rom spline for smooth curves
                        for i in 0..<points.count - 1 {
                            let p0 = i > 0 ? points[i - 1] : points[0]
                            let p1 = points[i]
                            let p2 = points[i + 1]
                            let p3 = i + 2 < points.count ? points[i + 2] : points[i + 1]
                            
                            // Calculate control points
                            let cp1x = p1.x + (p2.x - p0.x) / 6
                            let cp1y = p1.y + (p2.y - p0.y) / 6
                            let cp2x = p2.x - (p3.x - p1.x) / 6
                            let cp2y = p2.y - (p3.y - p1.y) / 6
                            
                            path.addCurve(
                                to: p2,
                                control1: CGPoint(x: cp1x, y: cp1y),
                                control2: CGPoint(x: cp2x, y: cp2y)
                            )
                        }
                        
                        path.addLine(to: CGPoint(x: points[points.count - 1].x, y: chartHeight))
                        path.closeSubpath()
                    }
                    .fill(
                        LinearGradient(
                            colors: [Color.orange.opacity(0.4), Color.orange.opacity(0.1)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    
                    // Smooth line using Catmull-Rom
                    Path { path in
                        guard points.count > 1 else { return }
                        
                        path.move(to: points[0])
                        
                        for i in 0..<points.count - 1 {
                            let p0 = i > 0 ? points[i - 1] : points[0]
                            let p1 = points[i]
                            let p2 = points[i + 1]
                            let p3 = i + 2 < points.count ? points[i + 2] : points[i + 1]
                            
                            let cp1x = p1.x + (p2.x - p0.x) / 6
                            let cp1y = p1.y + (p2.y - p0.y) / 6
                            let cp2x = p2.x - (p3.x - p1.x) / 6
                            let cp2y = p2.y - (p3.y - p1.y) / 6
                            
                            path.addCurve(
                                to: p2,
                                control1: CGPoint(x: cp1x, y: cp1y),
                                control2: CGPoint(x: cp2x, y: cp2y)
                            )
                        }
                    }
                    .stroke(Color.orange, lineWidth: 2)
                    
                    // Data points with white fill and orange border
                    ForEach(data.indices, id: \.self) { index in
                        let x = startX + pointSpacing * CGFloat(index)
                        let y = chartHeight - (chartHeight * CGFloat(data[index]) / CGFloat(maxValue))
                        
                        Circle()
                            .fill(Color.orange)
                            .frame(width: 8, height: 8)
                            .position(x: x, y: y)
                    }
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    .background(Color.white.cornerRadius(12))
            )
            
            // X-axis labels
            HStack(spacing: 0) {
                Spacer().frame(width: 28)
                ForEach(labels, id: \.self) { label in
                    Text(label)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.top, 8)
            
            // Legend
            HStack(spacing: 6) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.orange)
                    .frame(width: 12, height: 3)
                Circle()
                    .fill(Color.orange)
                    .frame(width: 6, height: 6)
                Text("Mood values")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding(.top, 8)
        }
    }
}

// MARK: - Mood Suggestions View
struct MoodSuggestionsView: View {
    let suggestions: [MoodSuggestion]
    let isLoading: Bool
    let errorMessage: String?
    let onContinue: () -> Void

    @State private var likedFoodNames: Set<String> = []
    @State private var isLoadingLikes = false

    var body: some View {
        VStack(spacing: 24) {
            Text("Based on your mood, here\nare some food suggestions")
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .padding(.top, 40)

            if isLoading {
                ProgressView()
                    .padding()
                Spacer()
            } else if let error = errorMessage {
                Text(error)
                    .font(.subheadline)
                    .foregroundColor(.red)
                    .padding()
                Spacer()
            } else {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        ForEach(suggestions) { suggestion in
                            FoodSuggestionCard(
                                suggestion: suggestion,
                                isLiked: likedFoodNames.contains(suggestion.foodName),
                                onLike: {
                                    toggleLike(foodName: suggestion.foodName)
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 24)
                }
            }

            Button(action: onContinue) {
                Text("Continue")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.orange)
                    .cornerRadius(30)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        .onAppear {
            fetchLikedFoods()
        }
    }
    
    private func fetchLikedFoods() {
        // Use ProfileViewModel to keep state in sync
        if ProfileViewModel.shared.likedFoods.isEmpty {
            ProfileViewModel.shared.fetchLikedFoods()
        }
        
        // Also fetch freshly here or rely on ViewModel
        UserService.shared.fetchLikedFoods { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let likedFoods):
                    likedFoodNames = Set(likedFoods.map { $0.food })
                    // Sync with ViewModel
                    ProfileViewModel.shared.likedFoods = likedFoods
                case .failure(let error):
                    print("❌ Failed to fetch liked foods: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func toggleLike(foodName: String) {
        guard !isLoadingLikes else { return }
        
        let isCurrentlyLiked = likedFoodNames.contains(foodName)
        isLoadingLikes = true
        
        // Use ProfileViewModel to handle API and State
        ProfileViewModel.shared.toggleLikedFood(foodName) { success in
            DispatchQueue.main.async {
                isLoadingLikes = false
                if success {
                    if isCurrentlyLiked {
                        likedFoodNames.remove(foodName)
                        print("✅ Removed \(foodName) from liked foods")
                    } else {
                        likedFoodNames.insert(foodName)
                        print("✅ Added \(foodName) to liked foods")
                    }
                } else {
                    print("❌ Failed to toggle like for \(foodName)")
                }
            }
        }
    }
}

// MARK: - Food Suggestion Card
struct FoodSuggestionCard: View {
    let suggestion: MoodSuggestion
    let isLiked: Bool
    let onLike: () -> Void

    private var dietType: String {
        if suggestion.description.lowercased().contains("vegetarian") {
            return "Vegetarian"
        } else if suggestion.description.lowercased().contains("protein") {
            return "High Protein"
        } else if suggestion.description.lowercased().contains("keto") {
            return "Keto"
        } else {
            return "General"
        }
    }

    private var dietColor: Color {
        switch dietType {
        case "Vegetarian":
            return .green
        case "High Protein":
            return .orange
        case "Keto":
            return .purple
        default:
            return .blue
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(suggestion.foodName)
                        .font(.title3)
                        .fontWeight(.bold)

                    Text(suggestion.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(dietType)
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(dietColor.opacity(0.2))
                        .foregroundColor(dietColor)
                        .cornerRadius(12)
                }

                Spacer()

                Button(action: onLike) {
                    Image(systemName: isLiked ? "heart.fill" : "heart")
                        .font(.title2)
                        .foregroundColor(isLiked ? .red : .gray)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
    }
}

#Preview {
    MoodTrackerView()
}
