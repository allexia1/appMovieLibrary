//
//  MovieListViewModelTests.swift
//  MovieLibraryApp
//
//  Created by Allexia Azevedo de Morais on 16/07/26.
//

import Foundation
import Testing
@testable import MovieLibraryApp

/// A test-only use case double that can hold specific calls in flight until explicitly released.
///
/// `FetchMoviesUseCaseSpy` resolves synchronously, which makes it impossible to deterministically
/// reproduce "a search arrives while a pagination fetch is still awaiting the network" without relying
/// on fragile real-time races. This actor lets a test pause a specific (1-based) call inside
/// `execute(searchQuery:page:)` and resume it on demand, while keeping the same call-count/received-query
/// tracking shape as `FetchMoviesUseCaseSpy` so assertions read the same way. It intentionally does not
/// touch `FetchMoviesUseCaseSpy` itself, since Task 15 depends on that type's interface staying stable.
private actor GatedFetchMoviesUseCaseSpy: FetchMoviesUseCaseProtocol {
    private(set) var executeCallCount = 0
    private(set) var receivedSearchQueries: [String?] = []
    private(set) var receivedPages: [Int] = []
    var resultsToReturn: [Result<MoviesPage, Error>] = []
    var defaultResult: Result<MoviesPage, Error> = .success(MoviesPage(items: [], nextPage: nil))

    /// 1-based call indices that should suspend inside `execute` until `release(callIndex:)` is invoked.
    private var callIndicesToHold: Set<Int> = []
    private var pendingContinuations: [Int: CheckedContinuation<Void, Never>] = [:]
    private var releasedCallIndices: Set<Int> = []

    func configure(
        resultsToReturn: [Result<MoviesPage, Error>] = [],
        defaultResult: Result<MoviesPage, Error> = .success(MoviesPage(items: [], nextPage: nil)),
        callIndicesToHold: Set<Int> = []
    ) {
        self.resultsToReturn = resultsToReturn
        self.defaultResult = defaultResult
        self.callIndicesToHold = callIndicesToHold
    }

    func execute(searchQuery: String?, page: Int) async throws -> MoviesPage {
        executeCallCount += 1
        let callIndex = executeCallCount
        receivedSearchQueries.append(searchQuery)
        receivedPages.append(page)

        if callIndicesToHold.contains(callIndex), !releasedCallIndices.contains(callIndex) {
            await withCheckedContinuation { continuation in
                pendingContinuations[callIndex] = continuation
            }
        }

        if callIndex <= resultsToReturn.count {
            return try resultsToReturn[callIndex - 1].get()
        }
        return try defaultResult.get()
    }

    func release(callIndex: Int) {
        releasedCallIndices.insert(callIndex)
        pendingContinuations.removeValue(forKey: callIndex)?.resume()
    }
}

/// Polls `condition` until it returns `true` or `timeoutNanoseconds` elapses, instead of relying on a
/// blind fixed-length sleep. Used to wait for a background `Task` to reach a specific point
/// (e.g. "the pagination fetch has entered the use case call") deterministically.
private func waitUntil(
    timeoutSeconds: TimeInterval = 2,
    _ condition: @Sendable () async -> Bool
) async {
    let deadline = Date().addingTimeInterval(timeoutSeconds)
    while await condition() == false {
        if Date() >= deadline { return }
        try? await Task.sleep(nanoseconds: 5_000_000)
    }
}

@MainActor
@Suite
struct MovieListViewModelTests {
    @Test
    func loadInitialMovies_onSuccess_setsContentState() async {
        let useCase = FetchMoviesUseCaseSpy()
        useCase.defaultResult = .success(MoviesPage(items: [.fixture(id: 1), .fixture(id: 2)], nextPage: nil))
        let sut = MovieListViewModel(fetchMoviesUseCase: useCase, favoriteMoviesStore: FavoriteMoviesStoreSpy())

        await sut.loadInitialMovies()

        guard case .content(let items, let isLoadingNextPage, let paginationErrorMessage) = sut.state else {
            Issue.record("Expected content state")
            return
        }
        #expect(items.count == 2)
        #expect(isLoadingNextPage == false)
        #expect(paginationErrorMessage == nil)
    }

