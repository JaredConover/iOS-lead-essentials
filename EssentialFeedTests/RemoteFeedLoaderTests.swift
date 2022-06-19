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
            let emptyListJSON = Data(bytes: "{\"items\": []}".utf8)
            client.complete(withStatusCode: 200, data: emptyListJSON)
        })
    }

    func test_load_deliversItemsOn200HTTPResponseWithJSONItems() {
        // create 2 valid feedItems, build JSON objects from them, send them to the rfl, check we get back the same items.

        let (sut, client) = makeSUT()

        let item1 = FeedItem(
            id: UUID(),
            description: nil,
            location: nil,
            imageUrl: URL(string: "http://a-url.com")!)

        let item1JSON = [
            "id" : item1.id.uuidString,
            "image" : item1.imageUrl.absoluteString
        ]

        let item2 = FeedItem(
            id: UUID(),
            description: "a description",
            location: "a location",
            imageUrl: URL(string: "http://another-url.com")!)

        let item2JSON = [
            "id" : item2.id.uuidString,
            "description" : item2.description,
            "location" : item2.location,
            "image" : item2.imageUrl.absoluteString
        ]

        let itemsJson = [
            "items" : [item1JSON, item2JSON]
        ]

        expect(sut, toCompleteWithResult: .loadFeedSuccess([item1, item2]), when: {
            let jsonData = try! JSONSerialization.data(withJSONObject: itemsJson)
            client.complete(withStatusCode: 200, data: jsonData)
        })


    }

    // MARK: - Helpers

    private func makeSUT(url: URL = URL(string: "http://a-given-url.com")!) -> (sut: RemoteFeedLoader, client: HTTPClientSpy) {
        let client = HTTPClientSpy()
        let sut = RemoteFeedLoader(url: url, client: client)
        return (sut, client)
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
