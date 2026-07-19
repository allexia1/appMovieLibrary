//
//  TMDBMovieRepository.swift
//  MovieLibraryApp
//
//  Created by Allexia Azevedo de Morais on 16/07/26.
//

import NetworkingKit

final class TMDBMovieRepository: MovieRepositoryProtocol, @unchecked Sendable {
    private let networking: Networking
    private let accessToken: String
    private let pageSize = 20

    init(networking: Networking, accessToken: String) {
        self.networking = networking
        self.accessToken = accessToken
    }

    func fetchMovies(searchQuery: String?, page: Int) async throws -> MoviesPage {
        let request = TMDBMoviesRequest(searchQuery: searchQuery, page: page, accessToken: accessToken)
        do {
            let response: TMDBMoviesListResponse = try await networking.perform(request)
            let items = response.results.map { movie in
                MovieItem(
                    id: movie.id,
                    title: movie.title,
                    posterURL: movie.posterURL,
                    overview: movie.overview,
                    rating: movie.voteAverage ?? 0,
                    genres: TMDBGenreCatalog.names(for: movie.genreIds ?? []),
                    releaseYear: movie.releaseYear,
                    isFavorite: false
                )
            }
            let hasMorePages = response.page < response.totalPages && response.results.count >= pageSize
            let nextPage = hasMorePages ? response.page + 1 : nil
            return MoviesPage(items: items, nextPage: nextPage)
        } catch let error as NetworkingError {
            throw MovieListRequestError(networkingError: error)
        }
    }
}
