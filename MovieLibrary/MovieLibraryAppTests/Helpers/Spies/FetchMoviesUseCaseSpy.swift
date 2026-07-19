//
//  FetchMoviesUseCaseSpy.swift
//  MovieLibraryApp
//
//  Created by Allexia Azevedo de Morais on 16/07/26.
//

@testable import MovieLibraryApp

final class FetchMoviesUseCaseSpy: FetchMoviesUseCaseProtocol, @unchecked Sendable {
    private(set) var executeCallCount = 0
    private(set) var receivedSearchQueries: [String?] = []
    private(set) var receivedPages: [Int] = []
    var resultsToReturn: [Result<MoviesPage, Error>] = []
    var defaultResult: Result<MoviesPage, Error> = .success(MoviesPage(items: [], nextPage: nil))

    func execute(searchQuery: String?, page: Int) async throws -> MoviesPage {
        executeCallCount += 1
        receivedSearchQueries.append(searchQuery)
        receivedPages.append(page)
        if executeCallCount <= resultsToReturn.count {
            return try resultsToReturn[executeCallCount - 1].get()
        }
        return try defaultResult.get()
    }
}
