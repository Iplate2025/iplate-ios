// iPlate/Views/MainTabView.swift
import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                HomeView()
                    .tag(0)
                
                AnalyticsView()
                    .tag(1)
                
                Color.clear
                    .tag(2)
                
                SearchView()
                    .tag(3)
                
                ProfileView()
                    .tag(4)
            }
            
            // Custom Tab Bar
            customTabBar
        }
    }
    
    private var customTabBar: some View {
        HStack {
            tabButton(icon: "house", title: "Home", tag: 0)
            tabButton(icon: "chart.line.uptrend.xyaxis", title: "Analytics", tag: 1)
            
            // Center Add Button
            Button {
                // Add action
            } label: {
                ZStack {
                    Circle()
                        .fill(Color.orange)
                        .frame(width: 56, height: 56)
                    
                    Image(systemName: "plus")
                        .font(.title2)
                        .foregroundColor(.white)
                }
            }
            .offset(y: -20)
            
            tabButton(icon: "magnifyingglass", title: "Search", tag: 3)
            tabButton(icon: "person.fill", title: "Profile", tag: 4)
        }
        .padding(.horizontal)
        .padding(.top, 8)
        .background(
            Color(.systemBackground)
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: -5)
        )
    }
    
    private func tabButton(icon: String, title: String, tag: Int) -> some View {
        Button {
            selectedTab = tag
        } label: {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                Text(title)
                    .font(.caption2)
            }
            .foregroundColor(selectedTab == tag ? .orange : .gray)
            .frame(maxWidth: .infinity)
        }
    }
}

#Preview {
    MainTabView()
}
