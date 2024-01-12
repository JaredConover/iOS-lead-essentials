12/10/2023 - starting 0013_Four_Approaches_to_Test_Drive_Network_Requests_End_to_End_Subclass
we were rudely interrupted by Carol and lost focus.

12/25/2023 - #13
Here they say "test driving" approaches as it seems like they are implementing and testing at the same time

What are the 4 approaches?
1) End-to-end tests
	- Actually hitting the network: executing the HTTP request, going to the backend, getting the response back and then asserting that we got the right response.
	- Problems: 
		- We might not actually have a backend and we don't want to be blocked.
		- They can be flaky as they are hitting the network and requests often fail for reasons that aren't pertinent to what we actually want to test.
		- Means we need a network connection to run the test.
		- In this current scenario we are working at the component level (Feed API module). E2E tests are more beneficial when we can test multiple components in integration.
 2) Subclass-based mocking
	 - We are subclassing the API being used and overriding certain methods in order to spy on its behaviour. 
	 - Problems: 
		 - This can be dangerous as we don't own the classes we are subclassing and often don't have access to their implementations. 
		 - If we mock classes we don't own, we can start making assumptions in our mocked behaviour that could be wrong. 
		 - The classes we mock may have many methods that interact in ways we don't fully grasp and we may not be able to override all the necessary methods.
3) Protocol-based mocking
	- We use a protocol to mock only the parts of the api we are testing
	- Problems: 
		- We end up re-declaring the signatures of the API we need solely for the purposes of testing. This is not fully agnostic and unnecessarily  duplicates code solely for tests.
1) `URLProtocol` stubbing
	- Subclass `URLProtocol`, part of the `URL Loading System` in order to intercept the `URLRequest` and return a stubbed response.
	- Implementation agnostic. The request is essentially what becomes the interface 
	- The tests are decoupled from the implementation
		- The specific mechanism being used to load the URLs can change without breaking the tests. 
	- Production implementation is agnostic of testing. (in contrast to Protocol-based mocking and others)

This episode is about developing / testing an implementation of the HTTPClient protocol
Our current architecture for the `Feed API` module looks like this:
![[Pasted image 20231225141236.png]]

Our`RemoteFeedLoader` implementation of the `<FeedLoader>` protocol in the `<Feed Feature>` module (is it a module?) :
- requests the data from the `<HTTPClient>` protocol  
- 'Uses' the `FeedItemsMapper` to map the response from the `<HTTPClient>`

As it stands, we have no implementation of the `<HTTPClient>`
The implementation of the `<HTTPClient>` would be responsible for communicating with the network/backend

Since we are not using any third party libraries we will use [URLSession](https://developer.apple.com/documentation/foundation/urlsession)
> An object that coordinates a group of related, network data transfer tasks

`URLSession` is a class in the Foundation framework of iOS that provides an API for performing networking operations such as fetching data from a URL or uploading data to a server. It supports various tasks, including data tasks for fetching data, upload tasks for uploading data, and download tasks for downloading files in the background.

This is the "highest level API" which I suppose means the most abstracted as in we should not have to deal with implementation specific details which will be good if we want to swap it out for a different API.
 
For the `<HTTPClient>` all we need is to implement the get from url function with a completion block that will receive either success with the data and an `HTTPURLResponse` or failure with an `<Error>`
There are different ways of testing or 'test driving this'. This approach of 'test driving' the development does feel backwards to me as we are building the tests before the production code. For example, we start writing a test class with functions testing the behaviours we want and the final step is implementing the production functionality on top of the test. This is contrary to the way that I would approach solving dev problems which is: start building, run into unforseen hurdles, adapt a working solution, and then maybe add some test coverage at the end.
E2E is a valid solution but there are more reliable solutions in this case

12/26/2023 - 13 - 4:21
#### Subclass-based mocking
Here we are subclassing URLSession in order to spy on its behaviour. We override `URLSession.dataTask(withUrl: URL, completionHandler: {}) -> URLSessionDataTask` so that we can evaluate whether the task contains the proper url based on how we invoked it and we also subclass the `URLSessionDataTask` in order to override its `resume` method so that we can validate whether the task was resumed the correct number of times when our `<HTTPClient>` implementation calls its get method with a url.

commit 98c3b8199ca3695616876c93ace411493b5dd814
    [13] Creates URLSession data task with URL on `URLSessionHTTPClient.get(from: URL)`

commit 19b0f91ab90ec94f5f2175e32b2c6c8203a4ec49 
    [13] Resumes data task on creation (subclass mocking)

The problem with this thats apparent is that our tests are coupled tightly to the implementation details of the URLSession class. This is because we need to override specific functions to perform our validations.
Ideally the implementation (of our get(from:URL)) should be private and we should just test the behaviour.
In this mocking strategy, we end up having to test exactly which API is being called, at which time, with exactly which parameters during every interaction. 
Currently this is what we need but it has the effect that the tests are coupled with production code so every time we refactor we will break the test.

If possible it would be much better to check the behaviour of loading the urls and the completions in a more implementation agnostic way.

#### Protocol-based mocking
Here we copy the exact api and put it in a protocol. So since we are only using `URLSession`'s `dataTask(for: URL, completion)` method, we create a protocol that declares this signature. This protocol that we call `HTTPSession` exists in our production code. In our test class we create an `HTTPSessionSpy` class that implements our protocol to mock the behaviour.

Our implementation, `HTTPSessionSpy` enables us to mock the interaction with a backend by associating urls with expected results; a dataTask (also mocked through protocol) or an `Error` while setting up the test. 

The improvement here over subclass-based mocking is that we are no longer dealing directly with all the details of the `URLSession` implementation. One downside is that we are duplicating the `dataTask(for: Url, completion)` signature in the production codebase: extra protocols that match the exact same interface. These new types are introduced solely for the purposes of testing.

#### `URLProtocol` stubbing
Intercepting the network call we are interested in at the system level so we can then stub its behaviour.
##### Background
Every time we perform a `URLRequest`, behind the scenes it's handled by the `URL Loading System`. This system contains the `URLProtocol` abstract class which we can subclass in order to intercept URL requests.

![[Pasted image 20240101112247.png]]

In our specific scenario, we can create a subclass of `URLProtocol` that implements our stub behaviour. This allows us to intercept `URLRequests` during tests and finish them with stubbed requests so we never end up actually hitting the network (which is faster, more reliable). This hides the details from the production code. The test code becomes implementation agnostic, it will not know if we are using `URLSession` or another mechanism for fetching URLs.

Finished 1/1/2024