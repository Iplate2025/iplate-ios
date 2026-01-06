//
//  DietPreferenceView.swift
//  iPlate
//
//  Created by ChatGPT (assistant) on behalf of Lukesh.
//  Matches design: progress capsules, Skip, selectable cards, Continue button bottom-right.
//  Sends diet selection to server (PUT /user/details) before navigating to the next onboarding step.
//

import SwiftUI

struct DietPreferenceView: View {
    // Diet options
    private let options = ["Vegan", "Vegetarian", "Keto", "Pescatarian", "None"]

    // Selected option
    @State private var selectedOption: String? = nil

    // Navigation
    @State private var goNext = false
    @State private var goHome = false

    // VM handling network calls
    @StateObject private var vm = OnboardingViewModel()

    // Read user session (ProfileViewModel should store these after login)
    private var userId: String {
        // fallback generated id when ProfileViewModel doesn't exist / not set
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
            // Top row: step label + Skip
            HStack {
                Text("3 of 6").foregroundColor(.gray)
                Spacer()
                Button(action: { skipTapped() }) {
                    Text("Skip")
                        .foregroundColor(.gray)
                }
            }
            .padding(.horizontal)
            .padding(.top, 12)

            // Progress capsules (6 total, highlight first 3)
            HStack(spacing: 8) {
                ForEach(0..<6) { idx in
                    Capsule()
                        .frame(width: 36, height: 8)
                        .foregroundColor(idx <= 2 ? Color.orange : Color.gray.opacity(0.25))
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)

            // Title
            VStack(alignment: .leading, spacing: 8) {
                Text("What’s your diet?")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .padding(.top, 18)
            }
            .padding(.horizontal)

            // Options list
            VStack(spacing: 12) {
                ForEach(options, id: \.self) { option in
                    Button(action: { selectedOption = option }) {
                        HStack {
                            // small checkbox style
                            Image(systemName: selectedOption == option ? "checkmark.square.fill" : "square")
                                .foregroundColor(selectedOption == option ? .orange : .gray)
                                .font(.system(size: 20))
                            Text(option)
                                .foregroundColor(.black)
                                .padding(.leading, 6)
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

            // Inline VM info message (success/error)
            if !vm.infoMessage.isEmpty {
                Text(vm.infoMessage)
                    .font(.footnote)
                    .foregroundColor(.gray)
                    .padding(.bottom, 6)
            }

            // Continue button aligned bottom-right (rounded capsule)
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
                            .background(selectedOption != nil ? Color.orange : Color.orange.opacity(0.5))
                            .cornerRadius(22)
                    }
                    .disabled(selectedOption == nil && !vm.isLoading)
                    .padding(.trailing, 18)
                    .padding(.bottom, 18)
                }
            }
        }
        .background(Color.white.ignoresSafeArea())
        .fullScreenCover(isPresented: $goNext) {
            AllergyPreferenceView()
        }
        .fullScreenCover(isPresented: $goHome) {
            HomeView()
        }
    }

    // Skip -> mark onboarding locally as complete, go to Home
    private func skipTapped() {
        // Mark completed locally (you can also call the server final /auth/onboard endpoint if required)
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding_\(userId)")
        goHome = true
    }

    // Continue -> send selected diet to backend and go to next step
    private func continueTapped() {
        guard let diet = selectedOption else {
            vm.infoMessage = "Please choose a diet or Skip."
            return
        }

        let details: [String: Any] = [
            "diet": diet
        ]

        vm.updateUserDetails(userId: userId, userEmail: userEmail, details: details) { result in
            switch result {
            case .success(_):
                // advance to next step
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
