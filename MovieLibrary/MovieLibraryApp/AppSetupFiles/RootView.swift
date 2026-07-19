//
//  RootView.swift
//  MovieLibraryApp
//

import SwiftUI

/// Raiz de navegação: TabView com Filmes e Favoritos, cada aba com sua própria NavigationStack.
struct RootView: View {
    @State private var movieListViewModel: MovieListViewModel
    @State private var favoritesViewModel: FavoritesViewModel
    private let dependencyContainer: AppDependencyContainer

    init(dependencyContainer: AppDependencyContainer) {
        self.dependencyContainer = dependencyContainer
        _movieListViewModel = State(initialValue: dependencyContainer.makeMovieListViewModel())
        _favoritesViewModel = State(initialValue: dependencyContainer.makeFavoritesViewModel())
    }

    var body: some View {
        TabView {
            NavigationStack {
                MovieListScreen(viewModel: movieListViewModel, imageLoader: dependencyContainer.imageLoader)
                    .navigationDestination(for: MovieItem.self) { movie in
                        MovieDetailScreen(viewModel: dependencyContainer.makeMovieDetailViewModel(movie: movie))
                    }
            }
            .tabItem {
                Label(LocalizedStrings.moviesTabTitle, systemImage: "film")
            }

            NavigationStack {
                FavoritesScreen(viewModel: favoritesViewModel, imageLoader: dependencyContainer.imageLoader)
                    .navigationDestination(for: MovieItem.self) { movie in
                        MovieDetailScreen(viewModel: dependencyContainer.makeMovieDetailViewModel(movie: movie))
                    }
            }
            .tabItem {
                Label(LocalizedStrings.favoritesTabTitle, systemImage: "heart")
            }
        }
    }
}
