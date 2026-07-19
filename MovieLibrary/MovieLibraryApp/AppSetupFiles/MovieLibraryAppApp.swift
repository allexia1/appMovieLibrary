//
//  MovieLibraryAppApp.swift
//  MovieLibraryApp
//

import SwiftUI

@main
struct MovieLibraryAppApp: App {
    private let dependencyContainer = AppDependencyContainer()

    var body: some Scene {
        WindowGroup {
            // Quando rodando sob o host de testes (XCTest), pula a construção da RootView (que
            // aciona o grafo de dependências completo, exigindo credenciais reais da TMDB via
            // AppConfig) porque os testes constroem objetos isolados e não dependem da UI real.
            if ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] == nil {
                RootView(dependencyContainer: dependencyContainer)
            } else {
                EmptyView()
            }
        }
    }
}
