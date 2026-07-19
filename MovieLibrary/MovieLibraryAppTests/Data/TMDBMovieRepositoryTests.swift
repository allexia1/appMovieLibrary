//
//  TMDBMovieRepositoryTests.swift
//  MovieLibraryApp
//
//  Created by Allexia Azevedo de Morais on 16/07/26.
//

import Testing
import Foundation
import NetworkingKit
@testable import MovieLibraryApp

@Suite
struct TMDBMovieRepositoryTests {
    private func makeResponse(
        page: Int = 1,
        totalPages: Int = 1,
        results: [TMDBMovieResponse] = []
    ) -> TMDBMoviesListResponse {
        TMDBMoviesListResponse(page: page, results: results, totalPages: totalPages)
    }

    private func makeMovieResponse(
        id: Int = 1,
        title: String = "TMDB Movie",
        overview: String = "Synopsis",
        posterPath: String? = "/poster.jpg",
        voteAverage: Double? = 7.5,
        releaseDate: String? = "2023-05-10",
        genreIds: [Int]? = [28]
    ) -> TMDBMovieResponse {
        TMDBMovieResponse(
            id: id,
            title: title,
            overview: overview,
            posterPath: posterPath,
            voteAverage: voteAverage,
            releaseDate: releaseDate,
            genreIds: genreIds
        )
    }

    @Test
    func fetchMovies_mapsResponseToMovieItems() async throws {
        let networking = NetworkingSpy()
        networking.resultToReturn = .success(makeResponse(results: [makeMovieResponse()]))
        let sut = TMDBMovieRepository(networking: networking, accessToken: "token")

        let page = try await sut.fetchMovies(searchQuery: nil, page: 1)

        #expect(page.items.count == 1)
        let movie = try #require(page.items.first)
        #expect(movie.id == 1)
        #expect(movie.title == "TMDB Movie")
        #expect(movie.rating == 7.5)
        #expect(movie.releaseYear == 2023)
        #expect(movie.genres == ["Action"])
        #expect(movie.posterURL?.absoluteString == "https://image.tmdb.org/t/p/w500/poster.jpg")
        #expect(movie.isFavorite == false)
    }

    @Test
    func fetchMovies_withNilPosterPath_mapsToNilPosterURL() async throws {
        let networking = NetworkingSpy()
        networking.resultToReturn = .success(makeResponse(results: [makeMovieResponse(posterPath: nil)]))
        let sut = TMDBMovieRepository(networking: networking, accessToken: "token")

        let page = try await sut.fetchMovies(searchQuery: nil, page: 1)

        #expect(page.items.first?.posterURL == nil)
    }

    @Test
    func fetchMovies_withMissingVoteAverageAndGenres_usesFallbacks() async throws {
        let networking = NetworkingSpy()
        networking.resultToReturn = .success(makeResponse(results: [
            makeMovieResponse(voteAverage: nil, releaseDate: nil, genreIds: nil)
        ]))
        let sut = TMDBMovieRepository(networking: networking, accessToken: "token")

        let page = try await sut.fetchMovies(searchQuery: nil, page: 1)
        let movie = try #require(page.items.first)

        #expect(movie.rating == 0)
        #expect(movie.releaseYear == nil)
        #expect(movie.genres.isEmpty)
    }

    @Test
    func fetchMovies_withFullPageAndMorePagesAvailable_returnsNextPage() async throws {
        let networking = NetworkingSpy()
        let fullPageResults = (1...20).map { makeMovieResponse(id: $0) }
        networking.resultToReturn = .success(makeResponse(page: 1, totalPages: 3, results: fullPageResults))
        let sut = TMDBMovieRepository(networking: networking, accessToken: "token")

        let page = try await sut.fetchMovies(searchQuery: nil, page: 1)

        #expect(page.nextPage == 2)
    }

    @Test
    func fetchMovies_withPartialLastPage_returnsNilNextPage() async throws {
        let networking = NetworkingSpy()
        networking.resultToReturn = .success(makeResponse(page: 2, totalPages: 3, results: [makeMovieResponse()]))
        let sut = TMDBMovieRepository(networking: networking, accessToken: "token")

        let page = try await sut.fetchMovies(searchQuery: nil, page: 2)

        #expect(page.nextPage == nil)
    }

    @Test
    func fetchMovies_onLastPage_returnsNilNextPage() async throws {
        let networking = NetworkingSpy()
        let fullPageResults = (1...20).map { makeMovieResponse(id: $0) }
        networking.resultToReturn = .success(makeResponse(page: 3, totalPages: 3, results: fullPageResults))
        let sut = TMDBMovieRepository(networking: networking, accessToken: "token")

        let page = try await sut.fetchMovies(searchQuery: nil, page: 3)

        #expect(page.nextPage == nil)
    }

    @Test
    func fetchMovies_withSearchQuery_sendsSearchRequestWithQueryAndPage() async throws {
        let networking = NetworkingSpy()
        networking.resultToReturn = .success(makeResponse())
        let sut = TMDBMovieRepository(networking: networking, accessToken: "token")

        _ = try await sut.fetchMovies(searchQuery: "matrix", page: 2)

        let sentRequest = try #require(networking.receivedRequests.first)
        #expect(sentRequest.path == "/search/movie")
        #expect(sentRequest.queryParams["query"] == "matrix")
        #expect(sentRequest.queryParams["page"] == "2")
    }

    @Test
    func fetchMovies_withoutSearchQuery_sendsPopularRequest() async throws {
        let networking = NetworkingSpy()
        networking.resultToReturn = .success(makeResponse())
        let sut = TMDBMovieRepository(networking: networking, accessToken: "token")

        _ = try await sut.fetchMovies(searchQuery: nil, page: 1)

        let sentRequest = try #require(networking.receivedRequests.first)
        #expect(sentRequest.path == "/movie/popular")
        #expect(sentRequest.queryParams["query"] == nil)
    }

    @Test
    func fetchMovies_onNetworkingError_throwsMappedMovieListRequestError() async {
        let networking = NetworkingSpy()
        networking.resultToReturn = .failure(NetworkingError.timeout)
        let sut = TMDBMovieRepository(networking: networking, accessToken: "token")

        do {
            _ = try await sut.fetchMovies(searchQuery: nil, page: 1)
            Issue.record("Expected to throw an error")
        } catch let error as MovieListRequestError {
            guard case .timeout = error else {
                Issue.record("Expected .timeout, got \(error)")
                return
            }
        } catch {
            Issue.record("Expected MovieListRequestError, got \(error)")
        }
    }
}
