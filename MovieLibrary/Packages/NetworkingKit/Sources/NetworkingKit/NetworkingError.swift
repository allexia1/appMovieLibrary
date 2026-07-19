//
//  NetworkingError.swift
//  MovieLibraryApp
//
//  Created by Allexia Azevedo de Morais on 16/07/26.
//

import Foundation

public enum NetworkingError: Error, @unchecked Sendable {
    case invalidURL
    case requestFailed(URLError)
    case invalidResponse
    case invalidResponseData
    case decodingFailed(Error)
    case invalidBodyData
    case noInternetConnection
    case timeout
    case cancelled
    case httpError(code: Int)
}
