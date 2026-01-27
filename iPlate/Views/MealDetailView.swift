//
//  MealDetailView.swift
//  iPlate
//
//  Created by Lukesh D on 27/01/26.
//

import SwiftUI

// MARK: - Data Models
struct MealDetailAPIResponse: Decodable {
    let meal_title: String?
    let meal_type: String?
    let created_at: String?
    let image_urls: [String]?
    let foods: [MealFoodItem]
    let summary: MealNutrientSummary
}

struct MealFoodItem: Decodable, Identifiable {
    let id: String
    let name: String
    let weight: Double?
    let nutrients: MealFoodNutrients

    enum CodingKeys: String, CodingKey {
        case id
        case name = "food_name"
        case weight = "quantity_grams"
        case calories, protein, carbs, fat, fiber
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        weight = try container.decodeIfPresent(Double.self, forKey: .weight)

        let calories = try container.decode(Double.self, forKey: .calories)
        let protein = try container.decode(Double.self, forKey: .protein)
        let carbs = try container.decode(Double.self, forKey: .carbs)
        let fat = try container.decode(Double.self, forKey: .fat)
        let fiber = try container.decodeIfPresent(Double.self, forKey: .fiber)

        nutrients = MealFoodNutrients(
            calories: calories,
            protein: protein,
            carbs: carbs,
            fat: fat,
            fiber: fiber
        )
    }
}

struct MealFoodNutrients: Decodable {
    let calories: Double
    let protein: Double
    let carbs: Double
    let fat: Double
    let fiber: Double?
}

struct MealNutrientSummary: Decodable {
    let calories: Double
    let protein: Double
    let carbs: Double
    let fat: Double
    let fiber: Double
}

// MARK: - Main View
struct MealDetailView: View {
    let mealId: String
    @Environment(\.dismiss) var dismiss

    @State private var isLoading = true
    @State private var errorMessage: String?

    @State private var mealTitle = ""
    @State private var mealType = ""
    @State private var createdAt = ""
    @State private var imageUrl: String?
    @State private var foods: [MealFoodItem] = []
    @State private var summary: MealNutrientSummary?

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color(.systemBackground)
                    .ignoresSafeArea()

                if isLoading {
                    ProgressView()
                } else if let error = errorMessage {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundColor(.orange)
                        Text(error)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        Button("Retry") {
                            fetchMealItems()
                        }
                        .foregroundColor(.orange)
                    }
                    .padding()
                } else {
                    ScrollView {
                        VStack(spacing: 0) {
                            mealImageView
                                .frame(width: geometry.size.width)

                            VStack(spacing: 20) {
                                headerSection

                                if let summary = summary {
                                    MealSummaryCardView(summary: summary)
                                        .padding(.horizontal, 16)

                                    MealMacrosBreakdownView(summary: summary)
                                        .padding(.horizontal, 16)
                                }

                                foodItemsSection
                            }
                            .padding(.bottom, 40)
                        }
                    }
                    .ignoresSafeArea(edges: .top)
                }
            }
            .overlay(alignment: .topLeading) {
                closeButton
            }
        }
        .task {
            fetchMealItems()
        }
    }

    private var mealImageView: some View {
        Group {
            if let urlString = imageUrl, let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        placeholderImage.overlay(ProgressView())
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 300)
                            .clipped()
                    case .failure:
                        placeholderImage
                    @unknown default:
                        EmptyView()
                    }
                }
            } else {
                placeholderImage
            }
        }
        .frame(height: 300)
    }

    private var placeholderImage: some View {
        Rectangle()
            .fill(Color(.systemGray5))
            .frame(height: 300)
            .overlay(
                Image(systemName: "photo")
                    .font(.largeTitle)
                    .foregroundColor(.gray)
            )
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(mealTitle.isEmpty ? "Untitled Meal" : mealTitle)
                        .font(.title)
                        .fontWeight(.bold)
                        .lineLimit(2)

                    Text(formatDate(createdAt))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer(minLength: 12)

                if !mealType.isEmpty && mealType != "exception" {
                    Text(mealType.capitalized)
                        .font(.subheadline)
                        .foregroundColor(mealTypeColor)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(mealTypeColor.opacity(0.15))
                        .cornerRadius(12)
                        .fixedSize()
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 20)
    }

    private var foodItemsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Food Items")
                .font(.title3)
                .fontWeight(.bold)
                .padding(.horizontal, 16)

            ForEach(foods) { food in
                MealFoodItemCard(food: food)
                    .padding(.horizontal, 16)
            }
        }
    }

    private var closeButton: some View {
        Button {
            dismiss()
        } label: {
            Circle()
                .fill(Color.white)
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: "xmark")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.primary)
                )
                .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
        }
        .padding(.leading, 16)
        .padding(.top, 60)
    }

    private var mealTypeColor: Color {
        switch mealType.lowercased() {
        case "breakfast": return .green
        case "lunch": return .blue
        case "dinner": return .purple
        case "snack": return .orange
        default: return .gray
        }
    }

    private func formatDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        if let date = formatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateFormat = "MMM d, yyyy 'at' h:mm a"
            return displayFormatter.string(from: date)
        }

        formatter.formatOptions = [.withInternetDateTime]
        if let date = formatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateFormat = "MMM d, yyyy 'at' h:mm a"
            return displayFormatter.string(from: date)
        }

        return dateString
    }

    private func fetchMealItems() {
        isLoading = true
        errorMessage = nil

        let urlString = "https://server-dev-161863711321.asia-south1.run.app/meals/\(mealId)/items"

        guard !mealId.isEmpty else {
            errorMessage = "Invalid meal ID"
            isLoading = false
            return
        }

        guard let baseURL = URL(string: urlString) else {
            errorMessage = "Invalid URL"
            isLoading = false
            return
        }

        var request = URLRequest(url: baseURL)
        request.httpMethod = "GET"

        if let userID = ProfileViewModel.shared.userID, !userID.isEmpty {
            request.setValue(userID, forHTTPHeaderField: "X-User-ID")
        }
        if let email = ProfileViewModel.shared.email, !email.isEmpty {
            request.setValue(email, forHTTPHeaderField: "X-User-Email")
        }
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                self.isLoading = false

                if let error = error {
                    self.errorMessage = "Network error: \(error.localizedDescription)"
                    return
                }

                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                    self.errorMessage = "Server error (code: \(httpResponse.statusCode))"
                    return
                }

                guard let data = data else {
                    self.errorMessage = "No data received"
                    return
                }

                do {
                    let result = try JSONDecoder().decode(MealDetailAPIResponse.self, from: data)
                    self.mealTitle = result.meal_title ?? ""
                    self.mealType = result.meal_type ?? ""
                    self.createdAt = result.created_at ?? ""
                    self.imageUrl = result.image_urls?.first
                    self.foods = result.foods
                    self.summary = result.summary
                } catch {
                    print("❌ Decoding error: \(error)")
                    self.errorMessage = "Failed to parse meal data"
                }
            }
        }.resume()
    }
}

