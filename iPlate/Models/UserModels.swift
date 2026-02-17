//
//  UserModels.swift
//  iPlate
//
//  Created by Lukesh D on 27/01/26.
//

// iPlate/Models/UserModels.swift
import Foundation

// MARK: - User Details
struct UserDetails: Codable {
    var userId: String?
    var username: String?
    var allergens: String?
    var diet: String?
    var heightCm: Double?
    var weightKg: Double?
    var breakfastStart: String?
    var breakfastEnd: String?
    var morningSnackStart: String?
    var morningSnackEnd: String?
    var lunchStart: String?
    var lunchEnd: String?
    var eveningSnackStart: String?
    var eveningSnackEnd: String?
    var dinnerStart: String?
    var dinnerEnd: String?
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case username
        case allergens, diet
        case heightCm = "height_cm"
        case weightKg = "weight_kg"
        case breakfastStart = "breakfast_start"
        case breakfastEnd = "breakfast_end"
        case morningSnackStart = "morning_snack_start"
        case morningSnackEnd = "morning_snack_end"
        case lunchStart = "lunch_start"
        case lunchEnd = "lunch_end"
        case eveningSnackStart = "evening_snack_start"
        case eveningSnackEnd = "evening_snack_end"
        case dinnerStart = "dinner_start"
        case dinnerEnd = "dinner_end"
    }
}

// MARK: - User Goals
struct UserGoals: Codable {
    var heightGoalCm: Double?
    var weightGoalKg: Double?
    var calorieTargetKcal: Double?
    var weeklyGoal: String?
    var activityLevel: String?
    var targetBmi: Double?
    var proteinGoalG: Double?
    var carbsGoalG: Double?
    var fatsGoalG: Double?
    var fiberGoalG: Double?
    
    enum CodingKeys: String, CodingKey {
        case heightGoalCm = "height_goal_cm"
        case weightGoalKg = "weight_goal_kg"
        case calorieTargetKcal = "calorie_target_kcal"
        case weeklyGoal = "weekly_goal"
        case activityLevel = "activity_level"
        case targetBmi = "target_bmi"
        case proteinGoalG = "protein_goal_g"
        case carbsGoalG = "carbs_goal_g"
        case fatsGoalG = "fats_goal_g"
        case fiberGoalG = "fiber_goal_g"
    }
}

struct UserGoalsResponse: Codable {
    let data: UserGoals?
    let message: String?
}

// MARK: - Liked Foods
struct LikedFood: Codable, Identifiable, Equatable {
    var id: String { food }
    let food: String
    let imageUrl: String?
    
    enum CodingKeys: String, CodingKey {
        case food
        case imageUrl = "image_url"
    }
}

struct LikedFoodsResponse: Codable {
    let likedFoods: [LikedFood]
    let message: String?
    
    enum CodingKeys: String, CodingKey {
        case likedFoods = "liked_foods"
        case message
    }
}

// MARK: - Meal Timing Helper
struct MealTiming: Identifiable {
    let id = UUID()
    let name: String
    var startTime: String
    var endTime: String
    let startKey: String
    let endKey: String
}
