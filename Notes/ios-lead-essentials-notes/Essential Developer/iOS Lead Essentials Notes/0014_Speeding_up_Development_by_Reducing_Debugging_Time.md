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

