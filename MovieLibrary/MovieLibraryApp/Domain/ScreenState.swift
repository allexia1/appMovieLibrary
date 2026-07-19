//
//  ScreenState.swift
//  MovieLibraryApp
//
//  Created by Allexia Azevedo de Morais on 16/07/26.
//

enum ScreenState<T> {
    case loading
    case empty
    case content(items: [T], isLoadingNextPage: Bool = false, paginationErrorMessage: String? = nil)
    case error(String)
}
