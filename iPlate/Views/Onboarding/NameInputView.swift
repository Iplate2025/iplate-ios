//
//  NameInputView.swift
//  iPlate
//
//  1st onboarding screen: asks username, Skip and Continue
//

import SwiftUI

struct NameInputView: View {
    @State private var name: String = ""
    @State private var goNext = false
    @State private var goHome = false
    @StateObject private var vm = OnboardingViewModel()

    // Use ProfileViewModel from your app (set during login)
    private var userId: String { ProfileViewModel.shared.userID ?? "local_user" }
    private var userEmail: String { ProfileViewModel.shared.email ?? "unknown@example.com" }

    var canContinue: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        VStack {
            HStack {
                Text("1 of 6").foregroundColor(.gray)
                Spacer()
                Button("Skip") {
                    markOnboardCompleteAndGoHome()
                }
                .foregroundColor(.gray)
            }
            .padding(.horizontal)
            .padding(.top, 12)

            // progress small capsules
            HStack(spacing: 8) {
                ForEach(0..<6) { idx in
                    Capsule()
                        .frame(width: 36, height: 8)
                        .foregroundColor(idx == 0 ? Color.orange : Color.gray.opacity(0.25))
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)

            VStack(alignment: .leading, spacing: 12) {
                Text("What should we call you?")
                    .font(.title2).fontWeight(.semibold)
                    .padding(.top, 20)

                TextField("", text: $name)
                    .placeholder(when: name.isEmpty) {
                        Text("Enter your name").foregroundColor(.gray)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(.systemGray5), lineWidth: 1))
            }
            .padding(.horizontal)

            Spacer()

            HStack {
                Spacer()
                if vm.isLoading {
                    ProgressView().padding(.trailing, 18).padding(.bottom, 18)
                } else {
                    Button(action: continueTapped) {
                        Text("Continue")
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 26)
                            .background(canContinue ? Color.orange : Color.orange.opacity(0.5))
                            .cornerRadius(22)
                    }
                    .disabled(!canContinue)
                    .padding(.trailing, 18)
                    .padding(.bottom, 18)
                }
            }
        }
        .background(Color.white.ignoresSafeArea())
        .fullScreenCover(isPresented: $goNext) {
            AgeInputView(userName: name)
        }
        .fullScreenCover(isPresented: $goHome) {
            HomeView()
        }
        .overlay(Group {
            if !vm.infoMessage.isEmpty {
                Text(vm.infoMessage)
                    .font(.footnote)
                    .foregroundColor(.gray)
                    .padding(.bottom, 80)
            }
        }, alignment: .bottom)
    }

    private func continueTapped() {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        vm.setUsername(userId: userId, username: trimmed) { result in
            switch result {
            case .success:
                // store username locally & next
                ProfileViewModel.shared.username = trimmed
                UserDefaults.standard.set(trimmed, forKey: "onboard_name_temp")
                self.goNext = true
            case .failure(let err):
                print("setUsername failed:", err.localizedDescription)
            }
        }
    }

    private func markOnboardCompleteAndGoHome() {
        let idKey = userId
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding_\(idKey)")
        self.goHome = true
    }
}

// Simple placeholder view extension for placeholder text
extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content) -> some View {
        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}
