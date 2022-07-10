//
//  FeedItemsMapper.swift
//  EssentialFeed
//
//  Created by Jared Conover on 2022-07-10.
//

import Foundation

internal final class FeedItemsMapper {
    // This represents the root of the JSON object we receive from the api
    struct Root: Decodable {
        let items : [APIItem]
    }

    /// We create an API specific item so that impmlentation details from the api don't leak into the higher level abstractions ie: having to specify the key path for imageURL = "image" in the FeedItem. This way the FeedItem has no knowledge of the API
    /// A Classicist TDD Approach.. 32:50
    struct APIItem: Decodable {
        let id: UUID
        let description: String?
        let location: String?
        let image: URL

        var feedItem: FeedItem {
            FeedItem(id: id, description: description, location: location, imageURL: image)
        }
    }

    private static var OK_200: Int { return 200 }

    internal static func map(_ data: Data, _ response: HTTPURLResponse) throws -> [FeedItem] {
        guard response.statusCode == OK_200 else {
            throw RemoteFeedLoader.Error.invalidData
        }
        let root = try JSONDecoder().decode(Root.self, from: data)
        return root.items.map { $0.feedItem }
    }
}
