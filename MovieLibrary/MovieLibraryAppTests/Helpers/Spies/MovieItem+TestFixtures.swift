//
//  MovieItem+TestFixtures.swift
//  MovieLibraryApp
//
//  Created by Allexia Azevedo de Morais on 16/07/26.
//

import Foundation
@testable import MovieLibraryApp

extension MovieItem {
    static func fixture(
        id: Int = 1,
        title: String = "Test Movie",
        posterURL: URL? = URL(string: "https://image.tmdb.org/t/p/w500/poster.jpg"),
        overview: String = "A test synopsis.",
        rating: Double = 8.0,
        genres: [String] = ["Action"],
        releaseYear: Int? = 2024,
        isFavorite: Bool = false
    ) -> MovieItem {
        MovieItem(
            id: id,
            title: title,
            posterURL: posterURL,
            overview: overview,
            rating: rating,
            genres: genres,
            releaseYear: releaseYear,
            isFavorite: isFavorite
        )
    }
}
