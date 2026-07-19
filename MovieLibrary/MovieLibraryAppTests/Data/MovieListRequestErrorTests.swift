//
//  MovieListRequestErrorTests.swift
//  MovieLibraryApp
//
//  Created by Allexia Azevedo de Morais on 16/07/26.
//

import Testing
import Foundation
import NetworkingKit
@testable import MovieLibraryApp

@Suite
struct MovieListRequestErrorTests {
    @Test(arguments: [
        (NetworkingError.invalidURL, "invalidRequest"),
        (NetworkingError.invalidBodyData, "invalidRequest"),
        (NetworkingError.httpError(code: 404), "notFound"),
        (NetworkingError.httpError(code: 500), "serverError"),
        (NetworkingError.invalidResponse, "serverError"),
        (NetworkingError.invalidResponseData, "serverError"),
        (NetworkingError.noInternetConnection, "noInternetConnection"),
        (NetworkingError.timeout, "timeout"),
        (NetworkingError.cancelled, "cancelled")
    ])
    func init_mapsEachNetworkingErrorCase(networkingError: NetworkingError, expectedCaseName: String) {
        let sut = MovieListRequestError(networkingError: networkingError)
        #expect("\(sut)".contains(expectedCaseName))
    }

    @Test
    func init_mapsDecodingFailed() {
        let sut = MovieListRequestError(networkingError: .decodingFailed(TestLocalizedError(message: "x")))
        #expect("\(sut)".contains("decodingFailed"))
    }

    @Test
    func init_mapsRequestFailedToUnknown() {
        let sut = MovieListRequestError(networkingError: .requestFailed(URLError(.badServerResponse)))
        #expect("\(sut)".contains("unknown"))
    }

    @Test
    func errorDescription_isNeverEmpty() {
        let sut = MovieListRequestError(networkingError: .timeout)
        #expect((sut.errorDescription?.isEmpty ?? true) == false)
    }
}
