---
title: The Concurrent Core Data Stack
date: 2013-04-02
---

**Update** (2013/04/29): I profiled the performance of the core data stack described in this post in a [more recent article][1], comparing it to other ways of setting up the stack. Please read this for important information regarding the tradeoffs of this setup!

[1]:http://floriankugler.com/blog/2013/4/29/concurrent-core-data-stack-performance-shootout

---

Apple's core data framework plays well with concurrency, if handled correctly. Unfortunately Apple's documentation on this topic is not  very explicit and up to date on the subject. The [core data programming guide](https://developer.apple.com/library/ios/#documentation/Cocoa/Conceptual/CoreData/Articles/cdConcurrency.html) states:

> The pattern recommended for concurrent programming with Core Data is thread confinement: each thread must have its own entirely private managed object context. [...] You must create the managed context on the thread on which it will be used.

So far, so good. However, it doesn't mention that with Mac OS X 10.7 and iOS 5 a new pattern for concurrency was introduced. The [documentation of NSManagedObjectContext](https://developer.apple.com/library/ios/#documentation/Cocoa/Reference/CoreDataFramework/Classes/NSManagedObjectContext_Class/NSManagedObjectContext.html#//apple_ref/occ/cl/NSManagedObjectContext) tells us in one sentence (after stating the same as previously quoted):

> In OS X v10.7 and later and iOS v5.0 and later, when you create a context you can specify the concurrency pattern with which you will use it (see initWithConcurrencyType:).

Digging a little deeper, it turns out that the thread confinement pattern &mdash; calling `initWithConcurrencyType:` with the `NSConfinementConcurrencyType` &mdash; is actually the legacy way of handling concurrency. Apple added two new concurrency types, `NSMainQueueConcurrencyType` and `NSPrivateQueueConcurrencyType`.

With NSPrivateQueueConcurrencyType setting up a managed object context which will operate outside of the main thread is as easy as this:

```objc
[[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
```

Previously you would have allocated the managed object context on a different thread by e.g. wrapping the call in a `dispatch_sync()` block. With the new concurrency types this is not required anymore, because the context will setup its own private dispatch queue anyway. To execute code on the managed object's private queue you simply use `performBlock:`.

Apple also added the possibility to chain managed object contexts together by setting a context's parentContext property to another context. This way you can make some changes to the data and then decide if you want to save these changes or discard them. By saving a child context the changes automatically propagate upwards one level to its parent context. This feature seemed to be plagued by [several bugs in iOS5](http://wbyoung.tumblr.com/post/27851725562/core-data-growing-pains), but these growing pains seem to be resolved with iOS 6.

Chaining managed object contexts together like this also seemed useful to setup a child context in a private queue to import larger amounts of data. It turns out, there is a better pattern for this. But let me first show you my previous setup:

```objc
NSManagedObjectContext* mainContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];

NSManagedObjectContext* backgroundContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
backgroundContext.parentContext = mainContext;
```

The idea was that importing of large data chunks will be performed in the background without blocking the main thread and therefore the user interface too much. However, in this setup the background context is at complete mercy of the main context, because the main context is connected to the persistent store. Any fetch request you perform will cause disk i/o on the main thread. Saving the data in the background context and then saving the main context will inevitably also block the main thread with a disk i/o operation.

![](/images/The-concurrent-core-data-stack.png)

After digging around a lot I found a different and better pattern to setup the core data stack. Apple's own [UIManagedDocument](http://developer.apple.com/library/ios/#documentation/uikit/reference/UIManagedDocument_Class/Reference/Reference.html) seems to use this kind of setup, and I found [several](http://cutecoder.org/programming/multithreading-core-data-ios/) [people](http://www.cocoanetics.com/2012/07/multi-context-coredata/) [recommending](http://www.cocoanetics.com/2013/02/zarra-on-locking/) this pattern, including Marcus Zarra, the author of a often praised [core data book](http://pragprog.com/book/mzcd2/core-data).

The idea is to setup the master managed object context connected to the persistent store with the private concurrency type (operating on a background thread) and then create the main thread's managed object context as a child of this master context. Intensive tasks like importing can be done in worker contexts which are setup as child contexts of the main context with the private concurrency type.

```objc
NSManagedObjectContext* masterContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];

NSManagedObjectContext* mainContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
mainContext.parentContext = masterContext;

NSManagedObjectContext* workerContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
workerContext.parentContext = mainContext;
```

It seems a bit complicated at first, but when you think about it, it makes total sense. Since the master context is running on a background thread, all the heavy lifting of persisting data to disk and reading data from disk is done without blocking the main thread.

There is also a very clean flow of data from the worker contexts through the main context to the master context, which finally persists all changes. Since in this setup you never touch the master context, i.e. you never directly make changes to it, all changes flow through the main context. Therefore you will always have the latest data available on the main thread. No need for listening to change notifications and merging changes manually.

Happy core data-ing!

