//
//  RemoteFeedLoader.swift
//  EssentialFeed
//
//  Created by Jared Conover on 2022-03-11.
//

import Foundation

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
        client.get(from: url) { httpClientResult in
            switch httpClientResult {
            case let .httpClientSuccess(data, response):
                loadFeedCompletion(FeedItemsMapper.map(data, from: response))
            case .httpClientFailure:
                loadFeedCompletion(.loadFeedFailure(.connectivity))
            }
        }
    }
}
