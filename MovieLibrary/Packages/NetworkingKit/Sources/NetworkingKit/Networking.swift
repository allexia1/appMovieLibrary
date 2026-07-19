//
//  Networking.swift
//  MovieLibraryApp
//
//  Created by Allexia Azevedo de Morais on 16/07/26.
//

public protocol Networking: Sendable {
    func perform<T: Decodable>(_ request: Request) async throws -> T
}
