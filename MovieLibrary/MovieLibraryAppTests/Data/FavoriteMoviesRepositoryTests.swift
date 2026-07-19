//
//  FavoriteMoviesRepositoryTests.swift
//  MovieLibraryApp
//
//  Created by Allexia Azevedo de Morais on 16/07/26.
//

import Testing
import SwiftData
@testable import MovieLibraryApp

@Suite(.serialized)
struct FavoriteMoviesRepositoryTests {
    private func makeInMemoryContainer() throws -> ModelContainer {
        let schema = Schema([FavoriteMovieObj.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: [configuration])
    }

    @Test
    func saveFavorite_thenFetch_returnsSavedMovie() async throws {
        let sut = FavoriteMoviesRepository(modelContainer: try makeInMemoryContainer())
        let movie = MovieItem.fixture(id: 1, title: "Movie A")

        try await sut.saveFavorite(movie)
        let favorites = try await sut.fetchFavoriteMovies()

        #expect(favorites.count == 1)
        #expect(favorites.first?.id == 1)
        #expect(favorites.first?.title == "Movie A")
        #expect(favorites.first?.isFavorite == true)
    }

    @Test
    func saveFavorite_withExistingID_updatesInsteadOfDuplicating() async throws {
        let sut = FavoriteMoviesRepository(modelContainer: try makeInMemoryContainer())
        try await sut.saveFavorite(.fixture(id: 1, title: "Original Title"))
        try await sut.saveFavorite(.fixture(id: 1, title: "Updated Title"))

        let favorites = try await sut.fetchFavoriteMovies()

        #expect(favorites.count == 1)
        #expect(favorites.first?.title == "Updated Title")
    }

    @Test
    func removeFavorite_deletesFromStorage() async throws {
        let sut = FavoriteMoviesRepository(modelContainer: try makeInMemoryContainer())
        try await sut.saveFavorite(.fixture(id: 1))

        try await sut.removeFavorite(id: 1)
        let favorites = try await sut.fetchFavoriteMovies()

        #expect(favorites.isEmpty)
    }

    @Test
    func fetchFavoriteMovieIDs_returnsAllSavedIDs() async throws {
        let sut = FavoriteMoviesRepository(modelContainer: try makeInMemoryContainer())
        try await sut.saveFavorite(.fixture(id: 1))
        try await sut.saveFavorite(.fixture(id: 2))

        let ids = try await sut.fetchFavoriteMovieIDs()

        #expect(ids == [1, 2])
    }

    @Test
    func fetchFavoriteMovies_ordersByFavoritedAtDescending() async throws {
        let sut = FavoriteMoviesRepository(modelContainer: try makeInMemoryContainer())
        try await sut.saveFavorite(.fixture(id: 1, title: "Saved first"))
        try await Task.sleep(nanoseconds: 20_000_000)
        try await sut.saveFavorite(.fixture(id: 2, title: "Saved later"))

        let favorites = try await sut.fetchFavoriteMovies()

        #expect(favorites.map(\.id) == [2, 1])
    }
}
