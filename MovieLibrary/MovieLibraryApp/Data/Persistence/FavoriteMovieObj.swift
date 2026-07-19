//
//  FavoriteMovieObj.swift
//  MovieLibraryApp
//
//  Created by Allexia Azevedo de Morais on 16/07/26.
//

import Foundation
import SwiftData

@Model
final class FavoriteMovieObj {
    @Attribute(.unique) var id: Int
    var title: String
    var posterURLString: String?
    var overview: String
    var rating: Double
    var genresString: String
    var releaseYear: Int?
    var favoritedAt: Date

    init(
        id: Int,
        title: String,
        posterURLString: String?,
        overview: String,
        rating: Double,
        genres: [String],
        releaseYear: Int?,
        favoritedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.posterURLString = posterURLString
        self.overview = overview
        self.rating = rating
        self.genresString = genres.joined(separator: " | ")
        self.releaseYear = releaseYear
        self.favoritedAt = favoritedAt
    }

    var genres: [String] {
        genresString.isEmpty ? [] : genresString.components(separatedBy: " | ")
    }

    var asMovieItem: MovieItem {
        MovieItem(
            id: id,
            title: title,
            posterURL: posterURLString.flatMap(URL.init(string:)),
            overview: overview,
            rating: rating,
            genres: genres,
            releaseYear: releaseYear,
            isFavorite: true
        )
    }

    func update(from movie: MovieItem) {
        title = movie.title
        posterURLString = movie.posterURL?.absoluteString
        overview = movie.overview
        rating = movie.rating
        genresString = movie.genres.joined(separator: " | ")
        releaseYear = movie.releaseYear
    }
}
