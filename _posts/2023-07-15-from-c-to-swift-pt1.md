---
layout: post
title: From C to Swift - Part 1
description: Learn to how to integrate C system libraries into your Swift code
tags: swift swiftpm c
---

In this article I will walk you through the steps required to set up a C library as a SwiftPM package. This will allow you to use C code within a Swift project. I will then also show you how to use said C code from Swift, as well as how to make it more Swift-friendly.

Throughout this article I will be showing you various examples, using the [ncurses](https://en.wikipedia.org/wiki/Ncurses) library. This is a library that is used for more advanced cases of putting text on the terminal screen. I had the pleasure of playing around with it in one of my recent side projects. It should come pre-installed on most \*nix systems, including macOS (though not necessarily on iOS). If you wish to follow along with me using `ncurses`, I recommend building for macOS.

## Setup SwiftPM package

You can create the package through whatever means work best for you. One way to do it is through the `Swift Package` Xcode template, found in the `Multiplatform` tab, when creating a new project. Another way is to use the terminal to navigate to the directory where you want your package to be stored and running the command:

{% highlight shell %}
swift package init --type library
{% endhighlight %}

This will initialize a new SwiftPM package in the current working directory. It will name the package the same as the name of the current directory. In my case I initialized it in a `Curses` directory, so that will be the name of the package. It will be a library, so it can be imported into other packages.

Once the package is created, we can open it in Xcode for editing, by double clicking the `Package.swift` file or running `open Package.swift` in the terminal.

## Importing `ncurses`

Importing a C library consists of a number of steps.

1. Create a library source directory with a bridging header and a `modulemap` file.
1. Define a `systemLibrary` target in the SwiftPM manifest file.
1. Add the `systemLibrary` target as a dependency to the target where we wish to use the library.

After that you simply import the library and use it as you would.

### Create source directory

Let's get started, first we create a directory to hold the "sources" of our library. This directory can by anywhere really, but keep in mind that we will need to reference in the next step, relative to the `Package` file's location. I will put mine in the `Sources` directory. The library I am using is called `ncurses`. Swift conventions recommend you prepend a `C` to the names of C libraries to make it clear that they are not Swift libraries. Therefore I will call my directory `Cncurses`. You can call it something else if you wish, but take note of the name as we will reference it later.

Next we will create two files in this directory. The first is a bridging header. It will be a C header file. That is, a plain-text file ending with the `.h` extension. The name of the file doesn't really matter. I will call mine `bridging-header.h`, since it technically acts as a bridge between the C and Swift interfaces. In this bridging header we must import any C code that we wish to be a part of this Swift Package. These imports are done in C syntax and look as follows:

{% highlight c %}
<!-- markdownlint-disable-next-line -->
#include <libraryHeader>
{% endhighlight %}

You can import individual C files here if you wish, however for most libraries there will be what's called an "umbrella" header, which will import all the public headers that are part of the library. Most things that you import here will have the `.h` extension, same as our own header file.

In my case I am trying to import the `ncurses` library, so I will do it like so:

{% highlight c %}
<!-- markdownlint-disable-next-line -->
#include <ncurses.h>
{% endhighlight %}

{% capture info_box_1 %}
If you are unfamiliar with C there is one thing that is good to know. C and Swift work a little different in terms of how they share code between source files.

In swift we are used to having access to all the code that is within the same module. For code outside of our module, we can simply import the whole module and we get access to all public members. For example, if you are working on an app, all code that belongs to the app can freely reference each other (so long as it has an access level of `internal` of higher). However for code defined outside of our app, such as in the `UIKit`, `SwiftUI` and `Foundation` frameworks or some third-party library such as `Firebase` or `Realm`, we must first import those modules, before we can use their code.

C works a little different. Everything declared in a `.c` source code file is private by default. You make it public by also including forward declarations of its members in an accompanying header file. A forward declaration is similar to how a protocol declaration looks (though that's where the similarities end, C does not have objects or protocols). Other source code can then import whatever headers they need, to use code from other source code files. With this difference in mind it is easy to see that these two systems are not really compatible out of the box.

This is why we must use a bridging header to **bridge** the gap between the two systems. We define one or more headers that import all the code that our Swift module needs to use. Swift will then treat that bridging header as one module, that you can import. If you have a mixed Swift/Objective-C codebase, you will have a bridging header generated for you by Xcode that performs the same function. That bridging header will imported implicitly. In our case we will need to import it manually.
{% endcapture %}

{% include aside.html type="info" content=info_box_1 %}

Next, we define a `modulemap` file.

Create a new file called `module.modulemap`. This file is responsible for telling SwiftPM what your package consists of. The file name is important. Place the following inside of the file.

{% highlight modulemap %}
module SwiftLibraryName {
    header "bridgingHeaderName"
    link "CLibraryName"
    export *
}
{% endhighlight %}

Make sure to replace the following:

- Replace `SwiftLibraryName` with the Swift facing name for your library. Remember that Swift conventions recommend C library names to be prepended with a "C". In my case I will name the library `Cncurses`.
- Replace `bridgingHeaderName` with the file name that you used for the bridging header, including the file extension. In my case that is `bridging-header.h`.
- Replace `CLibraryName` with the name of the library, as it appears in C, typically that will be the name of the umbrella header without the `.h` extension. In my case that is `ncurses`.

After the replacements my `modulemap` file looks something like this:

{% highlight modulemap %}
module Cncurses {
    header "bridging-header.h"
    link "ncurses"
    export *
}
{% endhighlight %}

We've defined what our system library must look like. Now we must make it visible to SwiftPM.

### Define SwiftPM `systemLibrary` target

Open the `Package.swift` file. We will be adding a system library target here. This can be done with the `.systemLibrary(...)` static initializer. This initializer can take a number of arguments, but we will only be use two: `name` and `path`. For the `name` argument, make sure that it matches the `SwiftLibraryName` name that you used in your `modulemap` file. The `path` argument specifies a path to the folder that contains your source code, in our case the bridging header and the module map file. This path is relative to the location of the `Package.swift` file. You may be able to omit the `path` argument and have SwiftPM automatically resolve it, but I find specifying it manually works a little better.

With all of that in mind, my target definition will look like `.systemLibrary(name: "Cncurses", path: "Sources/Cncurses")`. We can now insert this definition in the `targets` array of the package definition. This is what my `Package.swift` file looks like, after the additions (unrelated code removed for brevity).

{% highlight swift %}
let package = Package(
    name: "Curses",
    products: [...],
    targets: [
        .target(name: "Curses"),
        // New target
        .systemLibrary(name: "Cncurses", path: "Sources/Cncurses"),
    ]
)
{% endhighlight %}

If you are using Xcode, save the file and it will attempt to resolve the packages.

All the names here look confusing, so let me just clear it up a little. `Cncurses` is the name of my raw C library that I am exposing to Swift code through a SwiftPM package. `Curses` is the name of my Swift package that will internally be using `Cncurses` (the raw C library).

The next and last step is to add it as a dependency to some other target where we wish to use the library. In my case I only want to use it in the main `Curses` target so I will modify my `Package.swift` file to add a `Cncurses` dependency on the `Curses` target:

{% highlight swift %}
let package = Package(
    name: "Curses",
    products: [...],
    targets: [
    .target(name: "Curses", dependencies: ["Cncurses"]),  // Add dependency here
        .systemLibrary(name: "Cncurses", path: "Sources/Cncurses"),
    ]
)
{% endhighlight %}

With all that in place, I can now use the C library in the main `Curses` target. I can test this by simply importing the library and checking that the target compiles successfully.

In `main.swift`

{% highlight swift %}
import Cncurses
{% endhighlight %}

If you are using Xcode, try to build the project and see if that succeeds. If you are using the terminal to build the project, you can use `swift build`. Your output should look similar to this:

{% highlight shell %}
 % swift build
Building for debugging...
[2/2] Compiling Curses Curses.swift
Build complete! (1.55s)
 %
{% endhighlight %}

Now the C library is imported and you can use all of its compatible member. This is the end of part 1. In [part 2]({% post_url 2023-07-15-from-c-to-swift-pt2 %}), we will go through what using this library is actually like, as well as some tips on how to wrap the C API behind a more Swift-friendly interface.

## Sources

- [Making a C library available in Swift using the Swift Package Manager \| rderik](https://rderik.com/blog/making-a-c-library-available-in-swift-using-the-swift-package/)
- [Building a text-based application using Swift and ncurses \| rderik](https://rderik.com/blog/building-a-text-based-application-using-swift-and-ncurses/)
- [rderik/SwiftCursesTerm \| GitHub](https://github.com/rderik/SwiftCursesTerm)
- [TheCoderMerlin/Curses \| GitHub](https://github.com/TheCoderMerlin/Curses/)
