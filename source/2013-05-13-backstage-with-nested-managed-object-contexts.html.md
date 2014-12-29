---
title: Backstage with Nested Managed Object Contexts
date: 2013-05-13
---

Two weeks ago I wrote about the [huge performance differences between various concurrent core data stack setups][1] when importing data. The old-school setup with two independent contexts using the same persistent store coordinator turned out to have a much smaller performance impact on the main thread compared to an alternative [parent/child setup][2].

[1]:/blog/2013/4/29/concurrent-core-data-stack-performance-shootout
[2]:/blog/2013/4/2/the-concurrent-core-data-stack

In this article I will take a look behind the scenes of how nested managed object contexts operate and explain why the performance of saving a child context often is much worse than manually merging changes into a context. Understanding how each approach works will make clear, that nested contexts are certainly not a replacement for "manual" merging.


## Merging vs. Saving

In order to understand better what Core Data actually does when merging changes vs. saving a child context, I disassembled the Core Data framework from OS X 10.8.3 using [Hopper][100] and followed its steps for both scenarios. However, before I'm going to walk you through some of the internals, let's first have a look at this problem from a common sense perspective.

[100]:http://www.hopperapp.com

When you are working with two independent contexts and call [`mergeChangesFromContextDidSaveNotification:`][200] on one of them, all this context has to do is to update the objects contained in the save notification which are already registered with itself. All other objects can just be ignored, because they cannot be in use anyway. When importing large amounts of data on a background context, this behavior makes total sense. After all, most of the changed objects won't be of interest to the context in the main thread.

[200]:https://developer.apple.com/library/mac/documentation/Cocoa/Reference/CoreDataFramework/Classes/NSManagedObjectContext_Class/NSManagedObjectContext.html#//apple_ref/occ/instm/NSManagedObjectContext/mergeChangesFromContextDidSaveNotification:

In contrast, saving a child context has to copy all changes in its object graph to the parent context. Otherwise saving the parent context wouldn't propagate these changes further to the persistent store. Therefore, this is by definition a much more expensive operation than a merge, at least if a significant portion of the changes affect objects which the parent context is not currently interested in.


## Behind the Scenes

