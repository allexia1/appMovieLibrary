//
//  ImageLoaderSpy.swift
//  MovieLibraryApp
//

import UIKit
@testable import MovieLibraryApp

final class ImageLoaderSpy: ImageLoadingProtocol, @unchecked Sendable {
    var imageToReturn: UIImage? = UIImage()
    var errorToThrow: Error?
    private(set) var loadImageCallCount = 0

    func loadImage(from url: URL) async throws -> UIImage {
        loadImageCallCount += 1
        if let errorToThrow { throw errorToThrow }
        guard let imageToReturn else { throw ImageLoaderError.invalidImageData }
        return imageToReturn
    }
}
