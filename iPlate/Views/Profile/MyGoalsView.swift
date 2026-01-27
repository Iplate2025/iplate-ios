//
//  MyGoalsView.swift
//  iPlate
//
//  Created by Lukesh D on 27/01/26.
//

// iPlate/Views/Profile/MyGoalsView.swift
import SwiftUI

struct MyGoalsView: View {
    @StateObject private var viewModel = ProfileViewModel.shared
    @State private var showingEditSheet = false
    @State private var editingField: GoalField?
    @State private var editValue: String = ""
    
    enum GoalField: String, CaseIterable {
        case heightGoal = "Height Goal"
        case weightGoal = "Weight Goal"
        case calorieTarget = "Calorie Target"
        case weeklyGoal = "Weekly Goal"
        case activityLevel = "Activity Level"
    }
    
    var body: some View {
        List {
            Section(header: Text("My Goals")) {
                goalRow(field: .heightGoal, value: formatHeightGoal())
                goalRow(field: .weightGoal, value: formatWeightGoal())
                goalRow(field: .calorieTarget, value: formatCalorieTarget())
                goalRow(field: .weeklyGoal, value: viewModel.userGoals?.weeklyGoal ?? "")
                goalRow(field: .activityLevel, value: viewModel.userGoals?.activityLevel ?? "")
                
                if let bmi = viewModel.userGoals?.targetBmi {
                    HStack {
                        Text("Target BMI")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(String(format: "%.2f", bmi))
                    }
                }
            }
            
            Section(header: Text("Macro Goals")) {
                if let protein = viewModel.userGoals?.proteinGoalG {
                    macroRow(title: "Protein", value: "\(Int(protein))g")
                }
                if let carbs = viewModel.userGoals?.carbsGoalG {
                    macroRow(title: "Carbs", value: "\(Int(carbs))g")
                }
                if let fats = viewModel.userGoals?.fatsGoalG {
                    macroRow(title: "Fats", value: "\(Int(fats))g")
                }
                if let fiber = viewModel.userGoals?.fiberGoalG {
                    macroRow(title: "Fiber", value: "\(Int(fiber))g")
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("My Goals")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingEditSheet) {
            GoalEditSheet(
                field: editingField ?? .weightGoal,
                value: $editValue,
                onSave: saveGoal
            )
        }
        .onAppear {
            viewModel.fetchUserGoals()
        }
    }
    
    private func goalRow(field: GoalField, value: String) -> some View {
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
    
    private func macroRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
        }
    }
    
    private func formatHeightGoal() -> String {
        if let height = viewModel.userGoals?.heightGoalCm {
            return "\(Int(height)) cm"
        }
        return ""
    }
    
    private func formatWeightGoal() -> String {
        if let weight = viewModel.userGoals?.weightGoalKg {
            return "\(Int(weight)) kg"
        }
        return ""
    }
    
    private func formatCalorieTarget() -> String {
        if let calories = viewModel.userGoals?.calorieTargetKcal {
            return "\(Int(calories)) kcal"
        }
        return ""
    }
    
    private func saveGoal() {
        guard let field = editingField else { return }
        
        var updates: [String: Any] = [:]
        let numericValue = editValue.replacingOccurrences(of: "[^0-9.]", with: "", options: .regularExpression)
        
        switch field {
        case .heightGoal:
            if let value = Double(numericValue) {
                updates["height_goal_cm"] = value
            }
        case .weightGoal:
            if let value = Double(numericValue) {
                updates["weight_goal_kg"] = value
            }
        case .calorieTarget:
            if let value = Double(numericValue) {
                updates["calorie_target_kcal"] = value
            }
        case .weeklyGoal:
            updates["weekly_goal"] = editValue
        case .activityLevel:
            updates["activity_level"] = editValue
        }
        
        if !updates.isEmpty {
            viewModel.updateUserGoals(updates)
        }
        
        showingEditSheet = false
    }
}

struct GoalEditSheet: View {
    let field: MyGoalsView.GoalField
    @Binding var value: String
    let onSave: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text(field.rawValue)
                    .font(.headline)
                
                if field == .weeklyGoal {
                    Picker("Weekly Goal", selection: $value) {
                        Text("Lose 0.5 kg").tag("Lose 0.5 kg")
                        Text("Lose 1 kg").tag("Lose 1 kg")
                        Text("Maintain").tag("Maintain")
                        Text("Gain 0.5 kg").tag("Gain 0.5 kg")
                        Text("Gain 1 kg").tag("Gain 1 kg")
                    }
                    .pickerStyle(.wheel)
                } else if field == .activityLevel {
                    Picker("Activity Level", selection: $value) {
                        Text("Sedentary").tag("Sedentary")
                        Text("Lightly Active").tag("Lightly Active")
                        Text("Active").tag("Active")
                        Text("Very Active").tag("Very Active")
                    }
                    .pickerStyle(.wheel)
                } else {
                    TextField(field.rawValue, text: $value)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.decimalPad)
                        .padding(.horizontal)
                }
                
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
        .presentationDetents([.medium])
    }
}
