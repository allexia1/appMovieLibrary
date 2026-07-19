//
//  FavoritesScreen.swift
//  MovieLibraryApp
//

import SwiftUI

struct FavoritesScreen: View {
    let viewModel: FavoritesViewModel
    let imageLoader: ImageLoadingProtocol

    var body: some View {
        MovieGridView(
            state: viewModel.state,
            imageLoader: imageLoader,
            emptyStateTitle: LocalizedStrings.favoritesEmptyTitle,
            emptyStateSubtitle: LocalizedStrings.favoritesEmptySubtitle,
            onToggleFavorite: { movie in Task { await viewModel.toggleFavorite(for: movie) } },
            onReachLoadMoreThreshold: { _ in
                // Favoritos não paginam: a lista completa já vem do FavoriteMoviesStore em memória.
            },
            onRefresh: { viewModel.refreshFromStore() },
            onRetry: { Task { await viewModel.loadFavorites() } },
            onDismissPaginationError: {}
        )
        .navigationTitle(LocalizedStrings.favoritesTabTitle)
        .task {
            if case .loading = viewModel.state {
                await viewModel.loadFavorites()
            }
        }
        .onAppear { viewModel.refreshFromStore() }
    }
}
