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
    @State private var moodValues = MoodInput(calm: 3, focus: 2, energized: 4, fatigue: 3, excited: 2)
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

    private func submitMood() {
        isLoading = true
        errorMessage = nil
        currentStep = 2

        MoodService.shared.submitMoodAndGetSuggestions(mood: moodValues.currentMood) { result in
            isLoading = false

            switch result {
            case .success(let response):
                suggestions = response.suggestions
            case .failure(let error):
                errorMessage = error.localizedDescription
            }
        }
    }
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
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.title3)
                .fontWeight(.semibold)

            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 12)

                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.orange.opacity(0.6))
                    .frame(width: CGFloat(value) / 5 * (UIScreen.main.bounds.width - 48), height: 12)

                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 32, height: 32)
                        .shadow(radius: 4)

                    Text("\(value)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(8)
                        .background(Color.orange)
                        .cornerRadius(8)
                        .offset(y: -30)
                }
                .offset(x: CGFloat(value - 1) / 4 * (UIScreen.main.bounds.width - 80))
                .gesture(
                    DragGesture()
                        .onChanged { gesture in
                            let width = UIScreen.main.bounds.width - 80
                            let newValue = Int(round((gesture.location.x / width) * 4)) + 1
                            value = max(1, min(5, newValue))
                        }
                )
            }

            HStack {
                ForEach(1...5, id: \.self) { num in
                    Text("\(num)")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity)
                }
            }
        }
    }
}

// MARK: - Mood Results View
struct MoodResultsView: View {
    let moodValues: MoodInput
    let onContinue: () -> Void

    private var dominantMood: String {
        moodValues.currentMood.capitalized
    }

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

            Text(dominantMood)
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
        switch dominantMood.lowercased() {
        case "energized":
            return "You're in a great mood — perfect time to crush your goals!"
        case "calm":
            return "You're feeling peaceful — enjoy this moment of tranquility."
        case "focus":
            return "Your concentration is sharp — great for productive work!"
        case "excited":
            return "Your energy is high — channel it into something amazing!"
        case "fatigue":
            return "Take it easy — rest and recharge when you need to."
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
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            let maxValue: Double = 5
            let spacing = width / CGFloat(data.count)

            ZStack {
                VStack(spacing: 0) {
                    ForEach(0...5, id: \.self) { i in
                        HStack {
                            Text("\(5 - i)")
                                .font(.caption2)
                                .foregroundColor(.gray)
                                .frame(width: 20)

                            Rectangle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 1)
                        }
                        if i < 5 {
                            Spacer()
                        }
                    }
                }

                Path { path in
                    let startX = spacing / 2
                    path.move(to: CGPoint(x: startX, y: height))

                    for (index, value) in data.enumerated() {
                        let x = startX + spacing * CGFloat(index)
                        let y = height - (height * CGFloat(value) / CGFloat(maxValue))

                        if index == 0 {
                            path.move(to: CGPoint(x: x, y: y))
                        } else {
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }

                    path.addLine(to: CGPoint(x: startX + spacing * CGFloat(data.count - 1), y: height))
                    path.addLine(to: CGPoint(x: startX, y: height))
                }
                .fill(
                    LinearGradient(
                        colors: [Color.orange.opacity(0.4), Color.orange.opacity(0.1)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

                Path { path in
                    let startX = spacing / 2

                    for (index, value) in data.enumerated() {
                        let x = startX + spacing * CGFloat(index)
                        let y = height - (height * CGFloat(value) / CGFloat(maxValue))

                        if index == 0 {
                            path.move(to: CGPoint(x: x, y: y))
                        } else {
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                }
                .stroke(Color.orange, lineWidth: 3)

                ForEach(data.indices, id: \.self) { index in
                    let x = spacing / 2 + spacing * CGFloat(index)
                    let y = height - (height * CGFloat(data[index]) / CGFloat(maxValue))

                    Circle()
                        .fill(Color.orange)
                        .frame(width: 12, height: 12)
                        .position(x: x, y: y)
                }

                HStack(spacing: 0) {
                    ForEach(labels, id: \.self) { label in
                        Text(label)
                            .font(.caption)
                            .frame(maxWidth: .infinity)
                    }
                }
                .position(x: width / 2, y: height + 20)
            }
            .padding(.leading, 30)
            .padding(.bottom, 60)
        }
    }
}

// MARK: - Mood Suggestions View
struct MoodSuggestionsView: View {
    let suggestions: [MoodSuggestion]
    let isLoading: Bool
    let errorMessage: String?
    let onContinue: () -> Void

    @State private var likedSuggestions: Set<UUID> = []

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
                                isLiked: likedSuggestions.contains(suggestion.id),
                                onLike: {
                                    if likedSuggestions.contains(suggestion.id) {
                                        likedSuggestions.remove(suggestion.id)
                                    } else {
                                        likedSuggestions.insert(suggestion.id)
                                    }
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
