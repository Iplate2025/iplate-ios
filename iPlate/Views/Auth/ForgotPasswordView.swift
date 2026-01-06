import SwiftUI

struct ForgotPasswordView: View {
    @State private var email = ""
    @State private var newPassword = ""
    @StateObject private var viewModel = AuthViewModel()
    @State private var infoMessage: String = ""
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 16) {
            Spacer(minLength: 20)
            Text("Reset your password")
                .font(.title2.weight(.semibold))
            
            VStack(spacing: 12) {
                TextField("Enter your email", text: $email)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                
                SecureField("Enter new password", text: $newPassword)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
            }
            .padding(.horizontal, 20)
            
            if !infoMessage.isEmpty {
                Text(infoMessage)
                    .font(.footnote)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }
            
            if viewModel.isLoading {
                ProgressView()
            } else {
                Button(action: resetPassword) {
                    Text("Reset Password")
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.orange)
                        .cornerRadius(10)
                }
                .padding(.horizontal, 20)
            }
            
            Spacer()
        }
        .padding(.top, 10)
    }
    
    private func resetPassword() {
        infoMessage = ""
        
        guard !email.trimmingCharacters(in: .whitespaces).isEmpty else {
            infoMessage = "Please enter your email."
            return
        }
        
        viewModel.resetPassword(email: email) { resultMessage in
            infoMessage = resultMessage
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                dismiss()
            }
        }
    }

}

#Preview {
    ForgotPasswordView()
}
