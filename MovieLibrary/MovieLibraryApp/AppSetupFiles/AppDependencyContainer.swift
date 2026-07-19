//
//  AppDependencyContainer.swift
//  MovieLibraryApp
//

import Foundation
import SwiftData
import NetworkingKit

/// Composition root: monta manualmente o grafo de dependências do app (networking, persistência,
/// repositórios, use cases) e cria ViewModels já injetados para as Views SwiftUI.
@MainActor
final class AppDependencyContainer {
    private lazy var urlSessionClient: Networking = URLSessionClient()

    lazy var imageLoader: ImageLoadingProtocol = ImageLoader()

    private lazy var modelContainer: ModelContainer = {
        let schema = Schema([FavoriteMovieObj.self])
        do {
            return try ModelContainer(for: schema)
        } catch {
            fatalError("Could not initialize SwiftData ModelContainer: \(error)")
        }
    }()

    private lazy var movieRepository: MovieRepositoryProtocol = TMDBMovieRepository(
        networking: urlSessionClient,
        accessToken: AppConfig.shared.accessToken
    )

    private lazy var favoriteMoviesRepository: FavoriteMoviesRepositoryProtocol = FavoriteMoviesRepository(
        modelContainer: modelContainer
    )

    private lazy var fetchMoviesUseCase: FetchMoviesUseCaseProtocol = FetchMoviesUseCase(
        repository: movieRepository
    )

    lazy var favoriteMoviesStore: FavoriteMoviesStoreProtocol = FavoriteMoviesStore(
        repository: favoriteMoviesRepository
    )

    func makeMovieListViewModel() -> MovieListViewModel {
        MovieListViewModel(fetchMoviesUseCase: fetchMoviesUseCase, favoriteMoviesStore: favoriteMoviesStore)
    }

    func makeFavoritesViewModel() -> FavoritesViewModel {
        FavoritesViewModel(favoriteMoviesStore: favoriteMoviesStore)
    }

    func makeMovieDetailViewModel(movie: MovieItem) -> MovieDetailViewModel {
        MovieDetailViewModel(movie: movie, favoriteMoviesStore: favoriteMoviesStore, imageLoader: imageLoader)
    }
}
