//
//  NetworkingSpy.swift
//  MovieLibraryApp
//
//  Created by Allexia Azevedo de Morais on 16/07/26.
//

import Foundation
import NetworkingKit

final class NetworkingSpy: Networking, @unchecked Sendable {
    private(set) var performCallCount = 0
    private(set) var receivedRequests: [Request] = []
    var resultToReturn: Result<Any, Error> = .failure(NetworkingError.invalidResponse)

    func perform<T: Decodable>(_ request: Request) async throws -> T {
        performCallCount += 1
        receivedRequests.append(request)
        switch resultToReturn {
        case .success(let value):
            guard let typedValue = value as? T else {
                throw NetworkingError.decodingFailed(NSError(domain: "NetworkingSpy", code: -1))
            }
            return typedValue
        case .failure(let error):
            throw error
        }
    }
}
