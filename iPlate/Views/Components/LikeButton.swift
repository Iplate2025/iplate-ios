//
//  LikeButton.swift
//  iPlate
//
//  Created by Lukesh D on 27/01/26.
//

// iPlate/Views/Components/LikeButton.swift
import SwiftUI

struct LikeButton: View {
    let foodName: String
    @StateObject private var viewModel = ProfileViewModel.shared
    @State private var isLiked: Bool = false
    @State private var isLoading: Bool = false
    
    var body: some View {
        Button {
            toggleLike()
        } label: {
            if isLoading {
                ProgressView()
                    .frame(width: 24, height: 24)
            } else {
                Image(systemName: isLiked ? "heart.fill" : "heart")
                    .foregroundColor(isLiked ? .red : .gray)
                    .font(.title2)
            }
        }
        .disabled(isLoading)
        .onAppear {
            isLiked = viewModel.isFoodLiked(foodName)
        }
        .onChange(of: viewModel.likedFoods) { _ in
            isLiked = viewModel.isFoodLiked(foodName)
        }
    }
    
    private func toggleLike() {
        isLoading = true
        
        if isLiked {
            viewModel.removeLikedFood(foodName) { success in
                isLoading = false
                if success {
                    isLiked = false
                }
            }
        } else {
            viewModel.addLikedFood(foodName) { success in
                isLoading = false
                if success {
                    isLiked = true
                }
            }
        }
    }
}
