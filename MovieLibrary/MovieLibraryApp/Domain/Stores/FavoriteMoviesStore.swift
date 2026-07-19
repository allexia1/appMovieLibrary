//
//  FavoriteMoviesStore.swift
//  MovieLibraryApp
//
//  Created by Allexia Azevedo de Morais on 16/07/26.
//

@MainActor
final class FavoriteMoviesStore: FavoriteMoviesStoreProtocol {
    private let repository: FavoriteMoviesRepositoryProtocol
    private(set) var favoriteMovies: [MovieItem] = []
    private var hasLoadedFavorites = false

    init(repository: FavoriteMoviesRepositoryProtocol) {
        self.repository = repository
    }

    func loadFavoritesIfNeeded() async throws {
        guard !hasLoadedFavorites else { return }
        favoriteMovies = try await repository.fetchFavoriteMovies()
        hasLoadedFavorites = true
    }

    func isFavorite(id: Int) -> Bool {
        favoriteMovies.contains { $0.id == id }
    }

    func addFavorite(_ movie: MovieItem) async throws {
        try await repository.saveFavorite(movie)
        let favoritedMovie = movie.updatingFavorite(to: true)
        if let index = favoriteMovies.firstIndex(where: { $0.id == movie.id }) {
            favoriteMovies[index] = favoritedMovie
        } else {
            favoriteMovies.insert(favoritedMovie, at: 0)
        }
    }

    func removeFavorite(id: Int) async throws {
        try await repository.removeFavorite(id: id)
        favoriteMovies.removeAll { $0.id == id }
    }
}
