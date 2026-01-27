//
//  ProfileView.swift
//  iPlate
//
//  Created by Lukesh D on 26/01/26.
//

import SwiftUI

struct ProfileView: View {
    @StateObject private var viewModel = ProfileViewModel.shared
    @State private var goToLogin = false
    @State private var isLoggingOut = false
    @State private var logoutError: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    profileHeader

                    sectionHeader("Personal Details")
                    personalDetailsSection

                    sectionHeader("Preferences")
                    preferencesSection

                    sectionHeader("Account & Support")
                    accountSupportSection

                    if let logoutError {
                        Text(logoutError)
                            .foregroundColor(.red)
                            .font(.footnote)
                            .multilineTextAlignment(.center)
                            .padding(.top, 8)
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                viewModel.fetchUserDetails()
                viewModel.fetchUserGoals()
                viewModel.fetchLikedFoods()
            }
        }
        .fullScreenCover(isPresented: $goToLogin) {
            LoginView()
        }
    }

    // MARK: - Profile Header
    private var profileHeader: some View {
        VStack(spacing: 12) {
            ZStack(alignment: .bottomTrailing) {
                Circle()
                    .fill(Color.orange.opacity(0.2))
                    .frame(width: 100, height: 100)
                    .overlay(
                        Text(String(viewModel.userName?.prefix(1).uppercased() ?? "U"))
                            .font(.system(size: 40, weight: .medium))
                            .foregroundColor(.orange)
                    )

                Circle()
                    .fill(Color(.systemGray5))
                    .frame(width: 28, height: 28)
                    .overlay(
                        Image(systemName: "pencil")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    )
            }

            Text(viewModel.userName ?? "User")
                .font(.title2)
                .fontWeight(.semibold)

            Text(viewModel.email ?? "")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.vertical)
    }

    // MARK: - Section Header
    private func sectionHeader(_ title: String) -> some View {
        HStack {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            Spacer()
        }
    }

    // MARK: - Personal Details Section
    private var personalDetailsSection: some View {
        VStack(spacing: 0) {
            NavigationLink(destination: EditProfileView()) {
                ProfileRowView(icon: "person.circle", iconColor: .orange, title: "Edit Profile")
            }

            Divider().padding(.leading, 50)

            NavigationLink(destination: MyGoalsView()) {
                ProfileRowView(icon: "flag.fill", iconColor: .orange, title: "My Goals")
            }

            Divider().padding(.leading, 50)

            NavigationLink(destination: MealTimingsView()) {
                ProfileRowView(icon: "fork.knife", iconColor: .orange, title: "Meal Timings")
            }
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }

    // MARK: - Preferences Section
    private var preferencesSection: some View {
        VStack(spacing: 0) {
            NavigationLink(destination: AppearanceView()) {
                ProfileRowView(icon: "paintpalette.fill", iconColor: .orange, title: "Appearance")
            }

            Divider().padding(.leading, 50)

            NavigationLink(destination: NotificationsView()) {
                ProfileRowView(icon: "bell.fill", iconColor: .orange, title: "Notifications")
            }

            Divider().padding(.leading, 50)

            NavigationLink(destination: ConnectedDevicesView()) {
                ProfileRowView(icon: "applewatch", iconColor: .orange, title: "Connected Devices")
            }

            Divider().padding(.leading, 50)

            NavigationLink(destination: LikedFoodsView()) {
                ProfileRowView(icon: "heart.fill", iconColor: .orange, title: "Liked Foods")
            }
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }

    // MARK: - Account & Support Section
    private var accountSupportSection: some View {
        VStack(spacing: 0) {
            NavigationLink(destination: HelpSupportView()) {
                ProfileRowView(icon: "questionmark.circle", iconColor: .orange, title: "Help & Support")
            }

            Divider().padding(.leading, 50)

            NavigationLink(destination: PrivacyPolicyView()) {
                ProfileRowView(icon: "lock.shield", iconColor: .orange, title: "Privacy Policy")
            }

            Divider().padding(.leading, 50)

            NavigationLink(destination: AboutUsView()) {
                ProfileRowView(icon: "info.circle", iconColor: .orange, title: "About Us")
            }

            Divider().padding(.leading, 50)

            // Logout Button
            Button(action: performLogout) {
                HStack {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                        .foregroundColor(.orange)
                        .frame(width: 30)

                    Text("Logout")
                        .foregroundColor(.red)

                    Spacer()

                    if isLoggingOut {
                        ProgressView()
                    } else {
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                .padding()
            }
            .disabled(isLoggingOut)
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }

    // MARK: - Logout
    private func performLogout() {
        guard let token = ProfileViewModel.shared.sessionToken else {
            logoutError = "Session missing"
            return
        }

        isLoggingOut = true
        logoutError = nil

        AuthService.shared.logout(sessionToken: token) { result in
            DispatchQueue.main.async {
                self.isLoggingOut = false

                switch result {
                case .success:
                    ProfileViewModel.shared.clear()
                    goToLogin = true

                case .failure(let error):
                    self.logoutError = error.localizedDescription
                }
            }
        }
    }
}

#Preview {
    ProfileView()
}
