//
//  AllergyPreferenceView.swift
//  iPlate
//
//  Created by ChatGPT for Lukesh.
//  Collects allergies, posts to /user/details and navigates to next onboarding step.
//

import SwiftUI

struct AllergyPreferenceView: View {
    // Allergy options (matches your mock)
    private let allergies = ["Nuts", "Lactose", "Eggs", "Shellfish", "Gluten", "Soy", "Seafood", "None"]

    // Selected allergies (multiple)
    @State private var selectedAllergies: Set<String> = []

    // Navigation & state
    @State private var goNext = false
    @State private var goHome = false

    // ViewModel that performs the network call (PUT /user/details)
    @StateObject private var vm = OnboardingViewModel()

    // Read user session (ProfileViewModel should be set after login)
    private var userId: String {
        if let id = ProfileViewModel.shared.userID { return id }
        if let email = ProfileViewModel.shared.email {
            return "local_" + email.replacingOccurrences(of: "@", with: "_").replacingOccurrences(of: ".", with: "_")
        }
        return "local_unknown_user"
    }
    private var userEmail: String {
        ProfileViewModel.shared.email ?? "unknown@example.com"
    }

    var body: some View {
        VStack {
            // Top: step label + Skip
            HStack {
                Text("5 of 7")
                    .foregroundColor(.gray)
                Spacer()
                Button(action: { skipTapped() }) {
                    Text("Skip")
                        .foregroundColor(.gray)
                }
            }
            .padding(.horizontal)
            .padding(.top, 12)

            // Progress capsules
            HStack(spacing: 6) {
                ForEach(0..<7) { idx in
                    Capsule()
                        .frame(width: 30, height: 8)
                        .foregroundColor(idx <= 4 ? Color.orange : Color.gray.opacity(0.25))
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)

            // Title
            VStack(alignment: .leading, spacing: 6) {
                Text("what are you allergic to?")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .padding(.top, 14)
            }
            .padding(.horizontal)

            // Options list
            VStack(spacing: 12) {
                ForEach(allergies, id: \.self) { allergy in
                    Button(action: {
                        toggle(allergy: allergy)
                    }) {
                        HStack {
                            Image(systemName: selectedAllergies.contains(allergy) ? "checkmark.square.fill" : "square")
                                .foregroundColor(selectedAllergies.contains(allergy) ? .orange : .gray)
                                .font(.system(size: 20))
                            Text(allergy)
                                .foregroundColor(.black)
                                .padding(.leading, 8)
                            Spacer()
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.gray.opacity(0.25), lineWidth: 1)
                                .background(Color.white)
                        )
                    }
                    .padding(.horizontal, 16)
                }
            }
            .padding(.top, 12)

            Spacer()

            // Inline message from VM (success/error)
            if !vm.infoMessage.isEmpty {
                Text(vm.infoMessage)
                    .font(.footnote)
                    .foregroundColor(.gray)
                    .padding(.bottom, 6)
            }

            // Continue button aligned bottom-right
            HStack {
                Spacer()
                if vm.isLoading {
                    ProgressView()
                        .padding(.trailing, 18)
                        .padding(.bottom, 18)
                } else {
                    Button(action: continueTapped) {
                        Text("Continue")
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 26)
                            .background(Color.orange)
                            .cornerRadius(22)
                    }
                    .padding(.trailing, 18)
                    .padding(.bottom, 18)
                }
            }
        }
        .background(Color.white.ignoresSafeArea())
        .fullScreenCover(isPresented: $goNext) {
            HeightWeightView()
        }
        .fullScreenCover(isPresented: $goHome) {
            HomeView()
        }
    }

    // Toggle selection. If "None" is selected, clear others; selecting any other removes "None".
    private func toggle(allergy: String) {
        if allergy == "None" {
            if selectedAllergies.contains("None") {
                selectedAllergies.remove("None")
            } else {
                selectedAllergies = ["None"]
            }
            return
        }
        // normal allergy
        if selectedAllergies.contains(allergy) {
            selectedAllergies.remove(allergy)
        } else {
            selectedAllergies.insert(allergy)
            // if "None" was selected, remove it
            selectedAllergies.remove("None")
        }
    }

    // Skip: mark onboarding locally as complete and go Home
    private func skipTapped() {
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding_\(userId)")
        goHome = true
    }

    // Continue: send selected allergies to backend, then proceed
    private func continueTapped() {
        // Format allergens: server expects a string (comma separated) or single value.
        // Adjust payload shape if backend expects an array.
        let allergensString: String
        if selectedAllergies.isEmpty {
            // no selection -> treat as "None"
            allergensString = ""
        } else if selectedAllergies.contains("None") {
            allergensString = ""
        } else {
            allergensString = selectedAllergies.sorted().joined(separator: ",")
        }

        var details: [String: Any] = [:]
        // if empty string -> server may interpret as no allergens
        details["allergens"] = allergensString

        vm.updateUserDetails(userId: userId, userEmail: userEmail, details: details) { result in
            switch result {
            case .success(_):
                // mark local onboarding progress if desired
                DispatchQueue.main.async {
                    self.goNext = true
                }
            case .failure(let err):
                DispatchQueue.main.async {
                    self.vm.infoMessage = "❌ \(err.localizedDescription)"
                }
            }
        }
    }
}
