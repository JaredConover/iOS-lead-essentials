
### 12 - Conforming to feature abstractions

9/30/2023

Coming back after a while, trying to remember what this project is

It really seems like its more efficient to keep a minimum speed with this as there is a lot of 'reboot' effort each time I start again
	12/2/2023 - um ya here we are again
  

A major theme seems to be handling dependency properly, reading the short SOLID whitepaper helped me grasp this

Dependency inversion is when you have elements depend on abstractions (I should read the paper again)

It seems, at least in this course, 'High Level' abstraction refers to the more abstract protocols ie: `FeedLoader` and 'Lower level' abstraction refers to the implementation such as the `RemoteFeedLoader`

12/9/2023 - finished episode 0012_Conforming_to_Feature_Abstractions

It seems like they implemented the remote feed loader before having it explicitly conform to the FeedLoader protocol - which I found weird.

