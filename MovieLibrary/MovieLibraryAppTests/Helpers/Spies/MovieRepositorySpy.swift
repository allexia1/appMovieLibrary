//
//  MovieRepositorySpy.swift
//  MovieLibraryApp
//
//  Created by Allexia Azevedo de Morais on 16/07/26.
//

@testable import MovieLibraryApp

final class MovieRepositorySpy: MovieRepositoryProtocol, @unchecked Sendable {
    private(set) var fetchMoviesCallCount = 0
    private(set) var receivedSearchQueries: [String?] = []
    private(set) var receivedPages: [Int] = []
    var resultToReturn: Result<MoviesPage, Error> = .success(MoviesPage(items: [], nextPage: nil))

    func fetchMovies(searchQuery: String?, page: Int) async throws -> MoviesPage {
        fetchMoviesCallCount += 1
        receivedSearchQueries.append(searchQuery)
        receivedPages.append(page)
        return try resultToReturn.get()
    }
}
