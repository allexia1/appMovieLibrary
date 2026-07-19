//
//  MovieDetailViewModel.swift
//  MovieLibraryApp
//

import UIKit
import Observation

@MainActor
@Observable
final class MovieDetailViewModel {
    private(set) var movie: MovieItem
    private(set) var heroImage: UIImage?

    private let favoriteMoviesStore: FavoriteMoviesStoreProtocol
    private let imageLoader: ImageLoadingProtocol

    init(movie: MovieItem, favoriteMoviesStore: FavoriteMoviesStoreProtocol, imageLoader: ImageLoadingProtocol) {
        self.movie = movie.updatingFavorite(to: favoriteMoviesStore.isFavorite(id: movie.id))
        self.favoriteMoviesStore = favoriteMoviesStore
        self.imageLoader = imageLoader
    }

    func loadHeroImage() async {
        guard let posterURL = movie.posterURL else { return }
        guard let image = try? await imageLoader.loadImage(from: posterURL) else { return }
        heroImage = image
    }

    func toggleFavorite() async {
        do {
            if movie.isFavorite {
                try await favoriteMoviesStore.removeFavorite(id: movie.id)
            } else {
                try await favoriteMoviesStore.addFavorite(movie)
            }
            movie = movie.updatingFavorite(to: !movie.isFavorite)
        } catch {
            // Keep the current state; the user can try again.
        }
    }
}
