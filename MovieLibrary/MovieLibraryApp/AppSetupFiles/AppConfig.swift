//
//  AppConfig.swift
//  MovieLibraryApp
//
//  Created by Allexia Azevedo de Morais on 16/07/26.
//

import Foundation

/// TMDB API credentials read from Info.plist (via Config.xcconfig).
struct AppConfig {
    let apiKey: String
    let accessToken: String

    static let shared = AppConfig()

    private init() {
        guard
            let apiKey = Bundle.main.object(forInfoDictionaryKey: "TMDBAPIKey") as? String,
            !apiKey.isEmpty,
            apiKey != "YOUR_TMDB_API_KEY_HERE"
        else {
            fatalError("TMDB_API_KEY is not configured. Set a real value in Config.xcconfig before running the app.")
        }
        guard
            let accessToken = Bundle.main.object(forInfoDictionaryKey: "TMDBAccessToken") as? String,
            !accessToken.isEmpty,
            accessToken != "YOUR_TMDB_ACCESS_TOKEN_HERE"
        else {
            fatalError("TMDB_ACCESS_TOKEN is not configured. Set a real value in Config.xcconfig before running the app.")
        }
        self.apiKey = apiKey
        self.accessToken = accessToken
    }
}
