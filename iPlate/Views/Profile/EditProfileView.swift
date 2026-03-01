//
//  EditProfileView.swift
//  iPlate
//
//  Created by Lukesh D on 27/01/26.
//

// iPlate/Views/Profile/EditProfileView.swift
import SwiftUI

struct EditProfileView: View {
    @StateObject private var viewModel = ProfileViewModel.shared
    @State private var showingEditSheet = false
    @State private var editingField: EditField?
    @State private var editValue: String = ""
    
    enum EditField: String, CaseIterable {
        case userName = "User Name"
        case height = "Height"
        case weight = "Weight"
        case sex = "Sex"
        case dateOfBirth = "Date Of Birth"
        case units = "Units"
    }
    
    var body: some View {
        List {
            Section(header: Text("Personal Details")) {
                editRow(field: .userName, value: viewModel.userName ?? "")
                
                HStack {
                    Text("Email")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(viewModel.email ?? "")
                }
                
                editRow(field: .height, value: formatHeight())
                editRow(field: .weight, value: formatWeight())
                editRow(field: .sex, value: viewModel.userDetails?.sex ?? viewModel.sex ?? "")
                editRow(field: .dateOfBirth, value: formatDateOfBirth())
                editRow(field: .units, value: viewModel.units)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Edit Profile")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingEditSheet) {
            EditFieldSheet(
                field: editingField ?? .userName,
                value: $editValue,
                onSave: saveField
            )
        }
        .onAppear {
            viewModel.fetchUserDetails()
        }
    }
    
    private func editRow(field: EditField, value: String) -> some View {
        Button {
            editingField = field
            editValue = value
            showingEditSheet = true
        } label: {
            HStack {
                Text(field.rawValue)
                    .foregroundColor(.secondary)
                Spacer()
                Text(value)
                    .foregroundColor(.primary)
            }
        }
    }
    
    private func formatHeight() -> String {
        if let height = viewModel.userDetails?.heightCm {
            return "\(Int(height)) cm"
        }
        return ""
    }
    
    private func formatWeight() -> String {
        if let weight = viewModel.userDetails?.weightKg {
            return "\(Int(weight)) kg"
        }
        return ""
    }
    
    private func formatDateOfBirth() -> String {
        // First try from API userDetails
        if let dobStr = viewModel.userDetails?.dob, !dobStr.isEmpty {
            let inFmt = DateFormatter()
            inFmt.dateFormat = "yyyy-MM-dd"
            if let date = inFmt.date(from: dobStr) {
                let outFmt = DateFormatter()
                outFmt.dateFormat = "MMM d, yyyy"
                return outFmt.string(from: date)
            }
            return dobStr
        }
        // Fall back to local dateOfBirth
        if let dob = viewModel.dateOfBirth {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d, yyyy"
            return formatter.string(from: dob)
        }
        return ""
    }
    
    private func saveField() {
        guard let field = editingField else { return }
        
        switch field {
        case .userName:
            // Call API to set username in database
            viewModel.setUsername(editValue) { success in
                if success {
                    print("✅ Username updated successfully via API")
                } else {
                    print("❌ Failed to update username via API")
                }
            }
        case .height:
            let numericValue = editValue.replacingOccurrences(of: "[^0-9.]", with: "", options: .regularExpression)
            if let height = Double(numericValue) {
                viewModel.updateUserDetails(["height_cm": height])
            }
        case .weight:
            let numericValue = editValue.replacingOccurrences(of: "[^0-9.]", with: "", options: .regularExpression)
            if let weight = Double(numericValue) {
                viewModel.updateUserDetails(["weight_kg": weight])
            }
        case .sex:
            if !editValue.isEmpty {
                viewModel.updateUserDetails(["sex": editValue])
            }
            viewModel.updateLocalProfile(dateOfBirth: nil, sex: editValue, units: nil)
        case .dateOfBirth:
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d, yyyy"
            if let date = formatter.date(from: editValue) {
                // Also send to API in yyyy-MM-dd format
                let apiFmt = DateFormatter()
                apiFmt.dateFormat = "yyyy-MM-dd"
                let dobStr = apiFmt.string(from: date)
                viewModel.updateUserDetails(["dob": dobStr, "date_of_birth": dobStr])
                viewModel.updateLocalProfile(dateOfBirth: date, sex: nil, units: nil)
            }
        case .units:
            viewModel.updateLocalProfile(dateOfBirth: nil, sex: nil, units: editValue)
        }
        
        showingEditSheet = false
    }
}

// MARK: - Edit Field Sheet
struct EditFieldSheet: View {
    let field: EditProfileView.EditField
    @Binding var value: String
    let onSave: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text(field.rawValue)
                    .font(.headline)
                
                HStack {
                    TextField(field.rawValue, text: $value)
                        .textFieldStyle(.roundedBorder)
                    
                    Button {
                        value = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
                .padding(.horizontal)
                
                HStack(spacing: 16) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGray5))
                    .cornerRadius(10)
                    
                    Button("Submit") {
                        onSave()
                        dismiss()
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .padding(.top, 30)
        }
        .presentationDetents([.height(200)])
    }
}
