//
//  Request.swift
//  MovieLibraryApp
//
//  Created by Allexia Azevedo de Morais on 16/07/26.
//

import Foundation

public protocol Request {
    var scheme: String { get }
    var host: String { get }
    var version: String { get }
    var path: String { get }
    var method: HTTPMethod { get }
    var headers: [String: String] { get }
    var queryParams: [String: String] { get }
    var bodyParams: [String: Any]? { get }
}

public extension Request {
    var scheme: String { "https" }
    var version: String { "" }
    var headers: [String: String] { [:] }
    var queryParams: [String: String] { [:] }
    var bodyParams: [String: Any]? { nil }

    var fullPath: String {
        version.isEmpty ? path : version + path
    }

    func asURLRequest() throws -> URLRequest {
        var components = URLComponents()
        components.scheme = scheme
        components.host = host
        components.path = fullPath
        if !queryParams.isEmpty {
            components.queryItems = queryParams
                .sorted { $0.key < $1.key }
                .map { URLQueryItem(name: $0.key, value: $0.value) }
        }
        guard let url = components.url else {
            throw NetworkingError.invalidURL
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = method.rawValue
        headers.forEach { urlRequest.setValue($0.value, forHTTPHeaderField: $0.key) }

        if let bodyParams {
            guard let data = try? JSONSerialization.data(withJSONObject: bodyParams) else {
                throw NetworkingError.invalidBodyData
            }
            urlRequest.httpBody = data
            urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        return urlRequest
    }
}
