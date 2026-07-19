//
//  FavoriteMoviesStoreProtocol.swift
//  MovieLibraryApp
//
//  Created by Allexia Azevedo de Morais on 16/07/26.
//

@MainActor
protocol FavoriteMoviesStoreProtocol: AnyObject {
    var favoriteMovies: [MovieItem] { get }
    func loadFavoritesIfNeeded() async throws
    func isFavorite(id: Int) -> Bool
    func addFavorite(_ movie: MovieItem) async throws
    func removeFavorite(id: Int) async throws
}
