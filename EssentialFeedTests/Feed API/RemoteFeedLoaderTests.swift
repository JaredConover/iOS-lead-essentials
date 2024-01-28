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

        expect(sut, toCompleteWithResult: failure(.connectivity), when: {
            // Simulating the client throwing an error
            let clientError = NSError(domain: "Test", code: 0)
            client.complete(withError: clientError)
        })
    }

    func test_load_deliversErrorOnNon200HTTPResponse() {
        // Arrange
        // Build a client (HTTPClientSpy), a RemoteFeedLoader (the SUT) (using the client)
        // The client we make is an HTTPClientSpy
        let (sut, client) = makeSUT()
        let samples = [199, 201, 300, 400, 500]

        samples.enumerated().forEach { index, code in
            expect(sut, toCompleteWithResult: failure(.invalidData), when: {
                // Simulating the client completing with a status code
                let json = makeItemsJSON([])
                client.complete(withStatusCode: code, data: json, at: index)

            })
        }
    }

    func test_load_deliversErrorOn200HTTPResponseWithInvalidJSON() {
        let (sut, client) = makeSUT()

        expect(sut, toCompleteWithResult: failure(.invalidData), when: {
            let invalidJSON = Data("Invalid Json".utf8)
            client.complete(withStatusCode: 200, data: invalidJSON)
        })
    }

    func test_load_deliversNoItemsOn200HTTPResponseWithEmptyJSONList() {
        let (sut, client) = makeSUT()

        expect(sut, toCompleteWithResult: .success([]), when: {
            let emptyListJSON = makeItemsJSON([])
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

        expect(sut, toCompleteWithResult: .success(items), when: {
            let jsonData = makeItemsJSON([item1.json, item2.json])
            client.complete(withStatusCode: 200, data: jsonData)
        })
    }

    func test_load_doesNotDeliverResultsAfterSUTInstanceDeallocated() {
        /// To prevent async errors
        /// Its possible that the client may still comlete even if the rfl is deallocated
        let url = URL(string: "http://any-url.com")!
        let client = HTTPClientSpy()
        var sut : RemoteFeedLoader? = RemoteFeedLoader(url: url, client: client)

        var capturedResults = [RemoteFeedLoader.Result]()
        sut?.load { capturedResults.append($0) }
        sut = nil

        client.complete(withStatusCode: 200, data: makeItemsJSON([]))
        XCTAssertTrue(capturedResults.isEmpty)
    }

    // MARK: - Helpers

    private func makeSUT(url: URL = URL(string: "http://a-given-url.com")!, file: StaticString = #filePath, line: UInt = #line) -> (sut: RemoteFeedLoader, client: HTTPClientSpy) {
        let client = HTTPClientSpy()
        let sut = RemoteFeedLoader(url: url, client: client)
        trackForMemoryLeaks(sut, file: file, line: line)
        trackForMemoryLeaks(client, file: file, line: line)
        return (sut, client)
    }

    private func failure(_ error: RemoteFeedLoader.Error) -> RemoteFeedLoader.Result {
        .failure(error)
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

    private func expect(_ sut: RemoteFeedLoader, toCompleteWithResult expectedResult: RemoteFeedLoader.Result, when action: () -> Void, file: StaticString = #filePath, line: UInt = #line) {

        let exp = expectation(description: "Wait for load completion")
        sut.load { receivedResult in
            switch (receivedResult, expectedResult) {
                case let (.success(receivedItems), .success(expectedItems)):
                    XCTAssertEqual(receivedItems, expectedItems, file: file, line: line)

                case let (.failure(receivedFailure as RemoteFeedLoader.Error), .failure(expectedFailure as RemoteFeedLoader.Error)):
                    XCTAssertEqual(receivedFailure, expectedFailure, file: file, line: line)

                default:
                    XCTFail("Received result \(receivedResult) did not match expectation \(expectedResult)", file: file, line: line)
            }
            exp.fulfill()
        }

        action()
        wait(for: [exp], timeout: 1.0)
    }

    private class HTTPClientSpy: HTTPClient {
        var messages = [(url: URL, completion: (HTTPClientResult) -> Void)]()
        var requestedURLs: [URL] {
            messages.map { $0.url }
        }

        func get(from url: URL, httpClientCompletion: @escaping (HTTPClientResult) -> Void) {
            messages.append((url, httpClientCompletion))
        }

        func complete(withError error: Error, index: Int = 0) {
            messages[index].completion(.httpClientFailure(error))
        }

        func complete(withStatusCode code: Int, data: Data, at index: Int = 0 ) {
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
