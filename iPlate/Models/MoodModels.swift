//
//  MoodModels.swift
//  iPlate
//
//  Created by Lukesh D on 26/01/26.
//

import Foundation

// MARK: - Mood Models
struct MoodInput: Codable {
    var calm: Int
    var focus: Int
    var energized: Int
    var fatigue: Int
    var excited: Int

    var currentMood: String {
        let values = [
            ("calm", calm),
            ("focus", focus),
            ("energized", energized),
            ("fatigue", fatigue),
            ("excited", excited)
        ]

        let maxMood = values.max(by: { $0.1 < $1.1 })
        return maxMood?.0 ?? "neutral"
    }
}

struct MoodSuggestion: Codable, Identifiable, Sendable {
    let id = UUID()
    let foodName: String
    let description: String

    enum CodingKeys: String, CodingKey {
        case foodName = "food_name"
        case description
    }
}

struct MoodSuggestionsResponse: Codable, Sendable {
    let mealType: String
    let suggestions: [MoodSuggestion]

    enum CodingKeys: String, CodingKey {
        case mealType = "meal_type"
        case suggestions
    }
}

struct LastMoodInput: Codable, Sendable {
    let id: String
    let userId: String
    let currentMood: String
    let timestamp: String

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case currentMood = "current_mood"
        case timestamp
    }
}
