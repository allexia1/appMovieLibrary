//
//  MovieListRequestError.swift
//  MovieLibraryApp
//
//  Created by Allexia Azevedo de Morais on 16/07/26.
//

import Foundation
import NetworkingKit

enum MovieListRequestError: LocalizedError {
    case invalidRequest
    case notFound
    case serverError
    case noInternetConnection
    case timeout
    case cancelled
    case decodingFailed
    case unknown

    init(networkingError: NetworkingError) {
        switch networkingError {
        case .invalidURL, .invalidBodyData:
            self = .invalidRequest
        case .httpError(let code) where code == 404:
            self = .notFound
        case .httpError:
            self = .serverError
        case .invalidResponse, .invalidResponseData:
            self = .serverError
        case .decodingFailed:
            self = .decodingFailed
        case .noInternetConnection:
            self = .noInternetConnection
        case .timeout:
            self = .timeout
        case .cancelled:
            self = .cancelled
        case .requestFailed:
            self = .unknown
        }
    }

    var errorDescription: String? {
        switch self {
        case .invalidRequest:
            return NSLocalizedString("errors.movieList.invalidRequest", comment: "")
        case .notFound:
            return NSLocalizedString("errors.movieList.notFound", comment: "")
        case .serverError:
            return NSLocalizedString("errors.movieList.serverError", comment: "")
        case .noInternetConnection:
            return NSLocalizedString("errors.movieList.noInternetConnection", comment: "")
        case .timeout:
            return NSLocalizedString("errors.movieList.timeout", comment: "")
        case .cancelled:
            return NSLocalizedString("errors.movieList.cancelled", comment: "")
        case .decodingFailed:
            return NSLocalizedString("errors.movieList.decodingFailed", comment: "")
        case .unknown:
            return NSLocalizedString("errors.movieList.unknown", comment: "")
        }
    }
}
