+++
title = "[TLDR] How to use Tables in SwiftUI"
description = "An in-depth look at how Tables are implemented in SwiftUI"
date = 2023-09-07
tags = ["SwiftUI"]
+++

Throughout this article I will assume the following structure is available.

```swift
struct User: Identifiable {
    let id: UUID

    let firstName: String
    let lastName: String
    let age: Int
    let favoriteColor: Color

    let createdAt: Date
    let updatedAt: Date
}

enum Color {
    case red, orange, yellow, green, blue, purple
}
```

# Creating Tables

- Tables are created by passing in an array of identifiable items and defining what the columns look like inside the table
- The columns can be created by either
  - Passing in a `KeyPath` of the item that leads to a string property
  - Passing in a view builder that takes in an item and returns a view
    - You can put buttons in these views
- You are limited to 10 columns per table, however in iOS 16/macOS 12 we got the ability to compose more of them using `Group`s.

```swift
Table(users) {
  TableColumn("First Name", value: \.firstName)
  TableColumn("Last Name", value: \.lastName)

  TableColumn("Age") { user in
    Text(user.age.formatted())
  }
  .width(40)

  TableColumn("Color") { user in
    ColorView(color: user.favoriteColor)
  }
  .width(min: 55)

  TableColumn("Created") { user in
    Text(user.createdAt.formatted())
  }

  TableColumn("Updated") { user in
    Text(user.updatedAt.formatted())
  }
}
```

# Row Control

- You can customize which rows are visible or not by either changing the data set (the source array), which is the recommended approach.
  - Alternatively, you can avoid passing in the array of items to the table, and instead pass in a second closure which builds `TableRow`s. You can use a `ForEach` in there too. This is also useful if you have fixed/constant data.
- One benefit of doing this is the ability or provide a custom context menu for each row.

```swift
Table(of: User.self) {
  //...Columns...
} rows: {
  ForEach(users) { user in
    TableRow(user)
  }
}
```

# Selection

- Selection works the same as it does in `List`s. You can provide a binding to a nullable property of the same type as the item's ID. This will enable selection in the table. To enable multiple selection provide a binding to a set IDs instead

```swift
let users: [User]
@State private var selection: User.ID?

var body: some View {
  Table(users, selection: $selection) {
    //...Columns...
  }
}
```

# Sorting

- To enable sorting there are a number of steps you must take.
- First declare a bindable property that contains an array of `SortComparator` types. Typically these will be `KeyPathComparator`s. Pass this property to the table.
- Next you must specify how each table will be sorted. There are a number of ways to do this.
  - If you are creating the table using the `KeyPath` initializer and the property is comparable then this happens automatically.
  - If the property that this column should be sorted by is comparable, but you want to customize its presentation, you can provide an additional `value` argument, of type `KeyPath` to the initializer.
  - If the property is not comparable (or if you want to customize the default sorting behaviour) you must provide a custom sort comparator parameter.
   - If neither of these are given, the column is not sortable.
- With all this in place the table view will modify the sort order array based on user input. It will not however sort the actual data. That is your responsibility. For most cases, especially where the data is local, you can do this quite trivially with `Array`'s `sorted(using:)` method.
- Keep in mind that all types related to sorting must be uniform across all of the table.This includes things passed/declared on the table, as well as the columns.

```swift
let users: [User]
private var presentedUsers: [User] {
  users.sorted(using: sortOrder)
}

@State private var sortOrder: [KeyPathComparator<User>] = [
  KeyPathComparator(\.firstName),
  KeyPathComparator(\.lastName),
]

var body: some View {
  Table(presentedUsers) {
    TableColumn("First Name", value: \.firstName)
    TableColumn("Last Name", value: \.lastName)

    TableColumn("Age", value: \.age) { user in
      Text(user.age.formatted())
    }
    .width(40)

    let colorComparator = KeyPathComparator(
      \User.favoriteColor,
      comparator: Color.Comparator()
    )
    TableColumn("Color", sortUsing: colorComparator) { user in
      ColorView(color: user.favoriteColor)
    }
    .width(min: 55)

    TableColumn("Created", value: \.createdAt) { user in
      Text(user.createdAt.formatted())
    }

    TableColumn("Updated", value: \.updatedAt) { user in
      Text(user.updatedAt.formatted())
    }
  }
}
```
