//
//  FavoriteMoviesRepositoryProtocol.swift
//  MovieLibraryApp
//
//  Created by Allexia Azevedo de Morais on 16/07/26.
//

protocol FavoriteMoviesRepositoryProtocol: Sendable {
    func fetchFavoriteMovies() async throws -> [MovieItem]
    func fetchFavoriteMovieIDs() async throws -> Set<Int>
    func saveFavorite(_ movie: MovieItem) async throws
    func removeFavorite(id: Int) async throws
}
