//
//  LikedFoodsView.swift
//  iPlate
//
//  Created by Lukesh D on 27/01/26.
//

// iPlate/Views/Profile/LikedFoodsView.swift
import SwiftUI

struct LikedFoodsView: View {
    @StateObject private var viewModel = ProfileViewModel.shared
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(viewModel.likedFoods) { food in
                    LikedFoodCard(food: food) {
                        viewModel.removeLikedFood(food.food)
                    }
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Liked Foods")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.fetchLikedFoods()
        }
    }
}

struct LikedFoodCard: View {
    let food: LikedFood
    let onUnlike: () -> Void
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Food Image
            if let imageUrl = food.imageUrl?.replacingOccurrences(of: "{", with: "").replacingOccurrences(of: "}", with: ""),
               let url = URL(string: imageUrl) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color(.systemGray5))
                }
                .frame(height: 180)
                .clipped()
            } else {
                Rectangle()
                    .fill(Color(.systemGray5))
                    .frame(height: 180)
                    .overlay(
                        Image(systemName: "photo")
                            .font(.largeTitle)
                            .foregroundColor(.gray)
                    )
            }
            
            // Gradient overlay
            LinearGradient(
                gradient: Gradient(colors: [.clear, .black.opacity(0.7)]),
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 80)
            .frame(maxHeight: .infinity, alignment: .bottom)
            
            // Food info
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(food.food)
                        .font(.headline)
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                Button(action: onUnlike) {
                    Image(systemName: "heart.fill")
                        .foregroundColor(.orange)
                        .font(.title2)
                }
            }
            .padding()
        }
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}
