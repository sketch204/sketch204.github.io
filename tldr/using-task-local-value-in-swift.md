+++
title = "[TLDR] Using Task Local Value in Swift"
description = "A quick look at how Task Local Values work in Swift"
date = 2024-05-18
tags = ["swift"]
+++
- Declare a mutable static property on a type. Annotate the property with the `@TaskLocal` property wrapper
- Inside of a task, set the property by accessing its `projectedValue` and calling the `withValue` method. All code and subtasks created within the closure will have the value of the static property set to whatever was passed as the first argument of the `withValue` method.

```Swift
extension Logger {
    @TaskLocal static var traceId: String?
}

let trace1 = "Trace1"
let trace2 = "Trace2"

print(trace1)
// Trace1
print(trace2)
// Trace2
print("Outside of tasks: \(Logger.traceId)")
// nil

Task {
    await Logger.$traceId.withValue(trace1) {
        print("\(Logger.traceId ?? ""): Doing some work for user with ID")
        // Trace1: Doing some work for user with ID
        try? await Task.sleep(for: .seconds(1))
        print("\(Logger.traceId ?? ""): Finished some work for user with ID")
        // Trace1: Finished some work for user with ID
    }
}

Task {
    await Logger.$traceId.withValue(trace2) {
        print("\(Logger.traceId ?? ""): Doing some work for user with ID")
        // Trace2: Doing some work for user with ID
        try? await Task.sleep(for: .seconds(2))
        print("\(Logger.traceId ?? ""): Finished some work for user with ID")
        // Trace2: Finished some work for user with ID
    }
}
```
