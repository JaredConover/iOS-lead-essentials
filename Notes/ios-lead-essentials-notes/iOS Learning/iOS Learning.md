What does the @testable do for import ie: `@testable import Poka`


```swift   @MainActor func test_ApiManager() {
        guard let url = URL(string: "https://localhost:8080/") else { return XCTFail("Invalid!") }

        let request = URLRequest(url: url.appendingPathComponent("get-info"))
        let data = """
        {
            "test": "value"
        }
        """.data(using: .utf8)!

        let mock = Mock(url: request.url!, dataType: .json, statusCode: 200, data: [
            .get: data,
            .post: data,
            .put: data,
            .delete: data
        ], additionalHeaders: [
            "test": "value"
        ])

        mock.register()

        let manager = PKAPIManager(baseURL: url, session: URLSession(configuration: .mocker))

        let xpect = expectation(description: "response")
        manager.execute(request, mapper: nil, completion: { response in
            xpect.fulfill()
        })

        wait(for: [xpect], timeout: 5.0)
    }
```

Which path should and take and where should I invest my time?
I want to follow a course that addresses architectural topics but there are a few to chose from:
	- iOS lead essentials
		- I've spent money on it
		- Covers testing and architecture / modularity
		- No swiftUI
	- Pointfree
		- Haven't paid for a sub but it's not crazy expensive
		- There are videos that go over arch while talking about swiftUI

Basically I feel I should try to finish the iOS lead essentials course but I've had trouble sustaining motivation on it. Maybe  I should finish at least the first module which would involves 100 minutes across 4 videos. That could potentially be a good point to re-evaluate


### Look deeper into
- URL Loading system
- 