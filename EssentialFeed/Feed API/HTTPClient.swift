//
//  HTTPClient.swift
//  EssentialFeed
//
//  Created by Jared Conover on 2022-07-10.
//

import Foundation

public enum HTTPClientResult {
    case httpClientSuccess(Data, HTTPURLResponse)
    case httpClientFailure(Error)
}

public protocol HTTPClient {
    func get(from url: URL, httpClientCompletion: @escaping (HTTPClientResult) -> Void)
}
                                                                                
