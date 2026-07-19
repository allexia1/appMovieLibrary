//
//  URLSessionClientTests.swift
//  MovieLibraryApp
//
//  Created by Allexia Azevedo de Morais on 16/07/26.
//

import Testing
@testable import NetworkingKit
import Foundation

private struct StubItem: Decodable, Equatable {
    let id: Int
    let itemName: String
}

private struct StubRequest: Request {
    var host: String = "api.example.com"
    var path: String = "/items"
    var method: HTTPMethod = .get
}

@Suite(.serialized)
struct URLSessionClientTests {
    private func makeSUT() -> URLSessionClient {
        URLSessionClient(session: URLProtocolStub.makeSession())
    }

    private func httpResponse(statusCode: Int) -> HTTPURLResponse {
        HTTPURLResponse(url: URL(string: "https://api.example.com/items")!, statusCode: statusCode, httpVersion: nil, headerFields: nil)!
    }

    @Test
    func perform_onSuccess_decodesSnakeCaseJSON() async throws {
        let json = Data(#"{"id": 1, "item_name": "Test Movie"}"#.utf8)
        URLProtocolStub.stub = .init(data: json, response: httpResponse(statusCode: 200), error: nil)
        defer { URLProtocolStub.stub = nil }

        let sut = makeSUT()
        let result: StubItem = try await sut.perform(StubRequest())

        #expect(result == StubItem(id: 1, itemName: "Test Movie"))
    }

    @Test
    func perform_onNon2xxStatus_throwsHttpError() async throws {
        URLProtocolStub.stub = .init(data: Data(), response: httpResponse(statusCode: 404), error: nil)
        defer { URLProtocolStub.stub = nil }

        let sut = makeSUT()
        do {
            let _: StubItem = try await sut.perform(StubRequest())
            Issue.record("Expected to throw HTTP error")
        } catch let error as NetworkingError {
            guard case .httpError(let code) = error else {
                Issue.record("Expected .httpError, got \(error)")
                return
            }
            #expect(code == 404)
        }
    }

    @Test
    func perform_onTimeout_throwsTimeoutError() async throws {
        URLProtocolStub.stub = .init(data: nil, response: nil, error: URLError(.timedOut))
        defer { URLProtocolStub.stub = nil }

        let sut = makeSUT()
        do {
            let _: StubItem = try await sut.perform(StubRequest())
            Issue.record("Expected to throw timeout error")
        } catch let error as NetworkingError {
            guard case .timeout = error else {
                Issue.record("Expected .timeout, got \(error)")
                return
            }
        }
    }

    @Test
    func perform_onInvalidJSON_throwsDecodingFailed() async throws {
        let invalidJSON = Data(#"{"unexpected": true}"#.utf8)
        URLProtocolStub.stub = .init(data: invalidJSON, response: httpResponse(statusCode: 200), error: nil)
        defer { URLProtocolStub.stub = nil }

        let sut = makeSUT()
        do {
            let _: StubItem = try await sut.perform(StubRequest())
            Issue.record("Expected to throw decoding error")
        } catch let error as NetworkingError {
            guard case .decodingFailed = error else {
                Issue.record("Expected .decodingFailed, got \(error)")
                return
            }
        }
    }

    @Test
    func perform_onCancelledURLError_throwsCancelled() async throws {
        URLProtocolStub.stub = .init(data: nil, response: nil, error: URLError(.cancelled))
        defer { URLProtocolStub.stub = nil }

        let sut = makeSUT()
        do {
            let _: StubItem = try await sut.perform(StubRequest())
            Issue.record("Expected to throw cancellation error")
        } catch let error as NetworkingError {
            guard case .cancelled = error else {
                Issue.record("Expected .cancelled, got \(error)")
                return
            }
        }
    }

    @Test
    func perform_onNoInternet_throwsNoInternetConnection() async throws {
        URLProtocolStub.stub = .init(data: nil, response: nil, error: URLError(.notConnectedToInternet))
        defer { URLProtocolStub.stub = nil }

        let sut = makeSUT()
        do {
            let _: StubItem = try await sut.perform(StubRequest())
            Issue.record("Expected to throw no-internet error")
        } catch let error as NetworkingError {
            guard case .noInternetConnection = error else {
                Issue.record("Expected .noInternetConnection, got \(error)")
                return
            }
        }
    }
}
