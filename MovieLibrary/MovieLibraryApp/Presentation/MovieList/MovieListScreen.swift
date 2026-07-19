//
//  MovieListScreen.swift
//  MovieLibraryApp
//

import SwiftUI

struct MovieListScreen: View {
    let viewModel: MovieListViewModel
    let imageLoader: ImageLoadingProtocol

    @State private var searchText = ""

    var body: some View {
        MovieGridView(
            state: viewModel.state,
            imageLoader: imageLoader,
            emptyStateTitle: LocalizedStrings.moviesEmptyTitle,
            emptyStateSubtitle: LocalizedStrings.moviesEmptySubtitle,
            onToggleFavorite: { movie in Task { await viewModel.toggleFavorite(for: movie) } },
            onReachLoadMoreThreshold: { index in Task { await viewModel.loadNextPageIfNeeded(currentIndex: index) } },
            onRefresh: { await viewModel.refresh() },
            onRetry: { Task { await viewModel.loadInitialMovies() } },
            onDismissPaginationError: { viewModel.dismissPaginationError() }
        )
        .navigationTitle(LocalizedStrings.moviesTabTitle)
        .searchable(
            text: $searchText,
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: LocalizedStrings.moviesSearchPlaceholder
        )
        .onChange(of: searchText) { _, newValue in
            viewModel.search(query: newValue)
        }
        .task {
            if case .loading = viewModel.state {
                await viewModel.loadInitialMovies()
            }
        }
        .onAppear { viewModel.refreshFavoriteStatuses() }
    }
}
