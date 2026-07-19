//
//  FavoriteMoviesRepositorySpy.swift
//  MovieLibraryApp
//
//  Created by Allexia Azevedo de Morais on 16/07/26.
//

@testable import MovieLibraryApp

final class FavoriteMoviesRepositorySpy: FavoriteMoviesRepositoryProtocol, @unchecked Sendable {
    private(set) var fetchFavoriteMoviesCallCount = 0
    private(set) var fetchFavoriteMovieIDsCallCount = 0
    private(set) var savedMovies: [MovieItem] = []
    private(set) var removedIDs: [Int] = []

    var favoriteMoviesToReturn: Result<[MovieItem], Error> = .success([])
    var favoriteIDsToReturn: Result<Set<Int>, Error> = .success([])
    var saveResult: Result<Void, Error> = .success(())
    var removeResult: Result<Void, Error> = .success(())

    func fetchFavoriteMovies() async throws -> [MovieItem] {
        fetchFavoriteMoviesCallCount += 1
        return try favoriteMoviesToReturn.get()
    }

    func fetchFavoriteMovieIDs() async throws -> Set<Int> {
        fetchFavoriteMovieIDsCallCount += 1
        return try favoriteIDsToReturn.get()
    }

    func saveFavorite(_ movie: MovieItem) async throws {
        try saveResult.get()
        savedMovies.append(movie)
    }

    func removeFavorite(id: Int) async throws {
        try removeResult.get()
        removedIDs.append(id)
    }
}
