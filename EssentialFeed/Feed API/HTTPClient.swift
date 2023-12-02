import Foundation

public enum HTTPClientResult {
    case httpClientSuccess(Data, HTTPURLResponse)
    case httpClientFailure(Error)
}

public protocol HTTPClient {
    func get(from url: URL, httpClientCompletion: @escaping (HTTPClientResult) -> Void)
}
                                                                                
