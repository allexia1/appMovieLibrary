//
//  FavoriteMoviesStoreTests.swift
//  MovieLibraryApp
//
//  Created by Allexia Azevedo de Morais on 16/07/26.
//

import Testing
@testable import MovieLibraryApp

@MainActor
@Suite
struct FavoriteMoviesStoreTests {
    @Test
    func loadFavoritesIfNeeded_fetchesFromRepositoryOnce_evenWithMultipleCalls() async throws {
        let repository = FavoriteMoviesRepositorySpy()
        repository.favoriteMoviesToReturn = .success([.fixture(id: 1), .fixture(id: 2)])
        let sut = FavoriteMoviesStore(repository: repository)

        try await sut.loadFavoritesIfNeeded()
        try await sut.loadFavoritesIfNeeded()

        #expect(repository.fetchFavoriteMoviesCallCount == 1)
        #expect(sut.favoriteMovies.count == 2)
    }

    @Test
    func addFavorite_updatesInMemoryCache_withoutRefetching() async throws {
        let repository = FavoriteMoviesRepositorySpy()
        let sut = FavoriteMoviesStore(repository: repository)
        try await sut.loadFavoritesIfNeeded()

        let newFavorite = MovieItem.fixture(id: 7, isFavorite: false)
        try await sut.addFavorite(newFavorite)

        #expect(sut.isFavorite(id: 7) == true)
        #expect(repository.savedMovies.map(\.id) == [7])
        #expect(repository.fetchFavoriteMoviesCallCount == 1)
    }

    @Test
    func removeFavorite_updatesInMemoryCache() async throws {
        let repository = FavoriteMoviesRepositorySpy()
        repository.favoriteMoviesToReturn = .success([.fixture(id: 1)])
        let sut = FavoriteMoviesStore(repository: repository)
        try await sut.loadFavoritesIfNeeded()

        try await sut.removeFavorite(id: 1)

        #expect(sut.isFavorite(id: 1) == false)
        #expect(sut.favoriteMovies.isEmpty)
        #expect(repository.removedIDs == [1])
    }
}
