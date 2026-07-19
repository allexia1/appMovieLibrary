//
//  URLSessionClient.swift
//  MovieLibraryApp
//
//  Created by Allexia Azevedo de Morais on 16/07/26.
//

import Foundation

public final class URLSessionClient: Networking, @unchecked Sendable {
    private let session: URLSession
    private let decoder: JSONDecoder

    public init(
        session: URLSession? = nil,
        decoder: JSONDecoder? = nil
    ) {
        self.session = session ?? Self.makeDefaultSession()
        self.decoder = decoder ?? Self.makeDefaultDecoder()
    }

    public static func makeDefaultSession() -> URLSession {
        let configuration = URLSessionConfiguration.default
        configuration.urlCache = URLCache(memoryCapacity: 20 * 1024 * 1024, diskCapacity: 100 * 1024 * 1024, diskPath: nil)
        configuration.requestCachePolicy = .useProtocolCachePolicy
        return URLSession(configuration: configuration)
    }

    public static func makeDefaultDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }

    public func perform<T: Decodable>(_ request: Request) async throws -> T {
        let urlRequest = try request.asURLRequest()

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: urlRequest)
        } catch let urlError as URLError {
            throw Self.mapURLError(urlError)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkingError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw NetworkingError.httpError(code: httpResponse.statusCode)
        }

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw NetworkingError.decodingFailed(error)
        }
    }

    private static func mapURLError(_ error: URLError) -> NetworkingError {
        switch error.code {
        case .notConnectedToInternet, .networkConnectionLost, .dataNotAllowed:
            return .noInternetConnection
        case .timedOut:
            return .timeout
        case .cancelled:
            return .cancelled
        default:
            return .requestFailed(error)
        }
    }
}
