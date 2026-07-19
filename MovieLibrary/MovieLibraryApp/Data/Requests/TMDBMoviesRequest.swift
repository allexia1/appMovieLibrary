//
//  TMDBMoviesRequest.swift
//  MovieLibraryApp
//
//  Created by Allexia Azevedo de Morais on 16/07/26.
//

import Foundation
import NetworkingKit

struct TMDBMoviesRequest: Request {
    let searchQuery: String?
    let page: Int
    let accessToken: String

    var host: String { "api.themoviedb.org" }
    var version: String { "/3" }

    var path: String {
        (searchQuery?.isEmpty == false) ? "/search/movie" : "/movie/popular"
    }

    var method: HTTPMethod { .get }

    var headers: [String: String] {
        ["Authorization": "Bearer \(accessToken)", "Accept": "application/json"]
    }

    var queryParams: [String: String] {
        var params = ["page": String(page), "language": "pt-BR"]
        if let searchQuery, !searchQuery.isEmpty {
            params["query"] = searchQuery
        }
        return params
    }
}
