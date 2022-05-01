//
//  RemoteFeedLoader.swift
//  EssentialFeed
//
//  Created by Jared Conover on 2022-03-11.
//

import Foundation

// MARK: - HTTPClient

public enum HTTPClientResult {
    case httpClientSuccess(Data, HTTPURLResponse)
    case httpClientFailure(Error)
}

public protocol HTTPClient {
    func get(from url: URL, httpClientCompletion: @escaping (HTTPClientResult) -> Void)
}

// MARK: - RemoteFeedLoader

public final class RemoteFeedLoader {
    private let url: URL
    private let client: HTTPClient

    public enum Error: Swift.Error {
        case connectivity
        case invalidData
    }

    public enum Result: Equatable {
        case loadFeedSuccess([FeedItem])
        case loadFeedFailure(Error)
    }

    public init(url: URL, client: HTTPClient) {
        self.client = client
        self.url = url
    }

    public func load(loadFeedCompletion: @escaping (Result) -> Void) {

        // Prepare the completion block that will be passed to the httpClient
        let httpCompletion: (HTTPClientResult) -> Void = { httpClientResult in
            switch httpClientResult {
            case let .httpClientSuccess(data, _):
                // here we do a basic test to see if the json is valid
                if let _ = try? JSONSerialization.jsonObject(with: data) {
                    loadFeedCompletion(.loadFeedSuccess([]))
                } else {
                    loadFeedCompletion(.loadFeedFailure(.invalidData))
                }
            case .httpClientFailure: loadFeedCompletion(.loadFeedFailure(.connectivity))
            }
        }

        client.get(from: url, httpClientCompletion: httpCompletion)
    }
}
