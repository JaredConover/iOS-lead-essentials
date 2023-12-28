import XCTest
import EssentialFeed

protocol HTTPSession {
    func dataTask(with url: URL, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> HTTPSessionTask
}

protocol HTTPSessionTask {
    func resume()
}

class URLSessionHTTPClient {
    let session: HTTPSession

    init(session: HTTPSession) {
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
    // Ensures the task for a specific URL is resumed once when get is called
    func test_getFromURL_resumesDataTask () {
        let url = URL(string: "http://any-url.com")!
        let session = HTTPSessionSpy()
        let task = URLSessionDataTaskSpy()
        session.stub(url: url, task: task)

        let sut = URLSessionHTTPClient(session: session)

        sut.get(from: url) {  _ in }

        XCTAssertEqual(task.resumeCallCount, 1)
    }

    func test_getFromURL_failsOnRequestError () {
        let url = URL(string: "http://any-url.com")!
        let error = NSError(domain: "Error", code: 123)

        let session = HTTPSessionSpy()
        session.stub(url: url, error: error)

        let sut = URLSessionHTTPClient(session: session)

        let exp = expectation(description: "request loaded")
        sut.get(from: url) { result in
            switch result {
                case let .httpClientFailure(receivedError as NSError):
                    XCTAssertEqual(error, receivedError)
                default:
                    XCTFail("Expecte failure with error: \(error), but received result \(result)")
            }
            exp.fulfill()
        }

        wait(for: [exp], timeout: 1.0)
    }

    // MARK: Helpers
    private class HTTPSessionSpy: HTTPSession {
        private var stubs = [URL: Stub]()

        private struct Stub {
            let task: HTTPSessionTask
            let error: Error?
        }

        func stub(url:URL, task: HTTPSessionTask = FakeURLSessionDataTask(), error: Error? = nil) {
            stubs[url] = Stub(task: task, error: error)
        }

        func dataTask(with url: URL, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> HTTPSessionTask {
            guard let stub = stubs[url] else {
                fatalError("Could not find stub for \(url)")
            }
            completionHandler(nil, nil, stub.error)
            return stub.task
        }
    }

    private class FakeURLSessionDataTask: HTTPSessionTask {
        func resume() {}
    }
    
    private class URLSessionDataTaskSpy: HTTPSessionTask {
        var resumeCallCount = 0

        func resume() {
            resumeCallCount += 1
        }
    }
}
