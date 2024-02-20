started 02/16/2024

The first things done is this episode are changes to a few settings in the project:
- The first is to enable randomization of execution order of the tests to ensure that there is not some hidden sequential dependency. We want our tests to run perfectly in isolation as well as in a group. If one test fails, all the reasons for its failure should be contained within its own scope / method definition. It's possible to have scenarios where either tests fail in isolation but pass integration, or the opposite. We want to avoid this kind of flaky test suite condition and randomizing the execution helps with this.
- It was also discussed whether to activate the parallelization option but since we don't have performance issues with our tests at the moment, this is not necessary.
- We enable gathering the code coverage option for our essential feed target. When we run our tests this returns 100%. It is important to note that this metric simply reports which lines of our production code were executed while running the tests. It does not mean we have covered all possible scenarios and behaviours. So this means that 100% of our lines were executed while running our tests. So code coverage is not the goal, it's a side effect of TDD. Coverage will typically be 100% with TDD as we are enumerating our cases ans creating assertions for them first before writing the production code. The true goal of TDD is to have confidence that we have tested the important behaviours and that we are free to change our code. This means we will be agile and able to adapt to change and prevent bugs. 

The implementation of the Feed API Module is now finished:
![[Pasted image 20240216121234.png]]
Next, we are going to create some end to end tests to test the Feed API Module in integration with a backend. Essentially we would test all the API module components together with the backend to see if they work correctly if both sides are conforming to their agreed contract.

But the BE is probably not ready in this scenario so there are a few proposed options:
- Have BE setup a test endpoint that sends a static payload that represents what we should expect when the real api is ready.
- If they don't have time to do this we could build one ourselves.
- Otherwise we could also create a test account on an existing BE with pre-populated data. Ideally this account would not be shared/used by other platforms ie android, in order to not interfere with our test expectations.

We create a new test target for our e2e tests as to not slow down the execution of our existing test target. This also adds a new scheme to run the e2e tests in isolation. This is important since our new test takes about 3 seconds to execute as compared to our other unit tests that take 0.7 seconds. We don't want to be slowed down every time by running e2e if thats not what we want to validate.

We setup a type of integration test that will call a real endpoint that returns a fixed collection of data. Our test is built on the assumption that this fixed data will not change and if it does our test will be invalidated. In our test code we are initializing the remote feed loader components: the FeedLoader with the UrlSessionClient and then calling load to capture the result. We then evaluate this received result against items that we have hardcoded to match what our fixed endpoint should be returning us.

Instead of looping over the result items, we assert their equality to our expectation each on a separate line. This is because it will be clearer to see exactly where something failed and we currently have a small, fixed number of items to evaluate. If we had a large or unknown number of items to evaluate, we could add the failed index, etc in a loop over the items in order to have more context.

APPLICATION: I can see this strategy of using a BE endpoint to test several components could be useful while not requiring all the overhead of an XCUITest. In the case of Poka however, instead of being a fully fixed backend endpoint, the data could remain fixed but the server logic could update as BE deploys new versions enabling us to catch errors faster. I should find a way to set up some smoke tests like this. 

When do we want to run these e2e tests? Unlike the unit tests (while following TDD), we don't want to run them while we're developing because they take too long and we don't want to lose our flow. For these, it makes sense to run them as part of a CI process so that we test our changes before every merge to master. 

We add a new CI scheme that runs both our test schemes. We also setup a pipeline using Travis which allows us to run our CIs test plan every time we push to git. 
- we create a `.travivs.yml` file at the root of the project using the `touch` command
- configure the file with the os, language, xcode version 
- define the command to be executed:
	- `xcodebuild clean build test -project EssentialFeed.xcodeproj -scheme "CI" CODE_SIGN_IDENTITY="" CODE_SIGNINING_REQUIRED=NO`
It seems that github must pickup on this config and run the specified commands when we merge to main?

So now every time we merge code to main, these tests will be executed, protecting the integrity of our project.

Finished 02/18/2024