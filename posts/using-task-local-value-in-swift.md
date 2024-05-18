+++
title = "Using Task Local Value in Swift"
description = "A quick look at how Task Local Values work in Swift"
tags = ["swift"]
tldr = true
date = 2024-05-18
+++

Task local values are a way to bind a value to an execution scope. This is similar to normal variable scoping rules, except instead of applying values to curly brace code blocks, it applies them to a branch of `Task`s in a structured concurrency hierarchy. The easiest way to explain it is with an example.

Let's say we want to build a tracing system for our logs, such that whenever an operation occurs, it is given a unique ID for that instance of the operation. Any time anything is logged for that operation, it is prefixed with that unique ID. This way if something goes wrong, we can trace only the logs that are produced by this operation using the trace ID.

Let's assume that our operation is defined like so.

```swift
let logger: Logger

final class Model {
    func doComplicatedWork() async {
        logger.trace("Begin complicated work")
        // Some work happens here
        // There would be more log traces throughout the complicated work
        logger.trace("End complicated work")
    }
}
```

To execute this operation we would do something like this.

```swift
// Created elsewhere
let model: Model

Task {
    await model.doComplicatedWork()
}
```

As it stands right now, if we are in a highly concurrent system, with many things happening (and logging) at the same time, it would be very difficult to isolate the log statements of our `doComplicatedWork` method. Especially if there are multiple instance of that method being invoked at the same time.

One solution is to generate a unique trace ID and pass it in as an argument to the method. Inside it can use that ID as a prefix whenever it generates any logs. While this would work, it polluted the input of our method with unnecessary debugging details about logging. The inputs and output of `doComplicatedWork` should only be concerned with the actual complicated work, not some external factors.

An alternative is to use Task Local Values. These are values that you bind to a scope of a particular `Task`. Let's explore how this would work.

First define a mutable static property somewhere, for example `Logger`. The property must be annotated with the `@TaskLocal` property wrapper.

```swift
extension Logger {
    @TaskLocal static var traceId: String?
}
```

This property will hold a trace ID for a single `Task`. The Swift Concurrency model does some magic behind the scenes that allows it to actually hold multiple values at once, depending on which context (`Task`) you access it from.

In our model, we must make sure to use this new property. It is as simple as just accessing it.

```swift
let logger: Logger

final class Model {
    func doComplicatedWork() async {
        logger.trace("\(Logger.traceId ?? ""): Begin complicated work")
        // Some work happens here
        // There would be more log traces throughout the complicated work
        logger.trace("\(Logger.traceId ?? ""): End complicated work")
    }
}
```

Lastly, for the magic sauce. Whenever we invoke our `doComplicatedWork` method, we must wrap it in a `withValue` call. This function is exposed on our new property when we access it with the `$` prefix.

```swift
Task {
    Logger.$traceId.withValue(UUID().uuidString) {
        await model.doComplicatedWork()
    }
}
```

With this change, each new execution of our task should print a trace with a unique trace ID. You can imagine that this can be quite helpful when executing this method several times, sometimes concurrently, especially in a server environment.

> Info: When working with property wrappers, the value that is returned with using the `$` prefix is called the *projected value*. Conversely when we access the property without the prefix, what's returned is called the *wrapped value*.
