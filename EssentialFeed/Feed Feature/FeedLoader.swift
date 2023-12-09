import Foundation

/// Error here is a placeholder name for the concrete error type that will ultimately be used - a label for the generic effectively
/// Swift.Error is a restriction the concrete types must conform to
/// We use a generic type for error to allow flexibility in the types of errors that can be used with this enum.
/// The FeedItem type is concretie, in contrast, as we will only ever receive one FeedItem result type.
/// Basically we are saying that the loadFeed result can fail in many ways that we may be interested to know about.
/// However, if successful, it will only contain one type of data
public enum LoadFeedResult<Error: Swift.Error> {
    case success([FeedItem])
    case failure(Error)
}

/// This abstraction defines the functionality of a feed loader
/// This allows for several different implementations ie: RemoteFeedLoader
protocol FeedLoader {
    associatedtype Error: Swift.Error
   
    /// A type with conformance to FeedLoader must decide how it will handle a LoadFeedResult and specify what kind of Error can occur
    func load(completion: @escaping (LoadFeedResult<Error>) -> Void)
}
