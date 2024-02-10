0014_Speeding_up_Development_by_Reducing_Debugging_Time
Started 1/1/2024

- Re-evaluate usage of stub, highlight a downside of using stub
Currently we are stubbing a url with an error, but if the url in the implementation doesn't match the one we stubbed for the test, then our call won't be intercepted and we will actually hit the network. Also, we will need to debug the error in order to identify the url as the cause which is not ideal as it takes time. We want the test failure to be clear and explicit and understandable without debugging.

To fix this:
- remove the url based stubbing
- intercept all requests 
- add a specific test that checks the correct url was passed 

Point: we can override the `setUP` and `tearDown` method of `XCTestCase` which will be called before every test.

In our case here since we are calling static methods on our `URLProtocolStub` to start and stop request interception, we will call those methods in the setup and teardown of our `XCTestCase` instead of manually before and after every test.

Move the creation of the `URLSessionHTTPClient` to a helper factory method so that as we implement the client, if we ever have to change its api's ( to inject some dependencies for example) - we won't break our current tests for which those changes are irrelevant. 

Mike calls this a 'classic factory method' by which I suppose he means that unnecessary details are abstracted out away from the calling contexts where they're not needed?

Mike says here our factory method could theoretically return our `HTTPClient` since our implementation is technically supposed to implement that protocol. We do not yet have this conformance at the current stage though so we will make a mental note to have the `makeSUT` return `HTTPClient` as soon as we implement the protocol (ie: return an abstraction rather than a concrete type so we can protect our tests from implementation details)

We then extracted the memory leak test function to a new helper group / file since its now used in two different test classes. We didn't specify an access modifier on this function and so as a result, the default `internal` access is applied meaning that it is accessible within the module its defined in.

![[Pasted image 20240203121105.png]]







