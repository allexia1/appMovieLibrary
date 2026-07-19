//
//  FetchMoviesUseCase.swift
//  MovieLibraryApp
//
//  Created by Allexia Azevedo de Morais on 16/07/26.
//

protocol FetchMoviesUseCaseProtocol: Sendable {
    func execute(searchQuery: String?, page: Int) async throws -> MoviesPage
}

struct FetchMoviesUseCase: FetchMoviesUseCaseProtocol {
    let repository: MovieRepositoryProtocol

    func execute(searchQuery: String?, page: Int) async throws -> MoviesPage {
        try await repository.fetchMovies(searchQuery: searchQuery, page: page)
    }
}