    @Test
    func loadInitialMovies_withEmptyResult_setsEmptyState() async {
        let useCase = FetchMoviesUseCaseSpy()
        useCase.defaultResult = .success(MoviesPage(items: [], nextPage: nil))
        let sut = MovieListViewModel(fetchMoviesUseCase: useCase, favoriteMoviesStore: FavoriteMoviesStoreSpy())

        await sut.loadInitialMovies()

        guard case .empty = sut.state else {
            Issue.record("Expected empty state")
            return
        }
    }

    @Test
    func loadInitialMovies_onFailure_setsErrorStateWithMessage() async {
        let useCase = FetchMoviesUseCaseSpy()
        useCase.defaultResult = .failure(TestLocalizedError(message: "Failed to load movies"))
        let sut = MovieListViewModel(fetchMoviesUseCase: useCase, favoriteMoviesStore: FavoriteMoviesStoreSpy())

        await sut.loadInitialMovies()

        guard case .error(let message) = sut.state else {
            Issue.record("Expected error state")
            return
        }
        #expect(message == "Failed to load movies")
    }

    @Test
    func search_withWhitespaceOnlyQuery_normalizesToNilQuery() async throws {
        let useCase = FetchMoviesUseCaseSpy()
        useCase.defaultResult = .success(MoviesPage(items: [], nextPage: nil))
        let sut = MovieListViewModel(fetchMoviesUseCase: useCase, favoriteMoviesStore: FavoriteMoviesStoreSpy())

        sut.search(query: "   ")
        try await Task.sleep(nanoseconds: 400_000_000)

        #expect(useCase.receivedSearchQueries == [nil])
    }

    @Test
    func search_debounces_cancelsPreviousCallsAndOnlyExecutesLastQuery() async throws {
        let useCase = FetchMoviesUseCaseSpy()
        useCase.defaultResult = .success(MoviesPage(items: [], nextPage: nil))
        let sut = MovieListViewModel(fetchMoviesUseCase: useCase, favoriteMoviesStore: FavoriteMoviesStoreSpy())

        sut.search(query: "ab")
        sut.search(query: "abc")
        sut.search(query: "movie")
        try await Task.sleep(nanoseconds: 500_000_000)

        #expect(useCase.executeCallCount == 1)
        #expect(useCase.receivedSearchQueries == ["movie"])
    }

    @Test
    func loadNextPageIfNeeded_appendsNewItemsAndDeduplicatesRepeatedOnes() async {
        let useCase = FetchMoviesUseCaseSpy()
        useCase.resultsToReturn = [
            .success(MoviesPage(items: [.fixture(id: 1), .fixture(id: 2)], nextPage: 2)),
            .success(MoviesPage(items: [.fixture(id: 2), .fixture(id: 3)], nextPage: nil))
        ]
        let sut = MovieListViewModel(fetchMoviesUseCase: useCase, favoriteMoviesStore: FavoriteMoviesStoreSpy())

        await sut.loadInitialMovies()
        await sut.loadNextPageIfNeeded(currentIndex: 1)

        guard case .content(let items, _, _) = sut.state else {
            Issue.record("Expected content state")
            return
        }
        #expect(items.map(\.id) == [1, 2, 3])
        #expect(useCase.executeCallCount == 2)
    }

