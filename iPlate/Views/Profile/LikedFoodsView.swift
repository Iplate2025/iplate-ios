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
        VStack(alignment: .leading, spacing: 0) {
            // Food Image
            if let imageUrl = food.imageUrl?.replacingOccurrences(of: "{", with: "").replacingOccurrences(of: "}", with: ""),
               let url = URL(string: imageUrl) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        Rectangle()
                            .fill(Color(.systemGray5))
                            .frame(height: 180)
                            .overlay(ProgressView())
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 180)
                            .clipped()
                    case .failure:
                        Rectangle()
                            .fill(Color(.systemGray5))
                            .frame(height: 180)
                            .overlay(
                                Image(systemName: "photo")
                                    .font(.largeTitle)
                                    .foregroundColor(.gray)
                            )
                    @unknown default:
                        EmptyView()
                    }
                }
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
            
            // Food Details
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(food.food)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    /* Calories not available in API response yet
                    Text("200 cal")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    */
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
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}
