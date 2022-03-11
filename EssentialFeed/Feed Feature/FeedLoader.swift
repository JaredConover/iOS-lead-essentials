//
//  FeedLoader.swift
//  EssentialFeed
//
//  Created by Jared Conover on 2022-03-04.
//

import Foundation

enum LoadFeedResult {
    case sucess([FeedItem])
    case failure(Error)
}

protocol FeedLoader {
    func load(completion: @escaping (LoadFeedResult) -> Void)
}
