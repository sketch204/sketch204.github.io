---
layout: post
title: From C to Swift - Part 2
description: Learn to how to integrate C system libraries into your Swift code
tags: swift swiftpm c
---

In [part 1]({% post_url 2023-07-15-from-c-to-swift-pt1 %}) of this series we looked at how we can integrate a C library with SwiftPM such that we can import it into our code. In this article, we will be taking a look at how to actually use the C code, and what the edge cases of using C code in Swift are. If you missed the first part, I highly recommend you give it a read.

## Using `ncurses`

First, most basic constants and functions that are defined in C, will be available in Swift as their global constant and function Swift counterparts. You can call them without any name-spacing from any context. For example, the `ncurses` library has a `getch` function which reads a characters from the input stream. It returns an `int` and takes no arguments. In my `main.swift`, after importing `Cnurses`, I can very easily call this function.

{% highlight swift %}
import Cncurses
let c = getch()
{% endhighlight %}

However, to make things clear for myself and help me keep my sanity, I try not to access the C library members directly as top-level members. Instead I prepend their module name to the member names. So given the above example, I prefer to make the call like so:

{% highlight swift %}
import Cncurses
let c = Cncurses.getch()
{% endhighlight %}

This makes it very explicit when I am working with C code.

{% include aside.html type="note" content="In part 1 we defined the main `Curses` target as a library. This means it cannot have top-level executable code. If you wish to test if some code compiles, you can declare a top level testing function, and place your executable code there. However if you wish to execute that code, the easiest way would be to either call it from a test, or write the code in the test directly. New SwiftPM packages are typically created with tests, so looks for a `Tests` folder." %}

### Structs

Most C structs will be interpreted by the Swift compiler and coerced into Swift structs. However they may be difficult to work with, so. I would still recommend wrapping them with a Swift type, if they are something you have to work with often. `ncurses` does not offer that many structs so I cannot provide an example for you.

### Pointers

C uses pointers a lot. This is what gives it most of its power. Swift however has no notion of a pointer, instead it has reference and value types. Luckily, the Swift compiler does a lot of the heavy lifting for us.

When you call a function that accepts a pointer, there are a number of ways you can pass your pointer to it.

If the pointer is constant, that is, it is only read and never changed, then you should be able to just pass in the value as usual and the swift compiler will implicitly cast it to the right type. However, for functions that also need to change the value of the pointer, you can use Swift's in-out syntax. When you pass the variable in, you prepend its name with `&`. Make sure the variable is mutable.

For example, `ncurses` has a function called `pair_content`, which given an int identifier, will return a pair of colors associated with said identifier. One for the text and one for the background. The C signature of this function is as follows.

{% highlight c %}
extern int pair_content(short, short*, short*);
{% endhighlight %}

Note the last two arguments, they are pointer types. In my case, the Swift compiler interpreted this declaration like so:

{% highlight swift %}
<!-- markdownlint-disable-next-line -->
public func pair_content(_: Int16, _: UnsafeMutablePointer<Int16>!, _: UnsafeMutablePointer<Int16>!) -> Int32
{% endhighlight %}

Notice that the two C `short` pointers were transformed into `UnsafeMutablePointer<Int16>`. The way to use these functions in Swift would be to simply pass two in-out references to it.

{% highlight swift %}
let id: CShort = 0
var textColor: CShort = 0, backgroundColor: CShort = 0
Cncurses.pair_content(id, &textColor, &backgroundColor)
{% endhighlight %}

We could wrap this in a Swift-friendly, re-usable function. That way we can hide all the C details, like so:

{% highlight swift %}
func getColors(for id: Int) -> (textColor: Int, backgroundColor: Int) {
    var rawForegroundColor: CShort = 0
    var rawBackgroundColor: CShort = 0
    Cncurses.pair_content(
        CShort(id),
        &rawForegroundColor,
        &rawBackgroundColor
    )
    return (
        Int(rawForegroundColor),
        Int(rawBackgroundColor)
    )
}
{% endhighlight %}

To make it even more Swift friendly, we would define an `enum` or `struct` to hold constants for all of the available colors, but I leave that as an exercise to the reader.

{% include aside.html type="info" content="Note the use of the `CShort` type. It is a `typealias` that maps to `Int16`. It is from a collection of types that map to C primitives. We could have used `Int16` directly, but I find this conveys my intent a little better. If you want to learn more, you can find a full list of mapped C types [here](https://developer.apple.com/documentation/swift/c-interoperability) (there's no header linking in Apple docs, so you'll have to scroll down a bit)." %}

### Strings

Strings in C are simple arrays of `char`s. With that in mind, the only real way to make that work with Swift is to mimic this behaviour. If a C function accepts or returns a string, the Swift compiler will simply coerce it to and from a Swift string.

