import Foundation
import XCTest
@testable import NetworkKit

final class APIClientTests: XCTestCase {
    override func tearDown() {
        MockURLProtocol.requestHandler = nil
        super.tearDown()
    }

    func testSuccessfulRequestReturnsResponseData() async throws {
        let client = makeAPIClient()
        MockURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.url?.path, "/profile")
            return MockURLProtocol.response(statusCode: 200, data: Data("ok".utf8), request: request)
        }

        let data = try await client.send(Endpoint(path: "/profile"))

        XCTAssertEqual(String(data: data, encoding: .utf8), "ok")
    }

    func testAuthenticatedRequestAttachesAccessToken() async throws {
        let client = makeAuthenticatedClient(accessToken: "valid-token")
        MockURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer valid-token")
            return MockURLProtocol.response(statusCode: 200, data: Data("secure".utf8), request: request)
        }

        let data = try await client.send(Endpoint(path: "/accounts"))

        XCTAssertEqual(String(data: data, encoding: .utf8), "secure")
    }

    func testExpiredTokenRefreshesAndRetriesOriginalRequestOnce() async throws {
        let tokenProvider = MockAccessTokenProvider(accessToken: "expired-token")
        let tokenRefresher = MockAccessTokenRefresher(refreshedToken: "fresh-token")
        let client = makeAuthenticatedClient(tokenProvider: tokenProvider, tokenRefresher: tokenRefresher)
        let requestCount = RequestCounter()

        MockURLProtocol.requestHandler = { request in
            let count = await requestCount.increment()

            if count == 1 {
                XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer expired-token")
                return MockURLProtocol.response(statusCode: 401, data: Data(), request: request)
            }

            XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer fresh-token")
            return MockURLProtocol.response(statusCode: 200, data: Data("retried".utf8), request: request)
        }

        let data = try await client.send(Endpoint(path: "/accounts"))

        let finalRequestCount = await requestCount.currentValue()
        XCTAssertEqual(String(data: data, encoding: .utf8), "retried")
        XCTAssertEqual(tokenRefresher.refreshCallCount, 1)
        XCTAssertEqual(finalRequestCount, 2)
    }

    func testRefreshFailureDoesNotRetryOriginalRequestAgain() async {
        let tokenProvider = MockAccessTokenProvider(accessToken: "expired-token")
        let tokenRefresher = MockAccessTokenRefresher(errorToThrow: TestError.refreshRejected)
        let client = makeAuthenticatedClient(tokenProvider: tokenProvider, tokenRefresher: tokenRefresher)
        let requestCount = RequestCounter()

        MockURLProtocol.requestHandler = { request in
            _ = await requestCount.increment()
            return MockURLProtocol.response(statusCode: 401, data: Data(), request: request)
        }

        await XCTAssertThrowsErrorAsync(try await client.send(Endpoint(path: "/accounts"))) { error in
            XCTAssertEqual(error as? APIClientError, .refreshFailed)
        }

        let finalRequestCount = await requestCount.currentValue()
        XCTAssertEqual(tokenRefresher.refreshCallCount, 1)
        XCTAssertEqual(finalRequestCount, 1)
    }

    private func makeAPIClient() -> APIClient {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        return APIClient(
            baseURL: URL(string: "https://securebankingdemo.test")!,
            urlSession: URLSession(configuration: configuration)
        )
    }

    private func makeAuthenticatedClient(accessToken: String) -> AuthenticatedAPIClient {
        makeAuthenticatedClient(
            tokenProvider: MockAccessTokenProvider(accessToken: accessToken),
            tokenRefresher: MockAccessTokenRefresher(refreshedToken: "fresh-token")
        )
    }

    private func makeAuthenticatedClient(
        tokenProvider: MockAccessTokenProvider,
        tokenRefresher: MockAccessTokenRefresher
    ) -> AuthenticatedAPIClient {
        AuthenticatedAPIClient(
            apiClient: makeAPIClient(),
            tokenProvider: tokenProvider,
            tokenRefresher: tokenRefresher
        )
    }
}

private final class MockURLProtocol: URLProtocol, @unchecked Sendable {
    nonisolated(unsafe) static var requestHandler: (@Sendable (URLRequest) async throws -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        Task {
            guard let handler = Self.requestHandler else {
                client?.urlProtocol(self, didFailWithError: TestError.missingRequestHandler)
                return
            }

            do {
                let (response, data) = try await handler(request)
                client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
                client?.urlProtocol(self, didLoad: data)
                client?.urlProtocolDidFinishLoading(self)
            } catch {
                client?.urlProtocol(self, didFailWithError: error)
            }
        }
    }

    override func stopLoading() {}

    static func response(
        statusCode: Int,
        data: Data,
        request: URLRequest
    ) -> (HTTPURLResponse, Data) {
        (
            HTTPURLResponse(
                url: request.url!,
                statusCode: statusCode,
                httpVersion: nil,
                headerFields: nil
            )!,
            data
        )
    }
}

private final class MockAccessTokenProvider: AccessTokenProviding, @unchecked Sendable {
    let accessToken: String?

    init(accessToken: String?) {
        self.accessToken = accessToken
    }

    func currentAccessToken() async throws -> String? {
        accessToken
    }
}

private final class MockAccessTokenRefresher: AccessTokenRefreshing, @unchecked Sendable {
    let refreshedToken: String?
    let errorToThrow: Error?
    private(set) var refreshCallCount = 0

    init(refreshedToken: String? = nil, errorToThrow: Error? = nil) {
        self.refreshedToken = refreshedToken
        self.errorToThrow = errorToThrow
    }

    func refreshAccessToken() async throws -> String {
        refreshCallCount += 1

        if let errorToThrow {
            throw errorToThrow
        }

        return refreshedToken ?? "fresh-token"
    }
}

private actor RequestCounter {
    private var value = 0

    func increment() -> Int {
        value += 1
        return value
    }

    func currentValue() -> Int {
        value
    }
}

private enum TestError: Error {
    case missingRequestHandler
    case refreshRejected
}

private func XCTAssertThrowsErrorAsync(
    _ expression: @autoclosure () async throws -> some Any,
    _ errorHandler: (Error) -> Void,
    file: StaticString = #filePath,
    line: UInt = #line
) async {
    do {
        _ = try await expression()
        XCTFail("Expected expression to throw.", file: file, line: line)
    } catch {
        errorHandler(error)
    }
}
