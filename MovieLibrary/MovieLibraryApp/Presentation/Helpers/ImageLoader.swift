//
//  ImageLoader.swift
//  MovieLibraryApp
//
//  Created by Allexia Azevedo de Morais on 16/07/26.
//

import UIKit

protocol ImageLoadingProtocol: Sendable {
    func loadImage(from url: URL) async throws -> UIImage
}

enum ImageLoaderError: Error {
    case invalidImageData
}

final class ImageLoader: ImageLoadingProtocol, @unchecked Sendable {
    private let cache = NSCache<NSURL, UIImage>()
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func loadImage(from url: URL) async throws -> UIImage {
        if let cached = cache.object(forKey: url as NSURL) {
            return cached
        }

        let (data, response) = try await session.data(from: url)
        guard
            let httpResponse = response as? HTTPURLResponse,
            (200...299).contains(httpResponse.statusCode),
            let image = UIImage(data: data)
        else {
            throw ImageLoaderError.invalidImageData
        }

        cache.setObject(image, forKey: url as NSURL)
        return image
    }
}
