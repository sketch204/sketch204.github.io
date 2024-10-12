+++
title = "Using Regex in Swift"
description = "An in-depth look at the various different ways to define and use regular expressions in Swift"
excerpt = "In this article I will be walking you through the various different ways to define and use regular expressions in Swift"
tags = ["Swift"]
tldr = true
date = 2023-12-02
updatedDate = 2024-10-12
+++

In this article I will be walking you through the various different ways to define and use regular expressions in Swift.

Throughout this article I will be using the following string as the sample text we are trying to parse with Regex. It is an example of a basic CSV table that one might encounter in their day-to-day work. I stole this example text from [here](https://github.com/apple/swift-evolution/blob/main/proposals/0350-regex-type-overview.md) because it's a very good example that shows the flexibility of Regex in Swift.

```swift
let input = """
CREDIT    03/02/2022    Payroll                   $200.23
CREDIT    03/03/2022    Sanctioned Individual A   $2,000,000.00
DEBIT     03/03/2022    Totally Legit Shell Corp  $2,000,000.00
DEBIT     03/05/2022    Beanie Babies Forever     $57.33
"""
```

Let's get started.

## `NSRegularExpression`

If your project is targeting platforms before iOS 16, then you'll have no choice but to use Foundation's Regex APIs. These are available since iOS 4.0 and were originally made for Objective-C. As a result they're a little tedious to use in Swift.

If we wanted to define a regex pattern to grab the value of first column in the table, we would do it like so.

```swift
let regex = try NSRegularExpression(pattern: "(CREDIT|DEBIT)\\s+")
```

This gives us an `NSRegularExpression` object. We have to `try` the initializer because if the string that we pass in happens to be invalid Regex it will throw an error.

Notice the double back slash in `\\s+`. We can avoid having to escape the backslash by using [extended string delimiters](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/stringsandcharacters/#Extended-String-Delimiters). A special feature in swift that allows us to use a more specific string delimiter rather than just double quotes. With this, our regex pattern looks as follows:

```swift
let regex = try NSRegularExpression(pattern: #"(CREDIT|DEBIT)\s+"#)
```

To actually use the regex on our string, we have to call methods on the `regex` object such as `firstMatch(in:options:range:)`, `matches(in:options:range:)` or `enumerateMatches(in:options:range:using:)`. For example

```swift
regex.enumerateMatches(
  in: input,
  range: NSRange(location: 0, length: input.count)
) { result, flags, stopPointer in
  // Do something with result

  // Stop early if needed
  let shouldStop = false
  if shouldStop {
    stopPointer.pointee = false
  }
}
```

This API is a little bulky and dated in my opinion. I wont spend much more time exploring it. If you want to find out more, [check out the docs](https://developer.apple.com/documentation/foundation/nsregularexpression).

## `Regex`

Starting with iOS 16.0 Swift has a new `Regex` type as part of its standard library. You can use this type much like you used the `NSRegularExpression` type above to define a regex pattern with a string literal.

```swift
let regex = try Regex(#"(CREDIT|DEBIT)\s+"#)
```

The usage of our regex type is a little different. The `Regex` object exposes a few method that you can use to parse a string, however the bulk of the API is defined on `String`. If we want to get the first match on our input string, we would do it like so.

```swift
let match = input.firstMatch(of: regex)
```

This returns a `Regex.Match` object that we can use to query the output of our regex pattern. You can then use `match.output` to get the output of the regex.

So far this is not much different than what we had before. We still have to provide a string literal, and we still have to `try` the initializer, as it might fail if the regex is invalid. However this new API has some hidden improvements that we haven't made use of yet.

### Output types

`Regex` is generic over it's output type. What this means, is that when we define capture groups in our regex, we can actually specify them on the `Regex` as the output of the object. To do this, you provide an extra `as:` argument to the initializer, where you specify a tuple type of what you're expecting. Most of the time this will be a tuple of two or more `Substring`s.

```swift
let regex = try Regex(#"(CREDIT|DEBIT)\s+"#, as: (Substring, Substring).self)
```

Notice that I specified a tuple of two `Substring`s even though I only have one capture group. That is because the first captured of the regex is always the whole string that was matched. Which is then followed by all of the explicit capture groups.

If I wanted to also capture the first number of the date in the following column, I would use a regex like this

```swift
let regex = try Regex(#"(CREDIT|DEBIT)\s+(\d+)"#, as: (Substring, Substring, Substring).self)
```

Do get that number out of the match, I would simply access the tuple element on the match object like so.

```swift
let match = input.firstMatch(of: regex)
let month = match?.2  // "03"
```

The type of `month` will be `Substring?`. I can similarly get the first column by accessing `match?.1`, or the whole matched string with `match?.0`.

If I wanted to get a list of all the values in the first column I could do something like ths

```swift
let transactionTypes = input.matches(of: regex).map(\.1)  // ["CREDIT", "CREDIT", "DEBIT", "DEBIT"]
```

Hopefully you can see how this is an improvement over Foundation's `NSRegularExpression`, however it doesn't stop there.

## Regex Literals

With [SE-0354](https://github.com/apple/swift-evolution/blob/main/proposals/0354-regex-literals.md) the Swift team introduced a new syntax for defining regex patterns called Regex Literals. Let's take a look at it in this section.

If I wanted to define the exact same pattern that we had in the previous example, using regex literals it would look as follows

```swift
let regex = /(CREDIT|DEBIT)\s+(\d+)/
```

As you can see, it is literally the raw regex pattern surrounded by forward slashes (`/`). One benefit of defining a regex patterns this way rather than creating the raw `Regex` type is that these literals are checked at compile time. This means if you make an error, you will see it right away, so you don't need any `try`s. It also means that the Swift compiler can analyze your pattern and figure out the correct return type for the regex.

If we look at the type of `regex` with `print(type(of: regex))` we would see `Regex<(Substring, Substring, Substring)>`. As you can see, the compiler was able to automatically determine the type of the pattern, without us having to specify it manually. You can also see that the type that regex literals create is still a `Regex`, so its usage is exactly the same as in the previous example.

### Extended Literal Delimiters

There is one gotcha that I should mention, and that is the fact that forward slashes must be escaped when using regex literals. Let me show you what I mean. Below is a sample of what a row in our data looks like, in case you forgot.

```
CREDIT    03/02/2022    Payroll                   $200.23
```

If we wanted to grab the entire date from the second column, the regex pattern for that would look like so

```swift
let regex = /(CREDIT|DEBIT)\s+(\d+)/(\d+)/(\d+)/
```

However this would not work. Notice the forward slashes in `(\d+)/(\d+)/(\d+)`. Because regex literal are delimited by forward slashes, the compiler is likely to be yelling all kinds of errors at you right now. To make this work, we have to escape the forward slashes (`/`) with backslashes (`\`). So our escaped regex looks like this

```swift
let regex = /(CREDIT|DEBIT)\s+(\d+)\/(\d+)\/(\d+)/
```

This is a little difficult to work with in my opinion. Which is why the Swift team decided to enable the same kind of extended delimiters that they made for string literals, but for regex literals. So to avoid the backslash escaping we can do

```swift
let regex = #/(CREDIT|DEBIT)\s+(\d+)/(\d+)/(\d+)/#
```

One hidden feature of using these regex delimiters is that all whitespace and newlines in the regex are ignored. This means that you can break it up across multiple lines to make it more readable. Not only that but you can actually leave comments within your regex with by starting it with `#`.

```swift
let regex = #/
  (CREDIT|DEBIT)     # transaction type
  \s+
  (\d+)/(\d+)/(\d+)  # date
/#
```

I find this to be way more readable than the string regex patterns that we were using before.

Of course as mentioned before, this produces a `Regex` type, so usage is the same as before.

```swift
let match = input.firstMatch(of: regex)
let month = match?.2  // "03"
```

### Named Capture Groups

Notice how we have to use numbers to refer to our capture groups. Another benefit of using regex literals is allowing you to name the capture groups. This is done by adding a `?` after the opening parenthesis and providing the name between angle brackets right after that.

```swift
let regex = #/
  (?<transactionType> CREDIT|DEBIT)          # transaction type
  \s+
  (?<month> \d+)/(?<day> \d+)/(?<year> \d+)  # date
/#
```

Now, when we access the capture groups we can use the names we specify in the regex, rather than the number of their position.

```swift
let match = input.firstMatch(of: regex)
let day = match?.day      // "02"
let month = match?.month  // "03"
let year = match?.year    // "2022"
```

This is definitely an improvement over what Foundation offered. But wait, there's more!

## `RegexBuilder`

Along with regex literals, the Swift team introduced the [`RegexBuilder`](https://developer.apple.com/documentation/regexbuilder) framework. This is a framework that let's us define regex patterns using Swift's result builder syntax, similar to how we define views in SwiftUI.

Let's define the same pattern we were working with, using `RegexBuilder` this time.

First we import the framework.

```swift
import RegexBuilder
```

Next we start a pattern definition. We will define our pattern within the curly braces.

```swift
let regex = Regex {

}
```

Let's look at the first part of the regex.

```plaintext
(CREDIT|DEBIT)
```

This says, look for **either** the whole string **`CREDIT`** or the whole string **`DEBIT`** and then **capture** that. To achieve the same thing with `RegexBuilder`, we quite literally just say what we want.

```swift
let regex = Regex {
  Capture {
    ChoiceOf {
      "CREDIT"
      "DEBIT"
    }
  }
}
```

Notice how much more descriptive this approach is. Rather than using the cryptic regex syntax, we just use normal english words to describe what we're trying to do. When you're coming back six months from now, you won't need to pull out a regex handbook to understand what you're trying to do here.

In fact I bet that you can understand the rest of the pattern without me explaining much of it.

```swift
let regex = Regex {
  // Transaction type
  Capture {
    ChoiceOf {
      "CREDIT"
      "DEBIT"
    }
  }

  OneOrMore {
    CharacterClass.whitespace
  }

  // Date
  Capture {
    OneOrMore {
      CharacterClass.digit
    }
  }
  "/"
  Capture {
    OneOrMore {
      CharacterClass.digit
    }
  }
  "/"
  Capture {
    OneOrMore {
      CharacterClass.digit
    }
  }
}
```

There are a few things to notice here. First, since this is just plain Swift code, we can leave inline comments, like we would anywhere else.

Second, we use common constructs like `Capture`, `OneOrMore` and `ChoiceOf`, that if you're familiar with you know right away what they do, and if not, then it's easy to guess based on the name. It's intuitive.

Third, since this is using Swift's result builders, we can compose different regex patterns together, similar to how you'd extract repetitive View code in SwiftUI.

```swift
let digitCapture = Regex {
  Capture {
    OneOrMore {
      CharacterClass.digit
    }
  }
}

let regex = Regex {
  // Transaction type
  Capture {
    ChoiceOf {
      "CREDIT"
      "DEBIT"
    }
  }

  OneOrMore {
    CharacterClass.whitespace
  }

  // Date
  digitCapture
  "/"
  digitCapture
  "/"
  digitCapture
}
```

In terms of usage this is a still that same `Regex` type. So we use `regex` in exactly the same way as we did before. Except since we haven't named our captures yet, we must use the tuple indices.

```swift
let match = input.firstMatch(of: regex)
let month = match?.2  // "03"
```

The string API exposes an additional set of methods that allow us to pass in regex builders directly. This is particularly useful when your regex is short.

```swift
let match = input.firstMatch {
  Capture {
    ChoiceOf {
      "CREDIT"
      "DEBIT"
    }
  }
}
let transactionType = match?.1
```

### Naming Capture Groups

When it comes to naming capture groups, this works a little different from the other examples. First, we must define a `Reference` that will act as the gluing component between defining the capture group, and actually getting the values out.

Let's define a reference for the transaction type group.

```swift
let transactionTypeRef = Reference(Substring.self)
```

When defining a reference, you must specify what kind of data it is capturing. For most purposes this will be `Substring`, however there is a way to use a custom type. More on that later.

We then use the reference in our regex to associate a particular `Capture` with this reference. We do this by supplying the reference as an argument to the `Capture` expression.

```swift
Capture(as: transactionTypeRef) {
  ChoiceOf {
    "CREDIT"
    "DEBIT"
  }
}
```

If we try to access the transaction type from a match using the tuple index, it will not work. Neither will `match.transactionType`. Unfortunately that is not possible. Instead, we have to access data on the match object as if it's a dictionary.

```swift
let match = input.firstMatch(of: regex)
let transactionType = match?[transactionTypeRef]  // "CREDIT"
```

This returns an optional `Substring`, just like the output type of our `transactionTypeRef`.

We can repeat this process for the date fields, turning the extrapolated `digitCapture` property into a function. Here's what that would look like.

```swift
let transactionTypeRef = Reference(Substring.self)
let dayRef = Reference(Substring.self)
let monthRef = Reference(Substring.self)
let yearRef = Reference(Substring.self)

func digitCapture(as ref: Reference<Substring>) -> some RegexComponent {
  Capture(as: ref) {
    OneOrMore {
      CharacterClass.digit
    }
  }
}

let regex = Regex {
  Capture(as: transactionTypeRef) {
    ChoiceOf {
      "CREDIT"
      "DEBIT"
    }
  }
  OneOrMore {
    CharacterClass.whitespace
  }
  digitCapture(as: monthRef)
  "/"
  digitCapture(as: dayRef)
  "/"
  digitCapture(as: yearRef)
}
```

Notice here that we specified a return type of `some RegexComponent` for the `digitCapture` function. This again is very similar to how SwiftUI works, where we specify a return type of `some View` for custom views. We could of course use a concrete `Regex` type, but then we would need to figure out a concrete return type from our builder expression anytime the pattern changes, and unfortunately it's not as simple as `Regex<(Substring, Substring)>`.

Notice also that we didn't need to wrap our digit capture pattern in a `Regex { ... }` block. That is because `Capture` along with most other Regex Builder blocks all conform to `RegexComponent`. This can save you some code when composing regex patterns together.

With this code in place, we should be able to read all the captured fields in the regex.

```swift
let match = input.firstMatch(of: regex)
let transactionType = match?[transactionTypeRef]  // "CREDIT"
let day = match?[dayRef]                          // "02"
let month = match?[monthRef]                      // "03"
let year = match?[yearRef]                        // "2022"
```

### Capturing Custom Types

The last thing that I want to mention has to do with string parsing. We can use these regex patterns to fish out parts of strings, but this just gives us `Substring`s. There is a way to have the regex pattern transform those `Substring`s into custom data types for us. Let's look at how we can do that.

Let's assume that we have a custom `enum` to represent the different kinds of transactions that we can encounter.

```swift
enum TransactionType: String {
  case credit = "CREDIT"
  case debit = "DEBIT"
}
```

We can specify a transformation function in our regex, which will take the captured `CREDIT` or `DEBIT` strings and automatically turn them into our `TransactionType.credit` or `.debit` instances.

To do this, we change our `CREDIT`/`DEBIT` capture regex to something like this

```swift
TryCapture(as: transactionTypeRef) {
  ChoiceOf {
    "CREDIT"
    "DEBIT"
  }
} transform: { substring in
  TransactionType(rawValue: String(substring))
}
```

The way this works is the `TryCapture` will take in whatever it matches within its first `{ ... }` block, and pass that to the transform function as the first argument. The type of this argument will be `Substring`. From there you simply parse it into whatever custom type you want and return that. The return type of the transform function is optional so you can return nil if the substring doesn't match. You can even throw errors in there.

One last change still remains, and that is to change the output type of our reference. Replace `Substring.self` with `TransactionType.self` in the definition of `transactionTypeRef`.

```swift
let transactionTypeRef = Reference(TransactionType.self)  // TransactionType.credit
```

Now when you access the transaction type from a match object, rather than returning a `Substring` instance, you should get a `TransactionType` instance.

## Conclusion

This was an overview of the changes and improvements introduced to working with regex in Swift. I hope you find this article useful.

### Sources

- [NSRegularExpression](https://developer.apple.com/documentation/foundation/nsregularexpression)
- [Extended String Delimiters](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/stringsandcharacters/#Extended-String-Delimiters)
- [SE-0350 - Regex Type Overview](https://github.com/apple/swift-evolution/blob/main/proposals/0350-regex-type-overview.md)
- [SE-0351 - Regex Builder](https://github.com/apple/swift-evolution/blob/main/proposals/0351-regex-builder.md)
- [SE-0354 - Regex Literals](https://github.com/apple/swift-evolution/blob/main/proposals/0354-regex-literals.md)
- [Regex](https://developer.apple.com/documentation/swift/regex)
- [RegexBuilder](https://developer.apple.com/documentation/regexbuilder)
