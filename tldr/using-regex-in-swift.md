+++
title = "[TLDR] Using Regex in Swift"
description = "An in-depth look at the various different ways to define and use regular expressions in Swift"
excerpt = "In this article I will be walking you through the various different ways to define and use regular expressions in Swift"
date = 2023-12-02
tags = ["Swift"]
+++

Assume the following example input.

```swift
let input = """
CREDIT    03/02/2022    Payroll                   $200.23
CREDIT    03/03/2022    Sanctioned Individual A   $2,000,000.00
DEBIT     03/03/2022    Totally Legit Shell Corp  $2,000,000.00
DEBIT     03/05/2022    Beanie Babies Forever     $57.33
"""
```

## Before iOS 16

Use [`NSRegularExpression`](https://developer.apple.com/documentation/foundation/nsregularexpression) from Foundation.

```swift
let regex = try NSRegularExpression(pattern: #"(CREDIT|DEBIT)\s+"#)
```

Use methods on the regex object to perform regex operations on strings.

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

The focus of this article is on modern Swift regex APIs. To learn more about how to use `NSRegularExpression` fully, [read the docs](https://developer.apple.com/documentation/foundation/nsregularexpression).

## For iOS 16+

Use the new [`Regex`](https://developer.apple.com/documentation/swift/regex) type.

Create regex patterns from string literals.

```swift
let regex = try Regex(#"(CREDIT|DEBIT)\s+"#)
```

`Regex` is generic over what its output type is. The default is `AnyRegexOutput`. Specify an explicit output type on the regex to parse out captured groups.

```swift
let regex = try Regex(#"(CREDIT|DEBIT)\s+(\d+)"#, as: (Substring, Substring, Substring).self)
```

The output type should

- Always be a tuple
- Should consist of `Substring`s (most of the time)
- Should have one more `Substring` than there are capture groups. The first match is always the whole matched string.

Use `String` APIs to perform regex operations on strings.

```swift
let match = input.firstMatch(of: regex)
let allMatches = input.matches(of: regex)
```

Output will be a [`Regex.Match`](https://developer.apple.com/documentation/swift/regex/match) object. Treat it as a tuple object to get captured values out.

```swift
let wholeMatchedSubstring = match?.0        // "CREDIT    03"
let transactionTypeSubstring = match?.1     // "CREDIT"
let monthSubstring = match?.2               // "03"

let transactionTypes = allMatches.map(\.1)  // ["CREDIT", "CREDIT", "DEBIT", "DEBIT"]
```

## Regex Literals

Use regex literals to define regex patterns quicker and more succinctly. To do so, wrap the raw regex pattern with forward slashes (`/`).

```swift
let regex = /(CREDIT|DEBIT)\s+(\d+)/
```

Forward slashes that are part of the pattern must be escaped with back slashes (`\`). To avoid this, use extended delimiters.

```swift
let regex = #/(CREDIT|DEBIT)\s+(\d+)/(\d+)/(\d+)/#
```

This produces a `Regex` object, same as using the normal `Regex` initializer. Except this time the compiler can validate the regex expression at compile time and figure out the right output generic type for us.

Usage of regex patterns generated through regex literals is the same as using any other `Regex` instance.

For regex patterns defined with extended delimiters, you can multiline them for better readability and to comment them. Newlines and white spaces are ignored for multiline regex literals.

```swift
let regex = #/
(CREDIT|DEBIT)     # transaction type
\s+
(\d+)/(\d+)/(\d+)  # date
/#
```

Regex literals also allow us to provide names for our capture groups.

```swift
let regex = #/
(?<transactionType> CREDIT|DEBIT)          # transaction type
\s+
(?<month> \d+)/(?<day> \d+)/(?<year> \d+)  # date
/#
```

For a regex with named capture groups, use the capture group name instead of the tuple indices.

```swift
let match = input.firstMatch(of: regex)
let day = match?.day      // "02"
let month = match?.month  // "03"
let year = match?.year    // "2022"
```

## `RegexBuilder`

Use the first party [`RegexBuilder`](https://developer.apple.com/documentation/regexbuilder) framework for an even better regex crafting experience.

Define a regex pattern using result builders

```swift
import RegexBuilder

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

Make the regex more readable and clean by extrapolating repetitive code and composing regex patterns together.

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

The produced value is still just a `Regex` with its output type automatically set according to the result of the builder. Use it with the same String APIs as regex literals.

For quick and short regex patterns, pass the builder directly into the String API methods.

```swift
let match = input.firstMatch {
  Capture {
    ChoiceOf {
      "CREDIT"
      "DEBIT"
    }
  }
}
let transactionType = match?.1  // "CREDIT"
```

Use [`Reference`s](https://developer.apple.com/documentation/regexbuilder/reference) to create named capture groups

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

Access the captured contents by using the reference objects like keys to the `match` dictionary.

```swift
let match = input.firstMatch(of: regex)
let transactionType = match?[transactionTypeRef]  // "CREDIT"
let day = match?[dayRef]                          // "02"
let month = match?[monthRef]                      // "03"
let year = match?[yearRef]                        // "2022"
```

The type of captured data above is `Substring?`. Use `TryCapture` blocks `Capture` to have those `Substring`s automatically transformed into custom data.

```swift
enum TransactionType: String {
  case credit = "CREDIT"
  case debit = "DEBIT"
}

let transactionTypeRef = Reference(TransactionType.self)
// Other references...

let regex = Regex {
  TryCapture(as: transactionTypeRef) {
    ChoiceOf {
      "CREDIT"
      "DEBIT"
    }
  } transform: { substring in
    TransactionType(rawValue: String(substring))
  }
  // More regex...
}

// transactionType is now a custom type, rather than a Substring.
let transactionType: TransactionType? = match?[transactionTypeRef]
```

Check the sources below for more info.

### Sources

- [NSRegularExpression](https://developer.apple.com/documentation/foundation/nsregularexpression)
- [Extended String Delimiters](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/stringsandcharacters/#Extended-String-Delimiters)
- [SE-0350 - Regex Type Overview](https://github.com/apple/swift-evolution/blob/main/proposals/0350-regex-type-overview.md)
- [SE-0351 - Regex Builder](https://github.com/apple/swift-evolution/blob/main/proposals/0351-regex-builder.md)
- [SE-0354 - Regex Literals](https://github.com/apple/swift-evolution/blob/main/proposals/0354-regex-literals.md)
- [Regex](https://developer.apple.com/documentation/swift/regex)
- [RegexBuilder](https://developer.apple.com/documentation/regexbuilder)
