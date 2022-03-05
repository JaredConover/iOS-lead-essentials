//
//  RemoteFeedLoaderTests.swift
//  EssentialFeedTests
//
//  Created by Jared Conover on 2022-03-04.
//

import Foundation
import XCTest

class RemoteFeedLoader {
    let client: HTTPClient

    let url: URL

    init(url: URL, client: HTTPClient) {
        self.client = client
        self.url = url
    }

    func load() {
        client.get(from: url)
    }
}

protocol HTTPClient {
    func get(from url: URL)
}

class HTTPClientSpy: HTTPClient {

    func get(from url: URL) {
        requestedURL = url
    }

    var requestedURL: URL?
}

class RemoteFeedLoaderTests: XCTestCase {

    func test_init_doesNotRequestDataFromURL() {
        let url = URL(string: "http://a-given-url.com")!
        let client = HTTPClientSpy()
        _ = RemoteFeedLoader(url: url, client: client)

        XCTAssertNil(client.requestedURL)
    }

    func test_load_requestDataFromURL() {

        // Arrang
        let url = URL(string: "http://a-given-url.com")!
        let client = HTTPClientSpy()
        let sut = RemoteFeedLoader(url: url, client: client)

        // Act
        sut.load()

        // Assert
        XCTAssertEqual(client.requestedURL, url)
    }
}
