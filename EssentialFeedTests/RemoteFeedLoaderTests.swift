//
//  RemoteFeedLoaderTests.swift
//  EssentialFeedTests
//
//  Created by Jared Conover on 2022-03-04.
//

import Foundation
import XCTest
import EssentialFeed

class RemoteFeedLoaderTests: XCTestCase {

    func test_init_doesNotRequestDataFromURL() {
        let (_, client) = makeSUT()

//        XCTAssertNil(client.requestedURL)
        XCTAssertTrue(client.requestedURLs.isEmpty)
    }

    func test_load_requestsDataFromURL() {
        // Arrange
        let url = URL(string: "http://a-given-url.com")!
        let (sut, client) = makeSUT(url: url)
        // Act
        sut.load { _ in }

        // Assert
        XCTAssertEqual(client.requestedURLs, [url])
    }

    func test_loadTwice_requestsDataFromURLTwice() {
        // Arrange
        let url = URL(string: "http://a-given-url.com")!
        let (sut, client) = makeSUT(url: url)
        // Act
        sut.load { _ in }
        sut.load { _ in }

        // Assert
        XCTAssertEqual(client.requestedURLs, [url, url])
    }

    func test_load_deliversErrorOnClientError() {
        // Arrange
        // Build a client (HTTPClientSpy), a RemoteFeedLoader (the SUT) (using the client)
        // The client we make is an HTTPClientSpy
        let (sut, client) = makeSUT()

        // Act
        // Calling load on the RFL causes the client's get method to be called
        var capturedErrors = [RemoteFeedLoader.Error]()
        sut.load { capturedErrors.append($0) }

        // Simulating the client throwing an error
        let clientError = NSError(domain: "Test", code: 0)
        client.complete(with: clientError)

        XCTAssertEqual(capturedErrors, [.connectivity])

    }

    func test_load_deliversErrorOnNon200HTTPResponse() {
        // Arrange
        // Build a client (HTTPClientSpy), a RemoteFeedLoader (the SUT) (using the client)
        // The client we make is an HTTPClientSpy
        let (sut, client) = makeSUT()

        // Act
        // Calling load on the RFL causes the client's get method to be called
        var capturedErrors = [RemoteFeedLoader.Error]()
        sut.load { capturedErrors.append($0) }

        // Simulating the client completing with a status code
        client.complete(withStatusCode: 400)

        XCTAssertEqual(capturedErrors, [.invalidData])

    }

    // MARK: - Helpers

    private func makeSUT(url: URL = URL(string: "http://a-given-url.com")!) -> (sut: RemoteFeedLoader, client: HTTPClientSpy) {
        let client = HTTPClientSpy()
        let sut = RemoteFeedLoader(url: url, client: client)
        return (sut, client)
    }

    private class HTTPClientSpy: HTTPClient {
        var messages = [(url: URL, completion: (Error?, HTTPURLResponse?) -> Void)]()
        var requestedURLs: [URL] {
            messages.map { $0.url }
        }

        func get(from url: URL, completion: @escaping (Error?, HTTPURLResponse?) -> Void) {
            messages.append((url, completion))
        }

        func complete(with error: Error, index: Int = 0) {
            messages[index].completion(error, nil)
        }

        func complete(withStatusCode code: Int, at index: Int = 0 ) {
            let response = HTTPURLResponse(
                url: requestedURLs[index],
                statusCode: code,
                httpVersion: nil,
                headerFields: nil
            )

            messages[index].completion(nil, response)
        }
    }
}
