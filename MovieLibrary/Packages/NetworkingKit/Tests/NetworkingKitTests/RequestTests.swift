//
//  RequestTests.swift
//  MovieLibraryApp
//
//  Created by Allexia Azevedo de Morais on 16/07/26.
//

import Testing
@testable import NetworkingKit
import Foundation

private struct SampleRequest: Request {
    var host: String = "api.example.com"
    var version: String = "/v3"
    var path: String = "/movies"
    var method: HTTPMethod = .get
    var headers: [String: String] = ["Authorization": "Bearer token"]
    var queryParams: [String: String] = ["page": "1"]
}

@Suite
struct RequestTests {
    @Test
    func fullPath_concatenatesVersionAndPath() {
        let request = SampleRequest()
        #expect(request.fullPath == "/v3/movies")
    }

    @Test
    func asURLRequest_buildsExpectedURLAndMethodAndHeaders() throws {
        let request = SampleRequest()
        let urlRequest = try request.asURLRequest()

        #expect(urlRequest.httpMethod == "GET")
        #expect(urlRequest.value(forHTTPHeaderField: "Authorization") == "Bearer token")
        #expect(urlRequest.url?.host == "api.example.com")
        #expect(urlRequest.url?.path == "/v3/movies")
        #expect(urlRequest.url?.query?.contains("page=1") == true)
    }

    @Test
    func asURLRequest_withoutVersion_usesPathAlone() throws {
        struct NoVersionRequest: Request {
            var host: String = "api.example.com"
            var path: String = "/movies"
            var method: HTTPMethod = .get
        }
        let urlRequest = try NoVersionRequest().asURLRequest()
        #expect(urlRequest.url?.path == "/movies")
    }
}
