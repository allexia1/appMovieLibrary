//
//  FavoriteMoviesStoreSpy.swift
//  MovieLibraryApp
//
//  Created by Allexia Azevedo de Morais on 16/07/26.
//

@testable import MovieLibraryApp

@MainActor
final class FavoriteMoviesStoreSpy: FavoriteMoviesStoreProtocol {
    private(set) var favoriteMovies: [MovieItem] = []
    private(set) var loadFavoritesIfNeededCallCount = 0
    private(set) var addFavoriteCallCount = 0
    private(set) var removeFavoriteCallCount = 0

    var loadError: Error?
    var addFavoriteError: Error?
    var removeFavoriteError: Error?

    func setFavoriteMovies(_ movies: [MovieItem]) {
        favoriteMovies = movies
    }

    func loadFavoritesIfNeeded() async throws {
        loadFavoritesIfNeededCallCount += 1
        if let loadError { throw loadError }
    }

    func isFavorite(id: Int) -> Bool {
        favoriteMovies.contains { $0.id == id }
    }

    func addFavorite(_ movie: MovieItem) async throws {
        addFavoriteCallCount += 1
        if let addFavoriteError { throw addFavoriteError }
        favoriteMovies.insert(movie.updatingFavorite(to: true), at: 0)
    }

    func removeFavorite(id: Int) async throws {
        removeFavoriteCallCount += 1
        if let removeFavoriteError { throw removeFavoriteError }
        favoriteMovies.removeAll { $0.id == id }
    }
}
