import Foundation

public final class RemoteFeedLoader: FeedLoader {
    private let url: URL
    private let client: HTTPClient

    public enum Error: Swift.Error {
        case connectivity
        case invalidData
    }

    public typealias Result = LoadFeedResult<Error>

    public init(url: URL, client: HTTPClient) {
        self.client = client
        self.url = url
    }

    // The implementation/conformance to FeedLoader protocol
    public func load(completion loadFeedCompletion: @escaping (Result) -> Void) {
        client.get(from: url) { [weak self] httpClientResult in
            guard self != nil else { return }
            
            switch httpClientResult {
            case let .httpClientSuccess(data, response):
                loadFeedCompletion(FeedItemsMapper.map(data, from: response))
            case .httpClientFailure:
                loadFeedCompletion(.failure(.connectivity))
            }
        }
    }
}