// MARK: - Summary Card
struct MealSummaryCardView: View {
    let summary: MealNutrientSummary

    private var caloriesPercent: Double {
        min(summary.calories / 2400, 1.0)
    }

    var body: some View {
        HStack(spacing: 20) {
            ZStack {
                Circle()
                    .stroke(Color.orange.opacity(0.2), lineWidth: 12)
                    .frame(width: 100, height: 100)

                Circle()
                    .trim(from: 0, to: caloriesPercent)
                    .stroke(Color.orange, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                    .frame(width: 100, height: 100)
                    .rotationEffect(.degrees(-90))

                Text("\(Int(caloriesPercent * 100))%")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.orange)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Calories")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(Int(summary.calories))")
                        .font(.system(size: 32, weight: .bold))
                    Text("cal")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
        )
    }
}

// MARK: - Macros Breakdown
struct MealMacrosBreakdownView: View {
    let summary: MealNutrientSummary

    var body: some View {
        HStack(spacing: 8) {
            MealMacroBox(title: "Protein", current: Int(summary.protein), goal: 40, color: .yellow)
            MealMacroBox(title: "Carbs", current: Int(summary.carbs), goal: 60, color: .orange)
            MealMacroBox(title: "Fats", current: Int(summary.fat), goal: 20, color: .green)
        }
    }
}

struct MealMacroBox: View {
    let title: String
    let current: Int
    let goal: Int
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(1)

            Text("\(current)/\(goal)g")
                .font(.subheadline)
                .fontWeight(.semibold)
                .lineLimit(1)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color(.systemGray5))
                        .frame(height: 6)

                    Capsule()
                        .fill(color)
                        .frame(width: geo.size.width * min(Double(current) / Double(goal), 1.0), height: 6)
                }
            }
            .frame(height: 6)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 8)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
        )
    }
}

// MARK: - Food Item Card
struct MealFoodItemCard: View {
    let food: MealFoodItem

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(food.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .lineLimit(2)

                    if let weight = food.weight {
                        Text("\(Int(weight)) g")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Button {
                    // Delete action
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 18))
                        .foregroundColor(.red)
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(PlainButtonStyle())
            }

            Divider()

            HStack(spacing: 8) {
                MealNutrientPill(label: "Protein", value: food.nutrients.protein, unit: "g")
                MealNutrientPill(label: "Carbs", value: food.nutrients.carbs, unit: "g")
                MealNutrientPill(label: "Fat", value: food.nutrients.fat, unit: "g")
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
        )
    }
}

struct MealNutrientPill: View {
    let label: String
    let value: Double
    let unit: String

    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
                .lineLimit(1)
            Text("\(Int(value))\(unit)")
                .font(.caption)
                .fontWeight(.medium)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

#Preview {
    MealDetailView(mealId: "sample-id")
}
