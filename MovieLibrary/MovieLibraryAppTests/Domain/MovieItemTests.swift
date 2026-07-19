//
//  MovieItemTests.swift
//  MovieLibraryApp
//
//  Created by Allexia Azevedo de Morais on 16/07/26.
//

import Testing
@testable import MovieLibraryApp

@Suite
struct MovieItemTests {
    @Test
    func updatingFavorite_returnsCopyWithNewFavoriteStatus_keepingOtherFields() {
        let movie = MovieItem.fixture(id: 1, isFavorite: false)
        let favorited = movie.updatingFavorite(to: true)

        #expect(favorited.isFavorite == true)
        #expect(favorited.id == movie.id)
        #expect(favorited.title == movie.title)
    }

    @Test
    func hash_differsWhenFavoriteStatusDiffers_sameID() {
        let notFavorite = MovieItem.fixture(id: 1, isFavorite: false)
        let favorite = MovieItem.fixture(id: 1, isFavorite: true)

        var notFavoriteHasher = Hasher()
        notFavorite.hash(into: &notFavoriteHasher)

        var favoriteHasher = Hasher()
        favorite.hash(into: &favoriteHasher)

        #expect(notFavoriteHasher.finalize() != favoriteHasher.finalize())
    }

    @Test
    func equality_isTrueOnlyWhenAllFieldsMatch() {
        let movieA = MovieItem.fixture(id: 1, title: "A")
        let movieB = MovieItem.fixture(id: 1, title: "A")
        let movieC = MovieItem.fixture(id: 1, title: "B")

        #expect(movieA == movieB)
        #expect(movieA != movieC)
    }
}
