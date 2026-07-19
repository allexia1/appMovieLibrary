//
//  FeedbackStateView.swift
//  MovieLibraryApp
//

import SwiftUI

/// Estado de feedback em tela cheia: loading, vazio ou erro (com retry).
struct FeedbackStateView: View {
    enum Kind {
        case loading
        case empty(title: String, subtitle: String)
        case error(message: String)
    }

    let kind: Kind
    var onRetryTapped: (() -> Void)?

    var body: some View {
        switch kind {
        case .loading:
            ProgressView()
                .controlSize(.large)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .empty(let title, let subtitle):
            content(systemImage: "popcorn", title: title, subtitle: subtitle, showsRetry: false)
        case .error(let message):
            content(
                systemImage: "exclamationmark.triangle",
                title: LocalizedStrings.commonErrorTitle,
                subtitle: message,
                showsRetry: true
            )
        }
    }

    private func content(systemImage: String, title: String, subtitle: String, showsRetry: Bool) -> some View {
        VStack(spacing: 8) {
            Image(systemName: systemImage)
                .font(.system(size: 56, weight: .light))
                .foregroundStyle(.secondary)
            Text(title)
                .font(.headline)
                .multilineTextAlignment(.center)
            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            if showsRetry {
                Button(LocalizedStrings.commonRetry) { onRetryTapped?() }
                    .padding(.top, 8)
            }
        }
        .padding(.horizontal, 32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
