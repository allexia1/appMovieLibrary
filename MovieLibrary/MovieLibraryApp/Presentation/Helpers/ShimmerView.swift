//
//  ShimmerView.swift
//  MovieLibraryApp
//

import SwiftUI

/// Placeholder animado exibido enquanto um pôster está carregando.
struct ShimmerView: View {
    @State private var isAnimating = false

    var body: some View {
        LinearGradient(
            colors: [Color(.systemGray5), Color(.systemGray4), Color(.systemGray5)],
            startPoint: isAnimating ? .leading : .trailing,
            endPoint: isAnimating ? .trailing : .leading
        )
        .onAppear {
            withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) {
                isAnimating = true
            }
        }
    }
}
