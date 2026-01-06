//
//  OnboardingData.swift
//  iPlate
//
//  Created by Lukesh D on 01/01/26.
//

import Foundation

final class OnboardingData {
    static let shared = OnboardingData()
    private init() {}

    // Filled during onboarding steps
    var username: String? = nil
    var diet: String? = nil
    var allergies: [String] = []
    var heightCm: Double? = nil
    var weightKg: Double? = nil

    func clear() {
        username = nil
        diet = nil
        allergies = []
        heightCm = nil
        weightKg = nil
    }
}