Things get interesting when a C function return a string value, by assigning it a passed in pointer. In that case you must appropriate allocate some data, call the function passing it in, and then transform that data into a Swift string. There are a number of ways to accomplish this, but the most sane one I found is as follows.

{% highlight swift %}
// 1
var buffer = [CChar](repeating: 0, count: 80)
// 2
Cncurses.getstr(&buffer)
// 3
let str = String(cString: buffer)
{% endhighlight %}
Here we are calling the `getstr` string. This function will read a user input from the console, until it reads a newline feed. It will then take what it has read, and place it in the passed it pointer.

Now let's look at what is happening in the code.

1. We allocate some data for our string, by initializing a buffer. This is essentially an array of zeroes. The length of the array will determine how many characters will fit into the string, minus 1 for the end delimiter. Be mindful of this amount, because if you set it too low and the function tries to put in a bigger string, then you will get a crash. Notice also, that we are declaring an array of type `CChar`. This is to mimic the behaviour that we would do, if were we writing C code.
1. Next we call our function, passing in our buffer using in-out semantics. The function will set a value to the `buffer` array. I would also handle the status code that the function returns here, however we will talk about that in the next section.
1. Next I take my buffer and create a Swift string out of it, using the `init(cString: [CChar])` string initializer. This gives us a proper Swift `String`.

This looks cumbersome and annoying, but again, this is the most sane way I found to make this work. Believe me I've tried quite a few. Setting the maximum string length is quite annoying, but that is a side effect of using C.

If we were to wrap this in a Swifty function, I would do it like so.

{% highlight swift %}
public func getString(maxLength: Int = 80) -> String {
    var buffer = [CChar](repeating: 0, count: maxLength)
    Cncurses.getstr(&buffer)
    return String(cString: buffer)
}
{% endhighlight %}

This gives us the ability to override the max string length, if we anticipate a longer string, while also keeping a default of 80, which is common on a lot of other platforms.

{% include aside.html type="info" content="Apple has a [whole page](https://developer.apple.com/documentation/swift/calling-functions-with-pointer-parameters) dedicated to the implicit casting rules between Swift types and C pointer types. Be sure to check it out, if your work involves C pointers." %}

### Status Codes

It is common in C to pass values back to the caller through pointers, rather than simply returning them. This is usually done if more than one value needs to be returned, or if the function may throw an error. In those cases, often times what is actually returned by the functions is an `int` status code for whether the function executed successfully or not. You will need to check the documentation of your library to see what exactly constitutes a failure vs. a success. For `ncurses`, in case of a failure it will return the `ERR` constant, and something else in case of success. I was not able to find documentation for how to check the reason of failure, but I've seen other libraries provide various mechanisms for that. You'll have to refer to your library's documentation to see if they offer anything like that.

Rather than checking for the value of the status code every time you call the function in Swift, I would recommend declaring a throwing wrapper function. Let's continue our `getstr` function example from the previous section. First I declare an error type so I have something to `throw` in case of an error.

{% highlight swift %}
public enum CursesError: Error {
    case unknown
}
{% endhighlight %}

Next I modify my Swift `getString` function such that it throws an error if the status code of the C function is equal to `ERR`. I use the... in this case rather counter-intuitive, `guard` clause to perform the logic check.

{% highlight swift %}
public func getString(maxLength: Int = 80) throws -> String {
    var buffer = [CChar](repeating: 0, count: maxLength)
    let status = Cncurses.getstr(&buffer)
    guard status != Cncurses.ERR else {
        throw CursesError.unknown
    }
    return String(cString: buffer)
}
{% endhighlight %}

This is much better. Now I actually take the error into account, and provide a very Swifty way of handling it. The client can choose to ignore it if they are confident, but are otherwise forced to handle it.

If you're sure that the function you are calling will never fail, you can choose to ignore these error codes. However keep in mind that if it does fail, then you may get some unexpected behaviour and have a very difficult bug on your hands. Therefore I would recommend to still account for the error, but rather than throwing, perform a `fatalError`. This way, if the impossible error does occur, you'll at least be aware of it quickly.

### Pointers to `struct`

`ncurses` exposes a window object, that lets you isolate and work with a section of the terminal screen. This window object is represented as a C struct. When creating a window with `newwin`, you receive a pointer to this struct, and you must retain and pass around this pointer to various functions in order to manipulate the window. When you're done with it, you pass it to `delwin` to release its memory appropriately.

While you could manually create the pointer, hold a reference to it and pass it around, basically treating it as you would in C, I find this not very Swifty. Instead, I see this as a perfect use case to create a wrapper class. Classes are reference types so they have very similar semantics to pointers. Classes have a clear place of creation and destruction and they have an implicit `self` object that is passed as a hidden argument to all of their member functions. Releasing us from the burden of passing implicit data around. I hope you see how well this maps to our use case.

