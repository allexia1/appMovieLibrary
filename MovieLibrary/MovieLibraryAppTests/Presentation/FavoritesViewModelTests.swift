//
//  FavoritesViewModelTests.swift
//  MovieLibraryApp
//
//  Created by Allexia Azevedo de Morais on 16/07/26.
//

import Testing
@testable import MovieLibraryApp

@MainActor
@Suite
struct FavoritesViewModelTests {
    @Test
    func loadFavorites_withItemsInStore_setsContentState() async {
        let store = FavoriteMoviesStoreSpy()
        store.setFavoriteMovies([.fixture(id: 1), .fixture(id: 2)])
        let sut = FavoritesViewModel(favoriteMoviesStore: store)

        await sut.loadFavorites()

        guard case .content(let items, _, _) = sut.state else {
            Issue.record("Expected content state")
            return
        }
        #expect(items.count == 2)
        #expect(store.loadFavoritesIfNeededCallCount == 1)
    }

    @Test
    func loadFavorites_withEmptyStore_setsEmptyState() async {
        let store = FavoriteMoviesStoreSpy()
        let sut = FavoritesViewModel(favoriteMoviesStore: store)

        await sut.loadFavorites()

        guard case .empty = sut.state else {
            Issue.record("Expected empty state")
            return
        }
    }

    @Test
    func loadFavorites_onRepositoryFailure_setsErrorState() async {
        let store = FavoriteMoviesStoreSpy()
        store.loadError = TestLocalizedError(message: "Failed to load favorites")
        let sut = FavoritesViewModel(favoriteMoviesStore: store)

        await sut.loadFavorites()

        guard case .error(let message) = sut.state else {
            Issue.record("Expected error state")
            return
        }
        #expect(message == "Failed to load favorites")
    }

    @Test
    func toggleFavorite_removingItem_updatesListInStore() async {
        let movie1 = MovieItem.fixture(id: 1)
        let movie2 = MovieItem.fixture(id: 2)
        let store = FavoriteMoviesStoreSpy()
        store.setFavoriteMovies([movie1, movie2])
        let sut = FavoritesViewModel(favoriteMoviesStore: store)
        await sut.loadFavorites()

        await sut.toggleFavorite(for: movie1)

        guard case .content(let items, _, _) = sut.state else {
            Issue.record("Expected content state")
            return
        }
        #expect(items.map(\.id) == [2])
        #expect(store.removeFavoriteCallCount == 1)
    }

    @Test
    func toggleFavorite_removingLastItem_setsEmptyState() async {
        let movie = MovieItem.fixture(id: 1)
        let store = FavoriteMoviesStoreSpy()
        store.setFavoriteMovies([movie])
        let sut = FavoritesViewModel(favoriteMoviesStore: store)
        await sut.loadFavorites()

        await sut.toggleFavorite(for: movie)

        guard case .empty = sut.state else {
            Issue.record("Expected empty state")
            return
        }
    }

    @Test
    func refreshFromStore_reflectsCurrentStoreContents() async {
        let store = FavoriteMoviesStoreSpy()
        let sut = FavoritesViewModel(favoriteMoviesStore: store)
        await sut.loadFavorites()

        store.setFavoriteMovies([.fixture(id: 9)])
        sut.refreshFromStore()

        guard case .content(let items, _, _) = sut.state else {
            Issue.record("Expected content state")
            return
        }
        #expect(items.map(\.id) == [9])
    }

    @Test
    func toggleFavorite_whenStoreThrows_keepsItemInListAndDoesNotCrash() async {
        let movie = MovieItem.fixture(id: 1)
        let store = FavoriteMoviesStoreSpy()
        store.setFavoriteMovies([movie])
        store.removeFavoriteError = TestLocalizedError(message: "Failed to remove favorite")
        let sut = FavoritesViewModel(favoriteMoviesStore: store)
        await sut.loadFavorites()

        await sut.toggleFavorite(for: movie)

        guard case .content(let items, _, _) = sut.state else {
            Issue.record("Expected content state")
            return
        }
        #expect(store.removeFavoriteCallCount == 1)
        #expect(items.map(\.id) == [1])
    }
}
