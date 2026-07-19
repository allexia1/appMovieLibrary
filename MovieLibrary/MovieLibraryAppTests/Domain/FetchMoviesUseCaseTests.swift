//
//  FetchMoviesUseCaseTests.swift
//  MovieLibraryApp
//
//  Created by Allexia Azevedo de Morais on 16/07/26.
//

import Testing
@testable import MovieLibraryApp

@Suite
struct FetchMoviesUseCaseTests {
    @Test
    func execute_delegatesToRepositoryWithSameParameters() async throws {
        let repository = MovieRepositorySpy()
        let expectedPage = MoviesPage(items: [.fixture(id: 42)], nextPage: 2)
        repository.resultToReturn = .success(expectedPage)
        let sut = FetchMoviesUseCase(repository: repository)

        let result = try await sut.execute(searchQuery: "batman", page: 1)

        #expect(result == expectedPage)
        #expect(repository.fetchMoviesCallCount == 1)
        #expect(repository.receivedSearchQueries == ["batman"])
        #expect(repository.receivedPages == [1])
    }

    @Test
    func execute_propagatesRepositoryError() async {
        let repository = MovieRepositorySpy()
        repository.resultToReturn = .failure(TestLocalizedError(message: "Network failure"))
        let sut = FetchMoviesUseCase(repository: repository)

        do {
            _ = try await sut.execute(searchQuery: nil, page: 1)
            Issue.record("Expected to throw an error")
        } catch let error as TestLocalizedError {
            #expect(error.message == "Network failure")
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }
}
