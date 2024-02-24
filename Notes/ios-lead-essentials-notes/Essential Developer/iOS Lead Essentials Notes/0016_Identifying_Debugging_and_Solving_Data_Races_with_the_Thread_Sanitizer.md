Started 02/19/2024

#### Thread sanitizer
In addition to randomizing the order of tests, we can enable the option to run the thread sanitizer for our scheme under test/diagnostics. 
> The thread sanitizer is an LLVM based tool that detects data races at runtime

The `URLSesssionHTTPClient` implementation introduced threading to our codebase since `URLSession` dispatches requests on background threads to avoid stalling the main thread.

Threading can introduce issues such as data races
> A data race occurs when two or more threads access the same memory location concurrently without synchronisation and at least one access is a write

 " it looks like one of the tests initiates a request, but returns before the request finishes. This is a problem because that request that continues to run on a background thread could interfere with another test if something goes wrong"

It seems like the test classes teardown method which clears the stub is being called while the stub is still being used in the startLoading() method.
So a 'future' test could fail due to something related to a previous test execution which would be confusing and hard to debug and violates our principle that:
> Every operation started within a test method should finish before the method returns. (especially if you're running threads)

Our cause was determined to be that for our test that simply confirms the correct url is called, the test completes before the request because we are not validating anything in the response. Our async expectation fulfillment is only at the level of the `observeRequests()` method.
To solve this we looked at several possible options: 
- Increase the `expectedFulfillentCount` on our current expectation and add another fulfillment call in the empty get(from) {} completion.
	- This works but is not super readable and we cant be sure whether each of our fulfillment sites was called or if one was called twice.
- Add a separate async expectation to be fulfilled in the empty get(from) {} completion
- Capture the requests during the observeRequests method. Move the exp.fulfill to the empty get completion and validate the request properties after and ensure we have the correct number of requests.
```swift
func test_getFromURL_requestsFromProperURL() {
        let url = anyURL()        
        let exp = expectation(description: "wait for request")
        URLProtocolStub.observeRequests() { request in
            XCTAssertEqual(url, request.url)
            XCTAssertEqual(request.httpMethod, "GET")
            exp.fulfill()
        }
        let exp2 = expectation(description: "wait for request completion")
        makeSUT().get(from: url) { _ in exp2.fulfill()}
        wait(for: [exp, exp2], timeout: 1.0)
    }
```

These all technically work but they solve the issue from the clients point of view where the test is the client of the URLProtocolStub class. Our test in this case doesn't care about results however. Ideally we can fix this at the URLProtocolStub level, because this is the class responsible for handling the requests. The client ideally shouldn't have to bend over backwards to take care of something in the scope of responsibility of the provider class. 

To make this adjustment, we move the call to our injected requestObserver() method from the canInit (which is called before the loading) to the startLoading method. We execute it at the beginning of start loading, call `client?.urlProtocolDidFinishLoading()` and return with the void result of our observation closure. This way, the request will complete inside the scope of the test. This also means however that any value stubbing will not occur so any tests relying on that will fail if they also observe the request. Is this a bad thing? Will we ever need to both observe the request and stub the data, response or error?

In this case we were able to avoid handling this on the client's side since we control our `URLProtocolStub`, but if this wasn't the case, we would've been force to handle it in the client's behaviour.

The thread sanitizer helped us detect this issue but it adds a tremendous amount of overhead and can slow down the cpu up to 20x and increase memory usage by 5-10x according to Apple docs. So we don't want this to always be activated on our unit tests but we will activate for now on our CI. It's important to make sure that CI costs are not ballooning due to this however.

And to reiterate the main theme of this lesson:
Remember to make sure all operations finish before a test returns, otherwise we can end up with extremely hard to debug issues such as crashes or failures that happen during the execution of an unrelated test.

finished 02/24/2024 