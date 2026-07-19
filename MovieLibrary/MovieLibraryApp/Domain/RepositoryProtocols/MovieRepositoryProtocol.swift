//
//  MovieRepositoryProtocol.swift
//  MovieLibraryApp
//
//  Created by Allexia Azevedo de Morais on 16/07/26.
//

protocol MovieRepositoryProtocol: Sendable {
    func fetchMovies(searchQuery: String?, page: Int) async throws -> MoviesPage
}
