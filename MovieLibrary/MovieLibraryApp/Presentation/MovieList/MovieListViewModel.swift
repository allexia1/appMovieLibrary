//
//  MovieListViewModel.swift
//  MovieLibraryApp
//
//  Created by Allexia Azevedo de Morais on 16/07/26.
//

import Foundation
import Observation

@MainActor
@Observable
final class MovieListViewModel {
    private(set) var state: ScreenState<MovieItem> = .loading

    private let fetchMoviesUseCase: FetchMoviesUseCaseProtocol
    private let favoriteMoviesStore: FavoriteMoviesStoreProtocol

    private var currentQuery: String?
    private var nextPage: Int? = 1
    private var loadedItems: [MovieItem] = []
    private var fetchGeneration = 0
    private var isFetchingNextPage = false
    private var searchTask: Task<Void, Never>?

    init(fetchMoviesUseCase: FetchMoviesUseCaseProtocol, favoriteMoviesStore: FavoriteMoviesStoreProtocol) {
        self.fetchMoviesUseCase = fetchMoviesUseCase
        self.favoriteMoviesStore = favoriteMoviesStore
    }

    func loadInitialMovies() async {
        state = .loading
        await fetchPage(query: currentQuery, page: 1, resetting: true, isPrimaryFetch: true)
    }

    func refresh() async {
        await fetchPage(query: currentQuery, page: 1, resetting: true, isPrimaryFetch: true)
    }

    func search(query: String) {
        searchTask?.cancel()
        let normalizedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        searchTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 300_000_000)
            guard let self, !Task.isCancelled else { return }
            self.currentQuery = normalizedQuery.isEmpty ? nil : normalizedQuery
            await self.fetchPage(query: self.currentQuery, page: 1, resetting: true, isPrimaryFetch: true)
        }
    }

    func loadNextPageIfNeeded(currentIndex: Int) async {
        guard
            case .content(let items, let isLoadingNextPage, _) = state,
            !isLoadingNextPage,
            !isFetchingNextPage,
            let nextPage
        else { return }

        let thresholdIndex = items.count - 5
        guard currentIndex >= thresholdIndex else { return }

        isFetchingNextPage = true
        defer { isFetchingNextPage = false }
        await fetchPage(query: currentQuery, page: nextPage, resetting: false, isPrimaryFetch: false)
    }

    func toggleFavorite(for movie: MovieItem) async {
        do {
            if movie.isFavorite {
                try await favoriteMoviesStore.removeFavorite(id: movie.id)
            } else {
                try await favoriteMoviesStore.addFavorite(movie)
            }
            updateLocalItem(id: movie.id, isFavorite: !movie.isFavorite)
        } catch {
            // Keep the item unchanged; the user can try again.
        }
    }

    func refreshFavoriteStatuses() {
        guard case .content(let items, let isLoadingNextPage, let paginationErrorMessage) = state else { return }
        let updatedItems = items.map { $0.updatingFavorite(to: favoriteMoviesStore.isFavorite(id: $0.id)) }
        loadedItems = updatedItems
        state = .content(items: updatedItems, isLoadingNextPage: isLoadingNextPage, paginationErrorMessage: paginationErrorMessage)
    }

    func dismissPaginationError() {
        guard case .content(let items, let isLoadingNextPage, _) = state else { return }
        state = .content(items: items, isLoadingNextPage: isLoadingNextPage, paginationErrorMessage: nil)
    }

    private func updateLocalItem(id: Int, isFavorite: Bool) {
        guard case .content(let items, let isLoadingNextPage, let paginationErrorMessage) = state else { return }
        let updatedItems = items.map { $0.id == id ? $0.updatingFavorite(to: isFavorite) : $0 }
        loadedItems = updatedItems
        state = .content(items: updatedItems, isLoadingNextPage: isLoadingNextPage, paginationErrorMessage: paginationErrorMessage)
    }

    /// - Parameter isPrimaryFetch: `true` for `loadInitialMovies`/`refresh`/`search`, which always take
    ///   precedence and supersede any in-flight fetch (including a pagination fetch). `false` for the
    ///   pagination fetch triggered by `loadNextPageIfNeeded`, whose reentrancy is guarded separately by
    ///   `isFetchingNextPage`. `fetchGeneration` is used to detect when a fetch's result has been
    ///   superseded by a newer primary fetch, so its (now stale) result is discarded instead of
    ///   corrupting `state`/`loadedItems`.
    private func fetchPage(query: String?, page: Int, resetting: Bool, isPrimaryFetch: Bool) async {
        if isPrimaryFetch {
            fetchGeneration += 1
        }
        let generation = fetchGeneration

        if !resetting, case .content(let items, _, _) = state {
            state = .content(items: items, isLoadingNextPage: true, paginationErrorMessage: nil)
        }

        do {
            let moviesPage = try await fetchMoviesUseCase.execute(searchQuery: query, page: page)
            guard generation == fetchGeneration else { return }

            let favoriteStatusedItems = moviesPage.items.map {
                $0.updatingFavorite(to: favoriteMoviesStore.isFavorite(id: $0.id))
            }

            if resetting {
                loadedItems = favoriteStatusedItems
            } else {
                let existingIDs = Set(loadedItems.map(\.id))
                loadedItems.append(contentsOf: favoriteStatusedItems.filter { !existingIDs.contains($0.id) })
            }
            nextPage = moviesPage.nextPage

            state = loadedItems.isEmpty
                ? .empty
                : .content(items: loadedItems, isLoadingNextPage: false, paginationErrorMessage: nil)
        } catch {
            guard generation == fetchGeneration else { return }

            let message = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            if resetting {
                state = .error(message)
            } else {
                state = .content(items: loadedItems, isLoadingNextPage: false, paginationErrorMessage: message)
            }
        }
    }
}
