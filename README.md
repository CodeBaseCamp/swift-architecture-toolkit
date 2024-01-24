# `ART` - A minimalist toolkit for architecting Swift(UI) apps

## tl;dr

Minimal modular single-entry architecture allowing for feedback-loop-centric and observation-based
manipulation of application and system state, written in Swift and licensed under the permissive MIT
license. The architecture is significantly inspired by redux-pattern-based approaches to application
architectures, and particularly
[The Composable Architecture (TCA)](https://github.com/pointfreeco/swift-composable-architecture).
It is definitely much more barebone than TCA but might still be useful for some of you folks out
there.

## Disclaimer

This repository is work in progress and commits with breaking changes might be added to any branch at
any time. Since this project is a personal one, no warnings will be given for now. It is advisable to
not rely on the code in this repository for anything other than for hobby projects.

## Introduction

On a very high conceptual level, software applications are simple. They consist of mutable state
which can be modified using appropriate operations. One can distinguish between state which is fully
visible and controlled by the application and state which is not or only partially visible and
controlled by the application. The first is usually called _application state_ while the latter can
be referred to as _system state_. Clearly separating the two concepts with well-defined boundaries
is not just a theoretical exercise but is important for state persisting and loading, testability,
reduced cognitive load, and—last, not least—every engineer’s best friend, simplicity.

When writing non-trivial software applications, it is (usually) vital to rely on an application
architecture which naturally lends itself to clear separation of concerns, is easy to understand and
use, and fulfills key criteria such as support for thorough testing, high performance, and
straightforward integration of third-party services.

### Meet ART

`ART` attempts to help you fulfill these constraints by providing a minimal architecture toolkit
for Swift developers, allowing for a unified approach towards writing applications. In `ART`, the
application state is updated according to so-called update _requests_, while the system state is
manipulated by _side effects_. Both _requests_ and _side effects_ are assumed to be immutable value
objects. The readable part of the system state can be accessed via _coeffects_. The actual execution
of the _requests_ and _side effects_ is performed by a so-called _logic module_ (which internally
delegates these tasks to individual objects, the _model_ in case of _requests_ and the _side effect
performer_ in case of _side effects_). For the sake of convenience, `ART` allows for the combination
of _requests_ and _side effects_ into so-called _executables_.

Since, by definition, the application state models the state of the entire application, the app UI
is a mere function of said state and it is therefore sufficient to inform the component responsible
for the UI solely about the initial state and subsequent changes of the state. These UI updates are
achieved in `ART` by observing the application state.

The logic of an application is executed in various scenarios:

a) interaction of the user with the UI, leading to an update of the application and/or the system
state

b) changes of the application state

c) changes of the system state

d) interaction with the application via a different means like an API

In `ART`, scenario (a) is conceptually handled by a so-called _UI logic module_ which for an
incoming user interaction sends appropriate _requests_ and/or _side effects_ to the logic module,
taking into account the current application and system state, if necessary. Scenario (b) is handled
by observers added to the _logic module_. Scenario (c) should be handled by the application relying
on the appropriate callback or observation functionality, then reacting by sending _requests_ and/or
_side effects_ to the logic module. Scenario (d) can be tackled in the same way as scenario (c).

### Overview of the main components in `ART`

![Overview of the main components in `ART`](/Media/Overview.png)

## Q&A

### When to consider using `ART`?

`ART` is a minimal and rather barebone toolkit for building Swift(UI) apps. It attempts to be as
independent of other libraries as possible. While I’ve been using it only on medium-sized
applications for personal usage so far, there shouldn’t be something which hinders you from building
complex apps with it. However, as stated in the license under which `ART` lives, the software is
provided "as is", without warranty of any kind, so make sure to know what you are doing.

### When not to use `ART`?

The concepts `ART` relies on are not entirely trivial, so if you simply want to build a
quick’n’dirty prototype or a very simple single-screen app without much logic, `ART` is probably an
overkill. If you disagree with any of its concepts, particularly the value-object-based side-effect
modelling, you probably shouldn’t use it either.

Also, keep in mind that—unlike architectures such as incredible
[TCA](https://github.com/pointfreeco/swift-composable-architecture)—there is no
community behind `ART` and it is entirely unclear to which extent `ART` will be maintained in the
future.

### Where to start?

The best place to familiarize yourself with the basic setup of an `ART`-based application is in
[TaskBasedUsageExampleSpec](/Tests/ARTTests/Example/TaskBasedUsageExampleSpec.swift) for usage with
structured concurrency and/or [UsageExampleSpec](/Tests/ARTTests/Example/UsageExampleSpec.swift) for
usage with dispatch queues.

### How to integrate `ART`?

In a Swift package, add `ART` to `Package.swift`:

```swift
dependencies: [
  .package(url: "https://github.com/CodeBaseCamp/swift-architecture-toolkit", branch: "master"),
],
targets: [
  .target(
    dependencies: [
      .product(name: "ART", package: "swift-architecture-toolkit"),
    ],
  )
]
```

Otherwise, [add `ART` as a package dependency in Xcode](https://developer.apple.com/documentation/xcode/adding-package-dependencies-to-your-app).

### Why does `ART` use value objects for representing side effects?

The usage of value objects does indeed add an extra layer of abstraction, which can be a benefit or
a disadvantage, depending on the situation. The following aspects will usually be considered as
benefits:

- the representations of side effects are detached from their execution, allowing for composition of
  more complex side effects without the need for additional API
- side effects can be made persistable in a straightforward fashion by conforming to the `Codable`
  protocol
- side effects can easily be logged, filtered, or, if needed, be augmented before execution
- integration testing of the application becomes easier since the API implementation requirements of
  mocks of the side effect performer are extremely simple, while allowing for an arbitrarily complex
  mocking behavior

### Why are observers in `ART` `class`es rather than `struct`s?

In `ART`, deallocation of observers is used as a convenient way of stopping and removing
observations.
