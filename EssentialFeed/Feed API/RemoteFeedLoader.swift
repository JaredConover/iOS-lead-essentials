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
            case let .httpClientSuccess(data, response):
                do {
                    let items = try FeedItemsMapper.map(data, response)
                    loadFeedCompletion(.loadFeedSuccess(items))
                } catch {
                    loadFeedCompletion(.loadFeedFailure(.invalidData))
                }
            case .httpClientFailure: loadFeedCompletion(.loadFeedFailure(.connectivity))
            }
        }

        client.get(from: url, httpClientCompletion: httpCompletion)
    }
}


private class FeedItemsMapper {
    static func map(_ data: Data, _ response: HTTPURLResponse) throws -> [FeedItem] {
        guard response.statusCode == 200 else {
            throw RemoteFeedLoader.Error.invalidData
        }
        let root = try JSONDecoder().decode(Root.self, from: data)
        return root.items.map { $0.feedItem }
    }

    // This represents the root of the JSON object we receive from the api
    struct Root: Decodable {
        let items : [APIItem]
    }

    // We create an API specific item so that impmlentation details from the api don't leak into the higher level abstractions ie: having to specify the key path for imageURL = "image" in the FeedItem. This way the FeedItem has no knowledge of the API
    // A Classicist TDD Approach.. 32:50
    struct APIItem: Decodable {
        let id: UUID
        let description: String?
        let location: String?
        let image: URL

        var feedItem: FeedItem {
            FeedItem(id: id, description: description, location: location, imageURL: image)
        }
    }
}


// 32:26
