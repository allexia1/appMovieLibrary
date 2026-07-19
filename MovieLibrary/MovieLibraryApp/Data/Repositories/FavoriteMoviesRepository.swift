//
//  FavoriteMoviesRepository.swift
//  MovieLibraryApp
//
//  Created by Allexia Azevedo de Morais on 16/07/26.
//

import Foundation
import SwiftData

actor FavoriteMoviesRepository: FavoriteMoviesRepositoryProtocol {
    private let modelContainer: ModelContainer

    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
    }

    func fetchFavoriteMovies() async throws -> [MovieItem] {
        let context = ModelContext(modelContainer)
        let descriptor = FetchDescriptor<FavoriteMovieObj>(
            sortBy: [SortDescriptor(\.favoritedAt, order: .reverse)]
        )
        return try context.fetch(descriptor).map(\.asMovieItem)
    }

    func fetchFavoriteMovieIDs() async throws -> Set<Int> {
        let context = ModelContext(modelContainer)
        let descriptor = FetchDescriptor<FavoriteMovieObj>()
        return Set(try context.fetch(descriptor).map(\.id))
    }

    func saveFavorite(_ movie: MovieItem) async throws {
        let context = ModelContext(modelContainer)
        let movieID = movie.id
        let descriptor = FetchDescriptor<FavoriteMovieObj>(predicate: #Predicate { $0.id == movieID })

        if let existing = try context.fetch(descriptor).first {
            existing.update(from: movie)
        } else {
            let object = FavoriteMovieObj(
                id: movie.id,
                title: movie.title,
                posterURLString: movie.posterURL?.absoluteString,
                overview: movie.overview,
                rating: movie.rating,
                genres: movie.genres,
                releaseYear: movie.releaseYear
            )
            context.insert(object)
        }
        try context.save()
    }

    func removeFavorite(id: Int) async throws {
        let context = ModelContext(modelContainer)
        let descriptor = FetchDescriptor<FavoriteMovieObj>(predicate: #Predicate { $0.id == id })
        if let existing = try context.fetch(descriptor).first {
            context.delete(existing)
            try context.save()
        }
    }
}