    @Test
    func loadNextPageIfNeeded_onFailure_keepsExistingItemsAndSetsPaginationErrorMessage() async {
        let useCase = FetchMoviesUseCaseSpy()
        useCase.resultsToReturn = [
            .success(MoviesPage(items: [.fixture(id: 1)], nextPage: 2)),
            .failure(TestLocalizedError(message: "Failed to load more movies"))
        ]
        let sut = MovieListViewModel(fetchMoviesUseCase: useCase, favoriteMoviesStore: FavoriteMoviesStoreSpy())

        await sut.loadInitialMovies()
        await sut.loadNextPageIfNeeded(currentIndex: 0)

        guard case .content(let items, let isLoadingNextPage, let paginationErrorMessage) = sut.state else {
            Issue.record("Expected content state")
            return
        }
        #expect(items.map(\.id) == [1])
        #expect(isLoadingNextPage == false)
        #expect(paginationErrorMessage == "Failed to load more movies")
    }

    @Test
    func dismissPaginationError_clearsMessageWithoutChangingItems() async {
        let useCase = FetchMoviesUseCaseSpy()
        useCase.resultsToReturn = [
            .success(MoviesPage(items: [.fixture(id: 1)], nextPage: 2)),
            .failure(TestLocalizedError(message: "Failure"))
        ]
        let sut = MovieListViewModel(fetchMoviesUseCase: useCase, favoriteMoviesStore: FavoriteMoviesStoreSpy())
        await sut.loadInitialMovies()
        await sut.loadNextPageIfNeeded(currentIndex: 0)

        sut.dismissPaginationError()

        guard case .content(let items, _, let paginationErrorMessage) = sut.state else {
            Issue.record("Expected content state")
            return
        }
        #expect(items.map(\.id) == [1])
        #expect(paginationErrorMessage == nil)
    }

    @Test
    func toggleFavorite_addingFavorite_updatesLocalItemAndCallsStore() async {
        let movie = MovieItem.fixture(id: 1, isFavorite: false)
        let useCase = FetchMoviesUseCaseSpy()
        useCase.defaultResult = .success(MoviesPage(items: [movie], nextPage: nil))
        let store = FavoriteMoviesStoreSpy()
        let sut = MovieListViewModel(fetchMoviesUseCase: useCase, favoriteMoviesStore: store)
        await sut.loadInitialMovies()

        await sut.toggleFavorite(for: movie)

        guard case .content(let items, _, _) = sut.state else {
            Issue.record("Expected content state")
            return
        }
        #expect(items.first?.isFavorite == true)
        #expect(store.addFavoriteCallCount == 1)
    }

    @Test
    func toggleFavorite_removingFavorite_updatesLocalItemAndCallsStore() async {
        let movie = MovieItem.fixture(id: 1, isFavorite: true)
        let useCase = FetchMoviesUseCaseSpy()
        useCase.defaultResult = .success(MoviesPage(items: [movie], nextPage: nil))
        let store = FavoriteMoviesStoreSpy()
        let sut = MovieListViewModel(fetchMoviesUseCase: useCase, favoriteMoviesStore: store)
        await sut.loadInitialMovies()

        await sut.toggleFavorite(for: movie)

        guard case .content(let items, _, _) = sut.state else {
            Issue.record("Expected content state")
            return
        }
        #expect(items.first?.isFavorite == false)
        #expect(store.removeFavoriteCallCount == 1)
    }

    @Test
    func refreshFavoriteStatuses_syncsItemsFromStore() async {
        let movie = MovieItem.fixture(id: 1, isFavorite: false)
        let useCase = FetchMoviesUseCaseSpy()
        useCase.defaultResult = .success(MoviesPage(items: [movie], nextPage: nil))
        let store = FavoriteMoviesStoreSpy()
        let sut = MovieListViewModel(fetchMoviesUseCase: useCase, favoriteMoviesStore: store)
        await sut.loadInitialMovies()

        store.setFavoriteMovies([movie.updatingFavorite(to: true)])
        sut.refreshFavoriteStatuses()

        guard case .content(let items, _, _) = sut.state else {
            Issue.record("Expected content state")
            return
        }
        #expect(items.first?.isFavorite == true)
    }

