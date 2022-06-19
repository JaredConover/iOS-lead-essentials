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

        expect(sut, toCompleteWithResult: .loadFeedFailure(.connectivity), when: {
            // Simulating the client throwing an error
            let clientError = NSError(domain: "Test", code: 0)
            client.complete(with: clientError)
        })
    }

    func test_load_deliversErrorOnNon200HTTPResponse() {
        // Arrange
        // Build a client (HTTPClientSpy), a RemoteFeedLoader (the SUT) (using the client)
        // The client we make is an HTTPClientSpy
        let (sut, client) = makeSUT()
        let samples = [199, 201, 300, 400, 500]

        samples.enumerated().forEach { index, code in
            expect(sut, toCompleteWithResult: .loadFeedFailure(.invalidData), when: {
                // Simulating the client completing with a status code
                client.complete(withStatusCode: code, at: index)

            })
        }
    }

    func test_load_deliversErrorOn200HTTPResponseWithInvalidJSON() {
        let (sut, client) = makeSUT()

        expect(sut, toCompleteWithResult: .loadFeedFailure(.invalidData), when: {
            let invalidJSON = Data("Invalid Json".utf8)
            client.complete(withStatusCode: 200, data: invalidJSON)
        })
    }

    func test_load_deliversNoItemsOn200HTTPResponseWithEmptyJSONList() {
        let (sut, client) = makeSUT()

        expect(sut, toCompleteWithResult: .loadFeedSuccess([]), when: {
            let emptyListJSON = Data("{\"items\": []}".utf8)
            client.complete(withStatusCode: 200, data: emptyListJSON)
        })
    }

    func test_load_deliversItemsOn200HTTPResponseWithJSONItems() {
        // create 2 valid feedItems, build JSON objects from them, send them to the rfl, check we get back the same items.

        let (sut, client) = makeSUT()

        let item1 = makeItem(
            id: UUID(),
            imageURL: URL(string: "http://a-url.com")!)

        let item2 = makeItem(
            id: UUID(),
            description: "a description",
            location: "a location",
            imageURL: URL(string: "http://another-url.com")!)

        let items = [item1.model, item2.model]

        expect(sut, toCompleteWithResult: .loadFeedSuccess(items), when: {
            let jsonData = makeItemsJSON([item1.json, item2.json])
            client.complete(withStatusCode: 200, data: jsonData)
        })
    }

    // MARK: - Helpers

    private func makeSUT(url: URL = URL(string: "http://a-given-url.com")!) -> (sut: RemoteFeedLoader, client: HTTPClientSpy) {
        let client = HTTPClientSpy()
        let sut = RemoteFeedLoader(url: url, client: client)
        return (sut, client)
    }

    private func makeItem(id: UUID, description: String? = nil, location: String? = nil, imageURL: URL) -> (model: FeedItem, json: [String: Any]) {
        let model = FeedItem(id: id, description: description, location: location, imageURL: imageURL)
        let json = [
            "id" : id.uuidString,
            "description" : description,
            "location" : location,
            "image" : imageURL.absoluteString
        ].reduce(into: [String: Any]()) { (acc, e) in
            if let value = e.value { acc[e.key] = value }
        }

        return(model, json)
    }

    private func makeItemsJSON(_ items: [[String: Any]]) -> Data {
        let json = [ "items" : items ]
        return try! JSONSerialization.data(withJSONObject: json)
    }

    private func expect(_ sut: RemoteFeedLoader, toCompleteWithResult result: RemoteFeedLoader.Result, when action: () -> Void, file: StaticString = #filePath, line: UInt = #line) {

        var capturedResults = [RemoteFeedLoader.Result]()
        sut.load { capturedResults.append($0) }

        action()

        XCTAssertEqual(capturedResults, [result], file: file, line: line)
    }

    private class HTTPClientSpy: HTTPClient {
        var messages = [(url: URL, completion: (HTTPClientResult) -> Void)]()
        var requestedURLs: [URL] {
            messages.map { $0.url }
        }

        func get(from url: URL, httpClientCompletion: @escaping (HTTPClientResult) -> Void) {
            messages.append((url, httpClientCompletion))
        }

        func complete(with error: Error, index: Int = 0) {
            messages[index].completion(.httpClientFailure(error))
        }

        func complete(withStatusCode code: Int, data: Data = Data(), at index: Int = 0 ) {
            let response = HTTPURLResponse(
                url: requestedURLs[index],
                statusCode: code,
                httpVersion: nil,
                headerFields: nil
            )!

            messages[index].completion(.httpClientSuccess(data, response))
        }
    }
}
