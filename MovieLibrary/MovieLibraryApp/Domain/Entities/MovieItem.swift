//
//  MovieItem.swift
//  MovieLibraryApp
//
//  Created by Allexia Azevedo de Morais on 16/07/26.
//

import Foundation

struct MovieItem: Hashable, Sendable {
    let id: Int
    let title: String
    let posterURL: URL?
    let overview: String
    let rating: Double
    let genres: [String]
    let releaseYear: Int?
    let isFavorite: Bool

    func updatingFavorite(to isFavorite: Bool) -> MovieItem {
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

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(isFavorite)
    }
}
