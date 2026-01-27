//
//  NotificationsView.swift
//  iPlate
//
//  Created by Lukesh D on 27/01/26.
//

// iPlate/Views/Profile/NotificationsView.swift
import SwiftUI

struct NotificationsView: View {
    @AppStorage("mealReminders") private var mealReminders = true
    @AppStorage("goalReminders") private var goalReminders = true
    @AppStorage("weeklyReports") private var weeklyReports = false
    
    var body: some View {
        List {
            Section {
                Toggle("Meal Reminders", isOn: $mealReminders)
                Toggle("Goal Reminders", isOn: $goalReminders)
                Toggle("Weekly Reports", isOn: $weeklyReports)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
    }
}
