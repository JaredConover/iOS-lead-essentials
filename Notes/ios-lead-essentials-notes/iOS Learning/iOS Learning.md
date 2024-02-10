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


#### Access modifiers
If you don't specify any access modifier for a function, Swift assigns it the default access level, which is internal. Internal access means that entities are accessible within the same module but not from outside. So, if you don't specify any access modifier, the function will be accessible only within the same module.

Here's a summary of access levels in Swift:

1. **Private**: Limits the use of an entity to the enclosing declaration.
2. **File-private**: Limits the use of an entity to its defining source file.
3. **Internal**: Makes an entity accessible within the same module, but not outside of it. This is the default level if you don't specify any access modifier.
4. **Public**: Allows an entity to be used within any source file from its defining module and also in a different module that imports the defining module.
5. **Open**: Similar to `public`, but it also allows other modules to subclass and override the functionality.

So, if you want a function to be accessible from outside the module, you would need to specify either `public` or `open` access level explicitly.

#### Modules
In Swift, a module is essentially a single unit of code distribution. It can be a framework or an application. A module is defined by its boundaries, which are typically established by the project structure and organization of source files.

Here are some key points regarding what defines a module and its boundaries in Swift:

1. **Framework or Application**: A module can be either a framework (a reusable bundle of code and resources) or an application (an executable program).
    
2. **Compilation Unit**: In Swift, each source file is treated as a separate compilation unit. All declarations (such as classes, structs, enums, functions, etc.) within a source file are part of the same module.
    
3. **Module Declaration**: The `import` keyword is used to declare dependencies between modules. When you import a module, you make its functionality available to your code. Swift's module system helps in managing dependencies and organizing code into separate units of functionality.
    
4. **Access Control**: Access control in Swift (using keywords like `private`, `fileprivate`, `internal`, `public`, and `open`) allows you to define the boundaries within which entities are accessible. This helps in defining the interface of a module and controlling what parts of it are visible to other modules.
    
5. **Target Membership**: In Xcode, modules are often defined by target membership. Each target (such as a framework target or an application target) represents a separate module. Code and resources included in a target belong to that module.
    
6. **Namespaces**: Swift uses namespaces to prevent naming conflicts between modules. Each module has its own namespace, so entities within a module can be uniquely identified by their names.
    
7. **Bundle Identifier**: In the context of iOS/macOS applications, a module's boundaries can also be defined by its bundle identifier. Each app or framework has a unique bundle identifier, which helps in identifying and distinguishing it from other modules.
    

Overall, a module in Swift is defined by the collection of source files, dependencies, access control, and other factors that collectively represent a unit of code distribution and organization.