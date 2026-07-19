//
//  TestLocalizedError.swift
//  MovieLibraryApp
//
//  Created by Allexia Azevedo de Morais on 16/07/26.
//

import Foundation

struct TestLocalizedError: LocalizedError, Equatable {
    let message: String
    var errorDescription: String? { message }
}