Let's begin. I will create a new class called `Window`.

{% highlight swift %}
import Cncurses

public final class Window {
    // More code to follow
}
{% endhighlight %}

It will have a single constant property called `windowPointer`. This will be the C pointer to the window struct. I will create this pointer in the initializer, exposing the window creation arguments. I will also make sure to properly destroy the window pointer once my class is de-allocated.

{% highlight swift %}
import Cncurses

public final class Window {
    private let windowPointer: OpaquePointer

    init(row: Int, column: Int, width: Int, height: Int) {
        self.windowPointer = Cncurses.newwin(
            numericCast(row),
            numericCast(column),
            numericCast(width),
            numericCast(height)
        )
    }

    deinit {
        Cncurses.delwin(windowPointer)
    }
}
{% endhighlight %}

{% include aside.html type="info" content="`numericCast` is a neat little [built-in Swift function](https://developer.apple.com/documentation/swift/numericcast(_:)), which will take in whatever numeric type you give it, and cast it to whatever numeric type is expected on the other end." %}

Now, with my wrapper class set up, I can start adding all of those window modifying functions as methods of the class. For example, this is how I would declare a `getCharacter` function. This function reads a single character the is passed to the input stream of my window and returns it.

{% highlight swift %}
extension Window {
    public func getCharacter() -> Int {
        let c = Cncurses.wgetch(windowPointer)
        return numericCast(c)
    }
}
{% endhighlight %}

Notice how the C pointer remains hidden the whole time. Instead I simply work with my class instance. The client of my class does not even need to know that there are C pointers being passed around behind the scenes. This is much more Swifty in my opinion.

### Constants

`ncurses` does not export any constant properties that I can show you as examples. At least not in the traditional sense. It defines most of its constants through the `#define` directive (If you are unfamiliar with C, [this article](https://www.freecodecamp.org/news/constants-in-c-explained-how-to-use-define-and-const-keyword/) explains what the `#define` directive does).

Preprocessor directives do not translate to Swift well. By default, if it is a macro that maps directly to literal values it will try to coerce it as a top-level constant. If it also accepts parameters it will be coerced into a function. However if the macro maps to another macro then it will not be translated to the Swift interface at all.

An example of one such macro is `A_UNDERLINE`. In `ncurses` you use this to make your output text underlined. It is a macro that does not accept parameters, but depends on the `NCURSES_BITS(mask, shift)` macro. If you try to access it in your Swift code you will get a compile-time error, saying it is not defined:

{% highlight swift %}
let underline = Cncurses.A_UNDERLINE
// Error: Module 'Cncurses' has no member named 'A_UNDERLINE'
{% endhighlight %}

The only way around this, that I found to work is to go back to my bridging header and declare a wrapper function that accesses the unavailable member.

In `bridging-header.h`
{% highlight c %}
<!-- markdownlint-disable-next-line -->
#include <ncurses.h>

int getUnderlineAttribute() {
    return A_UNDERLINE;
}
{% endhighlight %}

I would do this for any unavailable member that I need access to.

With that, back in my `main.swift` file I should be able to access the new wrapper function.
{% highlight swift %}
let underline = Cncurses.getUnderlineAttribute()
{% endhighlight %}

This works for most unavailable members.

{% include aside.html type="note" content="It irks me to put implementation in the header file, but with the current configuration, the modulemap seems to ignore any `.c` source files the I add to the module. I was not able to figure out how to make it work. If you know of a way, please [do let me know](mailto:hello@inal.dev)." %}

## Conclusion

While it is definitely possible to work with C directly from Swift, in many cases it is rather cumbersome. Therefore, if your library is rather small, like a handful of functions and symbols, then you may get away with just using it directly. However if it is a library that you will be using heavily, throughout your codebase, or a library that is big and/or opinionated, I would highly recommend creating a Swift wrapper around it. Handle all the C logic in one centralized place, and keep the rest of the code base Swifty.

## Sources

- [Calling Functions With Pointer Parameters \| Apple Developer Documentation](https://developer.apple.com/documentation/swift/calling-functions-with-pointer-parameters)
- [Building a text-based application using Swift and ncurses \| rderik](https://rderik.com/blog/building-a-text-based-application-using-swift-and-ncurses/)
- [rderik/SwiftCursesTerm \| GitHub](https://github.com/rderik/SwiftCursesTerm)
- [TheCoderMerlin/Curses \| GitHub](https://github.com/TheCoderMerlin/Curses/)
- [Xcode man pages \| keith.github.io](https://keith.github.io/xcode-man-pages/ncurses.3x.html)
- [NCURSES Programming HOWTO \| The Linux Documentation Project](https://tldp.org/HOWTO/NCURSES-Programming-HOWTO/index.html)
