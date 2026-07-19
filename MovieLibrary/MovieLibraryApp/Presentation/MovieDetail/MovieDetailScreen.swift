//
//  MovieDetailScreen.swift
//  MovieLibraryApp
//

import SwiftUI

struct MovieDetailScreen: View {
    let viewModel: MovieDetailViewModel

    @State private var isOverviewExpanded = false

    private let overviewCollapsedLineLimit = 4
    private let readMoreCharacterThreshold = 180

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                heroSection
                metaSection
                genresSection
                overviewSection
            }
            .padding(.bottom, 32)
        }
        .task { await viewModel.loadHeroImage() }
    }

    private var heroSection: some View {
        ZStack(alignment: .bottomLeading) {
            heroImageView
                .aspectRatio(1.0 / 1.2, contentMode: .fit)
                .frame(maxWidth: .infinity)
                .clipped()
                .ignoresSafeArea(edges: .top)
                .overlay(
                    LinearGradient(colors: [.clear, .black.opacity(0.75)], startPoint: .top, endPoint: .bottom)
                )

            Text(viewModel.movie.title)
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(.white)
                .lineLimit(3)
                .padding(16)
        }
        .overlay(alignment: .topTrailing) {
            favoriteButton.padding(16)
        }
    }

    private var heroImageView: some View {
        Group {
            if let heroImage = viewModel.heroImage {
                Image(uiImage: heroImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                Image(systemName: "film")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .padding(64)
                    .foregroundStyle(.secondary)
                    .background(Color(.tertiarySystemBackground))
            }
        }
    }

    private var favoriteButton: some View {
        Button {
            Task { await viewModel.toggleFavorite() }
        } label: {
            Image(systemName: viewModel.movie.isFavorite ? "heart.fill" : "heart")
                .foregroundStyle(.white)
                .frame(width: 40, height: 40)
                .background(Color.black.opacity(0.45))
                .clipShape(Circle())
        }
        .accessibilityLabel(viewModel.movie.isFavorite ? LocalizedStrings.favoriteButtonRemove : LocalizedStrings.favoriteButtonAdd)
    }

    private var metaSection: some View {
        HStack(spacing: 12) {
            Text(viewModel.movie.releaseYear.map(String.init) ?? "—")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack(spacing: 4) {
                Image(systemName: "star.fill").foregroundStyle(.yellow)
                Text(String(format: "%.1f", viewModel.movie.rating))
                    .font(.system(size: 15, weight: .semibold))
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .padding(.horizontal, 16)
    }

    private var genresSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(LocalizedStrings.movieDetailGenresTitle).font(.headline)
            HStack(spacing: 8) {
                ForEach(viewModel.movie.genres, id: \.self) { genre in
                    Text(genre)
                        .font(.system(size: 13, weight: .medium))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
        .padding(.horizontal, 16)
    }

    private var overviewSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(LocalizedStrings.movieDetailOverviewTitle).font(.headline)
            Text(viewModel.movie.overview)
                .font(.body)
                .lineLimit(isOverviewExpanded ? nil : overviewCollapsedLineLimit)

            if viewModel.movie.overview.count >= readMoreCharacterThreshold {
                Button(isOverviewExpanded ? LocalizedStrings.movieDetailReadLess : LocalizedStrings.movieDetailReadMore) {
                    isOverviewExpanded.toggle()
                }
            }
        }
        .padding(.horizontal, 16)
    }
}
