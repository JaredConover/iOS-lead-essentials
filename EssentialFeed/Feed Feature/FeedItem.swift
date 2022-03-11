//
//  FeedItem.swift
//  EssentialFeed
//
//  Created by Jared Conover on 2022-03-04.
//

import Foundation

struct FeedItem {
    let id: UUID
    let description: String?
    let location: String?
    let imageUrl: URL
}
