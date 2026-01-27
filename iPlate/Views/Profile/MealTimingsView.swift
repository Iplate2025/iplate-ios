//
//  MealTimingsView.swift
//  iPlate
//
//  Created by Lukesh D on 27/01/26.
//

// iPlate/Views/Profile/MealTimingsView.swift
import SwiftUI

struct MealTimingsView: View {
    @StateObject private var viewModel = ProfileViewModel.shared
    @State private var showingTimePicker = false
    @State private var editingMeal: String = ""
    @State private var editingIsStart: Bool = true
    @State private var selectedTime = Date()
    
    var mealTimings: [MealTiming] {
        guard let details = viewModel.userDetails else { return [] }
        return [
            MealTiming(name: "Breakfast",
                      startTime: details.breakfastStart ?? "07:00:00",
                      endTime: details.breakfastEnd ?? "09:30:00",
                      startKey: "breakfast_start",
                      endKey: "breakfast_end"),
            MealTiming(name: "Morning Snack",
                      startTime: details.morningSnackStart ?? "10:00:00",
                      endTime: details.morningSnackEnd ?? "11:00:00",
                      startKey: "morning_snack_start",
                      endKey: "morning_snack_end"),
            MealTiming(name: "Lunch",
                      startTime: details.lunchStart ?? "12:00:00",
                      endTime: details.lunchEnd ?? "14:00:00",
                      startKey: "lunch_start",
                      endKey: "lunch_end"),
            MealTiming(name: "Evening Snack",
                      startTime: details.eveningSnackStart ?? "16:00:00",
                      endTime: details.eveningSnackEnd ?? "17:30:00",
                      startKey: "evening_snack_start",
                      endKey: "evening_snack_end"),
            MealTiming(name: "Dinner",
                      startTime: details.dinnerStart ?? "19:00:00",
                      endTime: details.dinnerEnd ?? "22:00:00",
                      startKey: "dinner_start",
                      endKey: "dinner_end")
        ]
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                ForEach(mealTimings) { meal in
                    mealSection(meal: meal)
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Meal Timings")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingTimePicker) {
            TimePickerSheet(
                mealName: editingMeal,
                isStart: editingIsStart,
                selectedTime: $selectedTime,
                onSave: saveTime
            )
        }
        .onAppear {
            viewModel.fetchUserDetails()
        }
    }
    
    private func mealSection(meal: MealTiming) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(meal.name)
                .font(.headline)
                .padding(.bottom, 8)
            
            VStack(spacing: 0) {
                timeRow(label: "From", time: meal.startTime, meal: meal, isStart: true)
                Divider()
                timeRow(label: "To", time: meal.endTime, meal: meal, isStart: false)
            }
            .background(Color(.systemBackground))
            .cornerRadius(12)
        }
    }
    
    private func timeRow(label: String, time: String, meal: MealTiming, isStart: Bool) -> some View {
        Button {
            editingMeal = isStart ? meal.startKey : meal.endKey
            editingIsStart = isStart
            selectedTime = parseTime(time)
            showingTimePicker = true
        } label: {
            HStack {
                Text(label)
                    .foregroundColor(.secondary)
                Spacer()
                Text(formatTimeForDisplay(time))
                    .foregroundColor(.primary)
                Image(systemName: "pencil")
                    .foregroundColor(.orange)
                    .font(.caption)
            }
            .padding()
        }
    }
    
    private func parseTime(_ timeString: String) -> Date {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.date(from: timeString) ?? Date()
    }
    
    private func formatTimeForDisplay(_ timeString: String) -> String {
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "HH:mm:ss"
        
        let outputFormatter = DateFormatter()
        outputFormatter.dateFormat = "h:mm a"
        
        if let date = inputFormatter.date(from: timeString) {
            return outputFormatter.string(from: date)
        }
        return timeString
    }
    
    private func saveTime() {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        let timeString = formatter.string(from: selectedTime)
        
        viewModel.updateUserDetails([editingMeal: timeString])
        showingTimePicker = false
    }
}

struct TimePickerSheet: View {
    let mealName: String
    let isStart: Bool
    @Binding var selectedTime: Date
    let onSave: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Select \(isStart ? "Start" : "End") Time")
                    .font(.headline)
                
                DatePicker("", selection: $selectedTime, displayedComponents: .hourAndMinute)
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                
                HStack(spacing: 16) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGray5))
                    .cornerRadius(10)
                    
                    Button("Save") {
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
            }
            .padding()
        }
        .presentationDetents([.medium])
    }
}
