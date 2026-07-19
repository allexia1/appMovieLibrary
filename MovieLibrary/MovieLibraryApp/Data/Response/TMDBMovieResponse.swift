//
//  TMDBMovieResponse.swift
//  MovieLibraryApp
//
//  Created by Allexia Azevedo de Morais on 16/07/26.
//

import Foundation

struct TMDBMoviesListResponse: Decodable {
    let page: Int
    let results: [TMDBMovieResponse]
    let totalPages: Int
}

struct TMDBMovieResponse: Decodable {
    let id: Int
    let title: String
    let overview: String
    let posterPath: String?
    let voteAverage: Double?
    let releaseDate: String?
    let genreIds: [Int]?

    var posterURL: URL? {
        guard let posterPath, !posterPath.isEmpty else { return nil }
        return URL(string: "https://image.tmdb.org/t/p/w500\(posterPath)")
    }

    var releaseYear: Int? {
        guard let releaseDate, releaseDate.count >= 4 else { return nil }
        return Int(releaseDate.prefix(4))
    }
}
