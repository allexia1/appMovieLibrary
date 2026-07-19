//
//  CachedAsyncImage.swift
//  MovieLibraryApp
//

import SwiftUI

/// Carrega uma imagem de forma assíncrona usando `ImageLoadingProtocol` (que já mantém um cache
/// próprio em `NSCache`), em vez do `AsyncImage` nativo — preservando o comportamento de cache do
/// `ImageLoader` existente.
struct CachedAsyncImage<Content: View, Placeholder: View>: View {
    let url: URL?
    let imageLoader: ImageLoadingProtocol
    @ViewBuilder let content: (Image) -> Content
    @ViewBuilder let placeholder: () -> Placeholder

    @State private var uiImage: UIImage?

    var body: some View {
        Group {
            if let uiImage {
                content(Image(uiImage: uiImage))
            } else {
                placeholder()
            }
        }
        .task(id: url) {
            uiImage = nil
            guard let url else { return }
            uiImage = try? await imageLoader.loadImage(from: url)
        }
    }
}