In order to back up this reasoning, I will give you a high level overview of what can be read from the Core Data framework disassembly. Additionally I will mix in some little assembler code snippets here and there, in order to give you a taste of how much fun digging in this code is ;-). If you are interested in learning more about how to read assembler code, I recommend reading the [Assembler posts][300] by [Gwynne Raskind][301] on [Mike Ash's blog][302], as well as the [X86_64 Assembly Language Tutorial][303] by the [Cocoa Factory][304] as an introduction.

[300]:http://www.mikeash.com/pyblog/?tag=assembly
[301]:http://blog.darkrainfall.org
[302]:http://www.mikeash.com/pyblog/
[303]:http://cocoafactory.com/blog/2012/11/23/x86-64-assembly-language-tutorial-part-1/
[304]:http://cocoafactory.com

First, let's have a look at what happens when you call the `save:` method on a child context.

After building a [`NSSaveChangesRequest`][400] with all the changed objects, it sends an [`executeRequest:withContext:error:`][401] message to the context's [`_parentObjectStore`][402]. In our case the `_parentObjectStore` is the parent context.

[400]:https://github.com/nst/iOS-Runtime-Headers/blob/master/Frameworks/CoreData.framework/NSSaveChangesRequest.h
[401]:https://github.com/nst/iOS-Runtime-Headers/blob/master/Frameworks/CoreData.framework/NSManagedObjectContext.h#L211
[402]:https://github.com/nst/iOS-Runtime-Headers/blob/master/Frameworks/CoreData.framework/NSManagedObjectContext.h#L50

![](/images/asm-save.png)

`NSManagedObjectContext`'s implementation of the `executeRequest:withContext:error:` method distinguishes according to the request's type. In order to follow the right execution path, we have to look up the `requestType` of `NSSaveChangesRequest`. A search for the `requestType` method tells us that the request type is 0x2.

![](/images/asm-requestType.png)

Following down this path we encounter a call to the context's [`_parentProcessSaveRequest:inContext:error:`][500] method. This is a relatively lengthy routine which basically loops over the save request's inserted and updated objects, and – this is the important part – copies them into the parent context using the
[`_copyChildObject:toParentObject:fromChildContext:`][501] method. Finally it loops over the deleted objects and deletes them from itself. Here is one example of such a loop for the inserted objects:

[500]:https://github.com/nst/iOS-Runtime-Headers/blob/master/Frameworks/CoreData.framework/NSManagedObjectContext.h#L135
[501]:https://github.com/nst/iOS-Runtime-Headers/blob/master/Frameworks/CoreData.framework/NSManagedObjectContext.h#L84

![](/images/asm-parentProcessSaveRequest.png)

As we suspected, saving to a parent context is a quite expensive operation, because it pushes all changes from the child context into the parent context's object graph. For scenarios where we insert, update or delete many objects which are not of interest to the parent context, this creates a lot of unnecessary work.

Now let's have a look at what `mergeChangesFromContextDidSaveNotification:` does.

`mergeChangesFromContextDidSaveNotification:` gets forwarded to [`_mergeChangesFromDidSaveDictionary:usingObjectIDs:`][1]. This is a quite unwieldy routine with all kinds of loops and conditions, which makes it a bit cumbersome to track its execution flow in the disassembly. Checkout the <a href="/s/mergeChangesFromDidSaveNotificationUsingObjectIDs-10000feet.png" target="_blank">whole method in its disassembled glory</a>, what a beast! In cases like this it is sometimes very helpful to override private framework methods in a test app and to insert some log statements, in order to see which execution path was taken or how often a method was called.

[1]:https://github.com/nst/iOS-Runtime-Headers/blob/master/Frameworks/CoreData.framework/NSManagedObjectContext.h#L124

Anyway, the gist of it is this: first it loops over the inserted and updated objects and gathers information about wether these objects are registered in the current context, if they have changes, if they are faults, etc. If an object is not faulted, the new values are retrieved with `NSManagedObject`'s [`_newChangedValuesForRefresh__`][600] method and stored for later. Then deletions are processed.

[600]:https://github.com/nst/iOS-Runtime-Headers/blob/master/Frameworks/CoreData.framework/NSManagedObject.h#L100

In a second step the method loops over the inserted and updated objects again, but this time the real merging happens. For objects of which new values were gathered in the previous step or which need a refresh (e.g. to enable KVO)  [`_mergeRefreshObject:mergeChanges:withPersistentSnapshot:`][700] gets called.

[700]:https://github.com/nst/iOS-Runtime-Headers/blob/master/Frameworks/CoreData.framework/NSManagedObjectContext.h#L127

![](/images/asm-mergeRefreshObjects.png)

This method does the actual work of updating the managed object with the new values and triggers the change notification methods `willChangeValueForKeys:` and `didChangeValueForKeys:`. But remember that this only happens for objects which were already in use by the context before.

Interestingly, `_mergeChangesFromDidSaveDictionary:usingObjectIDs:` uses [`objectRegisteredForID:`][800] when looping over the updated objects of the save notification. This way it discards all changes up front which affect objects that weren't previously registered in this context. However, when looping over the inserted objects it calls [`objectWithID:`][801], which will return a managed object in any case. This object then gets checked for pending changes, its fault status and for associated observers. It seems to me that an object, which has not been registered with the context before, will always be a fault and never have any pending changes or observers associated with it. Therefore it will never be marked as needing a merge, and `objectRegisteredForID:` could have been used to begin with. But probably I'm missing something here – please ping me if you have any insights into why this might be necessary!

[800]:https://developer.apple.com/library/mac/documentation/Cocoa/Reference/CoreDataFramework/Classes/NSManagedObjectContext_Class/NSManagedObjectContext.html#//apple_ref/occ/instm/NSManagedObjectContext/objectRegisteredForID:
[801]:https://developer.apple.com/library/mac/documentation/Cocoa/Reference/CoreDataFramework/Classes/NSManagedObjectContext_Class/NSManagedObjectContext.html#//apple_ref/occ/instm/NSManagedObjectContext/objectWithID:


## Implications

Merging changes and saving a child context do very different things. This makes clear that we should choose between these options depending on what we are trying to accomplish. Nested managed object contexts are clearly made for scenarios, where most of the changes propagated from the child context are immediately relevant to the parent context. The classical example is the scratch-pad use case, where you use a child context to edit a set of data with the option to dismiss or to save the changes (although this can also be achieved with the undo manager).

UIManagedDocument also uses a parent-child setup. This gives Apple the possibility to save the background (parent) context whenever and how often they decide to do so, while application developers can save the main (child) context whenever they want without blocking the main thread by disk i/o. It's probably no coincident that nested contexts where introduced in iOS 5 together with the iCloud storage options.

On the other hand there are scenarios like importing data, where the context on the main thread is not interested in any or only a small fraction of the new data. In this case a nested context setup (especially one where the data has to flow through the main thread context) is the wrong tool for the job and results in [massive amounts of work done][900] for nothing.

[900]:http://floriankugler.com/2013/4/29/concurrent-core-data-stack-performance-shootout

I would suggest that you don't consider nested managed object contexts to be the new way of implementing concurrent core data setups. It is an additional feature which fits certain use cases, but the old-school stack with independent contexts and a common persistent store coordinator still is preferable in many cases.

