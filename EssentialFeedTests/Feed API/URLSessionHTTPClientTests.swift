import XCTest
import EssentialFeed

class URLSessionHTTPClient {
    let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func get(from url: URL, completion: @escaping (HTTPClientResult) -> Void) {
        self.session.dataTask(with: url) { _, _, error in
            if let error {
                completion(.httpClientFailure(error))
            }
        }.resume()
    }
}

final class URLSessionHTTPClientTests: XCTestCase {

    func test_getFromURL_failsOnRequestError () {
        URLProtocolStub.startInterceptingRequests()
        let url = URL(string: "http://any-url.com")!
        let error = NSError(domain: "any error", code: 1)

        URLProtocolStub.stub(data: nil, response: nil, error: error)

        let sut = URLSessionHTTPClient()

        let exp = expectation(description: "request loaded")
        sut.get(from: url) { result in
            switch result {
                case let .httpClientFailure(receivedError as NSError):
                    XCTAssertEqual(error.domain, receivedError.domain)
                    XCTAssertEqual(error.code, receivedError.code)
                default:
                    XCTFail("Expecte failure with error: \(error), but received result \(result)")
            }
            exp.fulfill()
        }

        wait(for: [exp], timeout: 1.0)
        URLProtocolStub.stopInterceptingRequests()
    }

    // MARK: Helpers
    private class URLProtocolStub: URLProtocol {
        private static var stub: Stub?

        private struct Stub {
            let data: Data?
            let response: URLResponse?
            let error: Error?
        }

        static func stub(data: Data?, response: URLResponse?, error: Error?) {
            stub = Stub(data: data, response: response, error: error)
        }

        static func startInterceptingRequests() {
            URLProtocol.registerClass(URLProtocolStub.self)
        }
        
        static func stopInterceptingRequests() {
            URLProtocol.unregisterClass(URLProtocolStub.self)
            stub = nil
        }

        override class func canInit(with request: URLRequest) -> Bool {
            true
        }

        override class func canonicalRequest(for request: URLRequest) -> URLRequest {
            return request
        }

        override func startLoading() {
            guard let stub = URLProtocolStub.stub else { return }

            if let data = stub.data {
                client?.urlProtocol(self, didLoad: data)
            }
            
            if let response = stub.response {
                client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            }

            if let error = stub.error {
                client?.urlProtocol(self, didFailWithError: error)
            }

            client?.urlProtocolDidFinishLoading(self)
        }

        override func stopLoading() { }

    }
}
