import Foundation

public class URLSessionHTTPClient: HTTPClient {
    let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    private struct UnexpectedValuesRepresentation: Error {}

    public func get(from url: URL, httpClientCompletion completion: @escaping (HTTPClientResult) -> Void) {
        self.session.dataTask(with: url) { data, response, error in
            if let error {
                completion(.httpClientFailure(error))
            }
            else if let data, let response = response as? HTTPURLResponse {
                completion(.httpClientSuccess(data, response))
            }
            else {
                completion(.httpClientFailure(UnexpectedValuesRepresentation()))
            }
        }.resume()
    }
}
