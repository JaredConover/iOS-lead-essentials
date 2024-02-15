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

Here is the table of possible cases:

![[Pasted image 20240203121105.png]]

A lot of these are invalid and should not technically occur, but since we are partly using a 3rd party framework, it can be worth it to cover some of these cases. For example, if we update the framework we can be confident that our implementation didn't break because we have added coverage with these tests.

Since our two error cases contained a similar algorithm of stubbing the response waiting for the completion and checking the result, we broke out this common procedure into a helper method for error cases that takes a value for data, urlresponse and error and returns a nullable error (if the request succeeds there will be no error).

We use this helper method to build all the invalid cases into one test using dummy values for data, response and error. We are essentially validating that a request matching these cases will complete with an error. This also ensures we wont get a crash? 

Finally, we create a test for the success case where we have data and and HTTPURLResponse. We added an else if after the error if in the implementation code that called the completion with the data and the response but still ended up with two failing tests:
1) In our success test, our assertion that the response objects were equal failed. This was likely due to the fact that since HTTPURLResponse is a class, the evaluation of equivalence was based on the pointer address and not the class instances stored values. To fix this for the moment we instead independently compare the response.url and response.statusCode. Question: would this not be a problem if we were dealing with a struct? Is this a hole/ flaw in the Apple testing framework?
2) One of our invalid test cases failed: data=nil, resp=HTTPURLResponse, error=nil. This was supposed to fail with an invalidRepresentation error but instead of receiving a nil data parameter in our implementation as we had stubbed the `URLProtocol` to do, the framework (URLSession? + URL loading system?) seems to have returned us a dataTask that instead contained an non-null value for data that contained 0 bytes. To fix this for now we are adding another condition to our implementations success to not only check if data is not nil but also if it is larger than 0 bytes. "Somehow the URLLoading System is replacing our nil data with an empty data of 0 bytes in the case where we returned a valid HTTPURLResponse"

So to recap roughly for this case: we added an interceptor to the URL loading system. We told it to return nil data when requested. This is basically like mocking a backend response of data: nil. However `URLSession` seems to have taken this nil data response and represented it as a non-nil empty data response (0 bytes). Essentially what we thought was an invalid case turns out to be a valid case because of how the `URLSession` API handles a valid response with nil data. So we will remove this test from the invalid scenarios and create an empty data scenario. Question: would this not also apply to the 'nonHttpresponse' data:nil case?

The commit message they use when correcting this however refers to the URL Loading System so I'm not sure which component is actually responsible for interpreting nil as empty:
[14] Delivers empty data and response on successful HTTP response with nil data since the URL Loading System completes the request with a non-nil empty data value (0 bytes) which is a valid case (eg: HTTP 204 no content response)