    @Test
    func toggleFavorite_addingFavorite_whenStoreThrows_revertsToOriginalState() async {
        let movie = MovieItem.fixture(id: 1, isFavorite: false)
        let useCase = FetchMoviesUseCaseSpy()
        useCase.defaultResult = .success(MoviesPage(items: [movie], nextPage: nil))
        let store = FavoriteMoviesStoreSpy()
        store.addFavoriteError = TestLocalizedError(message: "Failed to favorite")
        let sut = MovieListViewModel(fetchMoviesUseCase: useCase, favoriteMoviesStore: store)
        await sut.loadInitialMovies()

        await sut.toggleFavorite(for: movie)

        guard case .content(let items, _, _) = sut.state else {
            Issue.record("Expected content state")
            return
        }
        #expect(store.addFavoriteCallCount == 1)
        #expect(items.first?.isFavorite == false)
    }

    @Test
    func toggleFavorite_removingFavorite_whenStoreThrows_revertsToOriginalState() async {
        let movie = MovieItem.fixture(id: 1, isFavorite: true)
        let useCase = FetchMoviesUseCaseSpy()
        useCase.defaultResult = .success(MoviesPage(items: [movie], nextPage: nil))
        let store = FavoriteMoviesStoreSpy()
        // Seed the store so the item's `isFavorite` (re-derived from the store during
        // `loadInitialMovies`) actually starts as `true`, matching the fixture.
        store.setFavoriteMovies([movie])
        store.removeFavoriteError = TestLocalizedError(message: "Failed to remove favorite")
        let sut = MovieListViewModel(fetchMoviesUseCase: useCase, favoriteMoviesStore: store)
        await sut.loadInitialMovies()

        await sut.toggleFavorite(for: movie)

        guard case .content(let items, _, _) = sut.state else {
            Issue.record("Expected content state")
            return
        }
        #expect(store.removeFavoriteCallCount == 1)
        #expect(items.first?.isFavorite == true)
    }

    @Test
    func search_whileLoadNextPageIsInFlight_stillExecutesAndDiscardsTheStalePaginationResult() async {
        let useCase = GatedFetchMoviesUseCaseSpy()
        let initialItems = (1...5).map { MovieItem.fixture(id: $0) }
        await useCase.configure(
            resultsToReturn: [
                .success(MoviesPage(items: initialItems, nextPage: 2)), // call 1: loadInitialMovies
                .success(MoviesPage(items: [.fixture(id: 6)], nextPage: 3)) // call 2: loadNextPageIfNeeded (held)
            ],
            defaultResult: .success(MoviesPage(items: [.fixture(id: 50)], nextPage: nil)), // call 3: search
            callIndicesToHold: [2]
        )
        let sut = MovieListViewModel(fetchMoviesUseCase: useCase, favoriteMoviesStore: FavoriteMoviesStoreSpy())

        await sut.loadInitialMovies()

        let paginationTask = Task { await sut.loadNextPageIfNeeded(currentIndex: 0) }
        await waitUntil { await useCase.executeCallCount == 2 }

        sut.search(query: "batman")
        try? await Task.sleep(nanoseconds: 500_000_000)

        // The search's fetch must have actually reached the use case, even though the pagination
        // fetch triggered moments earlier is still awaiting release.
        #expect(await useCase.executeCallCount == 3)
        #expect(await useCase.receivedSearchQueries == [nil, nil, "batman"])

        // Now let the stale pagination fetch resolve. Its result must be discarded (it belongs to an
        // older fetch generation), and must not corrupt the state that search already produced.
        await useCase.release(callIndex: 2)
        await paginationTask.value

        guard case .content(let items, let isLoadingNextPage, _) = sut.state else {
            Issue.record("Expected content state")
            return
        }
        #expect(items.map(\.id) == [50])
        #expect(isLoadingNextPage == false)
    }
}
