//
//  MovieCardView.swift
//  MovieLibraryApp
//

import SwiftUI

struct MovieCardView: View {
    let movie: MovieItem
    let imageLoader: ImageLoadingProtocol
    let onFavoriteToggle: () -> Void

    @State private var isFavoriteBouncing = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            posterView
            Text(movie.title)
                .font(.footnote)
                .foregroundStyle(.primary)
                .lineLimit(2)
        }
        .padding(6)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.15), radius: 6, x: 0, y: 3)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            LocalizedStrings.movieCellAccessibilityLabel(title: movie.title, rating: String(format: "%.1f", movie.rating))
        )
        .accessibilityAction(named: Text(movie.isFavorite ? LocalizedStrings.favoriteButtonRemove : LocalizedStrings.favoriteButtonAdd)) {
            toggleFavorite()
        }
    }

    private var posterView: some View {
        CachedAsyncImage(url: movie.posterURL, imageLoader: imageLoader) { image in
            image.resizable().aspectRatio(contentMode: .fill)
        } placeholder: {
            ShimmerView()
        }
        .aspectRatio(1.0 / 1.5, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(alignment: .topLeading) { favoriteButton.padding(6) }
        .overlay(alignment: .topTrailing) { ratingBadge.padding(6) }
    }

    private var ratingBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: "star.fill")
                .foregroundStyle(.yellow)
            Text(String(format: "%.1f", movie.rating))
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
        .background(Color.black.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func toggleFavorite() {
        isFavoriteBouncing = true
        onFavoriteToggle()
        withAnimation(.easeOut(duration: 0.12)) { isFavoriteBouncing = false }
    }

    private var favoriteButton: some View {
        Button {
            toggleFavorite()
        } label: {
            Image(systemName: movie.isFavorite ? "heart.fill" : "heart")
                .foregroundStyle(.white)
                .frame(width: 32, height: 32)
                .background(Color.black.opacity(0.4))
                .clipShape(Circle())
                .scaleEffect(isFavoriteBouncing ? 1.3 : 1.0)
        }
        .buttonStyle(.borderless)
        .accessibilityLabel(movie.isFavorite ? LocalizedStrings.favoriteButtonRemove : LocalizedStrings.favoriteButtonAdd)
    }
}
