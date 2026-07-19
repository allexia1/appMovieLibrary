//
//  LocalizedStrings.swift
//  MovieLibraryApp
//
//  Created by Allexia Azevedo de Morais on 16/07/26.
//

import Foundation

enum LocalizedStrings {
    static var moviesTabTitle: String { NSLocalizedString("movies.tab.title", comment: "") }
    static var favoritesTabTitle: String { NSLocalizedString("favorites.tab.title", comment: "") }

    static var moviesSearchPlaceholder: String { NSLocalizedString("movies.search.placeholder", comment: "") }
    static var moviesEmptyTitle: String { NSLocalizedString("movies.empty.title", comment: "") }
    static var moviesEmptySubtitle: String { NSLocalizedString("movies.empty.subtitle", comment: "") }

    static var favoritesEmptyTitle: String { NSLocalizedString("favorites.empty.title", comment: "") }
    static var favoritesEmptySubtitle: String { NSLocalizedString("favorites.empty.subtitle", comment: "") }

    static var movieDetailRatingTitle: String { NSLocalizedString("movieDetail.rating.title", comment: "") }
    static var movieDetailGenresTitle: String { NSLocalizedString("movieDetail.genres.title", comment: "") }
    static var movieDetailOverviewTitle: String { NSLocalizedString("movieDetail.overview.title", comment: "") }
    static var movieDetailReadMore: String { NSLocalizedString("movieDetail.readMore", comment: "") }
    static var movieDetailReadLess: String { NSLocalizedString("movieDetail.readLess", comment: "") }

    static var commonOK: String { NSLocalizedString("common.ok", comment: "") }
    static var commonRetry: String { NSLocalizedString("common.retry", comment: "") }
    static var commonErrorTitle: String { NSLocalizedString("common.error.title", comment: "") }

    static var favoriteButtonAdd: String { NSLocalizedString("movie.favorite.add", comment: "") }
    static var favoriteButtonRemove: String { NSLocalizedString("movie.favorite.remove", comment: "") }

    static func movieCellAccessibilityLabel(title: String, rating: String) -> String {
        String(format: NSLocalizedString("movie.cell.accessibilityLabel", comment: ""), title, rating)
    }
}
