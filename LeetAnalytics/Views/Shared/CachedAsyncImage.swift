import SwiftUI

/// File-level URLSession with a persistent disk cache (50 MB).
/// Images downloaded once are served from disk on subsequent launches
/// without a network request (.returnCacheDataElseLoad).
private let imageSession: URLSession = {
    let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)
        .first?.appendingPathComponent("ImageCache")
    let config = URLSessionConfiguration.default
    config.urlCache = URLCache(
        memoryCapacity: 10_000_000,
        diskCapacity: 50_000_000,
        directory: cacheDir
    )
    config.requestCachePolicy = .returnCacheDataElseLoad
    return URLSession(configuration: config)
}()

/// Drop-in replacement for AsyncImage that persists images to disk.
/// Profile pictures and badge icons rarely change — caching them eliminates
/// blank/loading states on low-bandwidth connections.
struct CachedAsyncImage<Placeholder: View>: View {
    let url: URL?
    let placeholder: () -> Placeholder
    @State private var image: UIImage?

    init(url: URL?, @ViewBuilder placeholder: @escaping () -> Placeholder) {
        self.url = url
        self.placeholder = placeholder
    }

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                placeholder()
            }
        }
        .task(id: url?.absoluteString) {
            guard let url, image == nil else { return }
            self.image = await loadImage(from: url)
        }
    }

    private func loadImage(from url: URL) async -> UIImage? {
        guard let (data, _) = try? await imageSession.data(from: url) else { return nil }
        return UIImage(data: data)
    }
}
