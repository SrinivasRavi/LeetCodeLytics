import Foundation

/// Intercepts URLSession requests in tests and returns configured responses.
/// Usage:
///   MockURLProtocol.responseProvider = { _ in (200, responseData) }
///   let session = MockURLProtocol.makeSession()
final class MockURLProtocol: URLProtocol {
    /// Set this before each test. Receives the URLRequest, returns (statusCode, data).
    static var responseProvider: ((URLRequest) throws -> (Int, Data))?

    static func makeSession() -> URLSession {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        return URLSession(configuration: config)
    }

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let provider = MockURLProtocol.responseProvider else {
            client?.urlProtocol(self, didFailWithError: URLError(.unknown))
            return
        }
        do {
            let (statusCode, data) = try provider(request)
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: statusCode,
                httpVersion: nil,
                headerFields: nil
            )!
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}
