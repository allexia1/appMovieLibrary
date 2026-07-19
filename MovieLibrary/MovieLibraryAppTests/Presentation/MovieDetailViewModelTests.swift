//
//  MovieDetailViewModelTests.swift
//  MovieLibraryApp
//

import UIKit
import Testing
@testable import MovieLibraryApp

@MainActor
@Suite
struct MovieDetailViewModelTests {
    @Test
    func init_derivesFavoriteStatusFromStore() {
        let store = FavoriteMoviesStoreSpy()
        store.setFavoriteMovies([.fixture(id: 1)])
        let sut = MovieDetailViewModel(
            movie: .fixture(id: 1, isFavorite: false),
            favoriteMoviesStore: store,
            imageLoader: ImageLoaderSpy()
        )

        #expect(sut.movie.isFavorite == true)
    }

    @Test
    func loadHeroImage_onSuccess_setsHeroImage() async {
        let imageLoader = ImageLoaderSpy()
        let sut = MovieDetailViewModel(
            movie: .fixture(id: 1),
            favoriteMoviesStore: FavoriteMoviesStoreSpy(),
            imageLoader: imageLoader
        )

        await sut.loadHeroImage()

        #expect(sut.heroImage != nil)
        #expect(imageLoader.loadImageCallCount == 1)
    }

    @Test
    func loadHeroImage_withNoPosterURL_doesNotCallImageLoader() async {
        let imageLoader = ImageLoaderSpy()
        let movie = MovieItem.fixture(id: 1, posterURL: nil)
        let sut = MovieDetailViewModel(
            movie: movie,
            favoriteMoviesStore: FavoriteMoviesStoreSpy(),
            imageLoader: imageLoader
        )

        await sut.loadHeroImage()

        #expect(sut.heroImage == nil)
        #expect(imageLoader.loadImageCallCount == 0)
    }

    @Test
    func toggleFavorite_addingFavorite_updatesMovieAndCallsStore() async {
        let store = FavoriteMoviesStoreSpy()
        let movie = MovieItem.fixture(id: 1, isFavorite: false)
        let sut = MovieDetailViewModel(movie: movie, favoriteMoviesStore: store, imageLoader: ImageLoaderSpy())

        await sut.toggleFavorite()

        #expect(sut.movie.isFavorite == true)
        #expect(store.addFavoriteCallCount == 1)
    }

    @Test
    func toggleFavorite_removingFavorite_updatesMovieAndCallsStore() async {
        let store = FavoriteMoviesStoreSpy()
        let movie = MovieItem.fixture(id: 1, isFavorite: true)
        store.setFavoriteMovies([movie])
        let sut = MovieDetailViewModel(movie: movie, favoriteMoviesStore: store, imageLoader: ImageLoaderSpy())

        await sut.toggleFavorite()

        #expect(sut.movie.isFavorite == false)
        #expect(store.removeFavoriteCallCount == 1)
    }

    @Test
    func toggleFavorite_whenStoreThrows_keepsPreviousState() async {
        let store = FavoriteMoviesStoreSpy()
        store.addFavoriteError = TestLocalizedError(message: "Failed to favorite")
        let movie = MovieItem.fixture(id: 1, isFavorite: false)
        let sut = MovieDetailViewModel(movie: movie, favoriteMoviesStore: store, imageLoader: ImageLoaderSpy())

        await sut.toggleFavorite()

        #expect(sut.movie.isFavorite == false)
        #expect(store.addFavoriteCallCount == 1)
    }
}
