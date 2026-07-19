//
//  MovieGridView.swift
//  MovieLibraryApp
//

import SwiftUI

/// Grid responsivo com estados de loading/empty/error/paginação, reutilizado pelas telas de
/// Filmes e Favoritos — equivalente SwiftUI da antiga `MovieListScreenView` compartilhada.
struct MovieGridView: View {
    let state: ScreenState<MovieItem>
    let imageLoader: ImageLoadingProtocol
    let emptyStateTitle: String
    let emptyStateSubtitle: String
    let onToggleFavorite: (MovieItem) -> Void
    let onReachLoadMoreThreshold: (Int) -> Void
    let onRefresh: () async -> Void
    let onRetry: () -> Void
    let onDismissPaginationError: () -> Void

    private let columns = [GridItem(.adaptive(minimum: 150), spacing: 16)]

    var body: some View {
        Group {
            switch state {
            case .loading:
                FeedbackStateView(kind: .loading)
            case .empty:
                FeedbackStateView(kind: .empty(title: emptyStateTitle, subtitle: emptyStateSubtitle))
            case .error(let message):
                FeedbackStateView(kind: .error(message: message), onRetryTapped: onRetry)
            case .content(let items, let isLoadingNextPage, _):
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(Array(items.enumerated()), id: \.element.id) { index, movie in
                            NavigationLink(value: movie) {
                                MovieCardView(movie: movie, imageLoader: imageLoader) {
                                    onToggleFavorite(movie)
                                }
                            }
                            .buttonStyle(.plain)
                            .onAppear { onReachLoadMoreThreshold(index) }
                        }
                    }
                    .padding(16)

                    if isLoadingNextPage {
                        ProgressView()
                            .padding(.vertical, 12)
                    }
                }
                .refreshable { await onRefresh() }
            }
        }
        .alert(
            LocalizedStrings.commonErrorTitle,
            isPresented: paginationErrorBinding,
            presenting: paginationErrorMessage
        ) { _ in
            Button(LocalizedStrings.commonOK) { }
        } message: { message in
            Text(message)
        }
    }

    private var paginationErrorMessage: String? {
        if case .content(_, _, let message) = state { return message }
        return nil
    }

    private var paginationErrorBinding: Binding<Bool> {
        Binding(
            get: { paginationErrorMessage != nil },
            set: { isPresented in if !isPresented { onDismissPaginationError() } }
        )
    }
}
