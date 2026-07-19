//
//  FavoritesViewModel.swift
//  MovieLibraryApp
//
//  Created by Allexia Azevedo de Morais on 16/07/26.
//

import Foundation
import Observation

@MainActor
@Observable
final class FavoritesViewModel {
    private(set) var state: ScreenState<MovieItem> = .loading

    private let favoriteMoviesStore: FavoriteMoviesStoreProtocol

    init(favoriteMoviesStore: FavoriteMoviesStoreProtocol) {
        self.favoriteMoviesStore = favoriteMoviesStore
    }

    func loadFavorites() async {
        state = .loading
        do {
            try await favoriteMoviesStore.loadFavoritesIfNeeded()
            refreshFromStore()
        } catch {
            let message = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            state = .error(message)
        }
    }

    func refreshFromStore() {
        let movies = favoriteMoviesStore.favoriteMovies
        state = movies.isEmpty ? .empty : .content(items: movies, isLoadingNextPage: false, paginationErrorMessage: nil)
    }

    func toggleFavorite(for movie: MovieItem) async {
        do {
            try await favoriteMoviesStore.removeFavorite(id: movie.id)
            refreshFromStore()
        } catch {
            // Keep the item unchanged; the user can try again.
        }
    }
}
