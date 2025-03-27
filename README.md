# `#once`

[![CI](https://github.com/davdroman/swift-once-macro/actions/workflows/ci.yml/badge.svg)](https://github.com/davdroman/swift-once-macro/actions/workflows/ci.yml)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fdavdroman%2Fswift-once-macro%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/davdroman/swift-once-macro)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fdavdroman%2Fswift-once-macro%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/davdroman/swift-once-macro)

A Swift macro that makes it dead simple to execute something *just once*.

## Motivation

Sometimes you want to ensure a piece of code only runs once—no matter how many times it's called. That’s what `#once` is for.

Just wrap your code in a `#once` block, and Swift will take care of the rest:

```swift
#once {
	print("Doesn't matter how many times this is called, it'll only be printed once")
}
```

This is useful for:

- One-time side effects (e.g. analytics, logging)
- Lazy initialization in non-global contexts
- Ensuring swizzling or other runtime setup runs exactly once
- Basically anything you only want to trigger *just once*

No need for custom flags, static vars, or DispatchOnce-style wrappers. Just write your code where you want it to run once, and be done with it.

Thread-safe and works with async code.

## Getting Started

Add the package via Swift Package Manager:

```swift
.package(url: "https://github.com/davdroman/swift-once-macro", from: "1.0.0"),
```

```swift
.product(name: "Once", package: "swift-once-macro"),
```

Then import and use:

```swift
import Once

#once {
	// executes once, ever
}
```

That's it.
