---
title: Concurrent Core Data Stacks – Performance Shootout
date: 2013-04-29
---

A few weeks ago I wrote about a [concurrent core data stack setup][1] which uses the [nested context feature][3] introduced with iOS 5. This setup was recommended amongst others [by Marcus Zarra][2]. It seemed elegant and straightforward, while putting the majority of the heavy lifting on a background thread.

[1]:http://floriankugler.com/blog/2013/4/2/the-concurrent-core-data-stack
[2]:http://www.cocoanetics.com/2013/02/zarra-on-locking/
[3]:http://developer.apple.com/library/ios/releasenotes/DataManagement/RN-CoreData/index.html#//apple_ref/doc/uid/TP40010637-CH1-SW1

I was wondering though how much the main thread will be affected in this setup by extensive work done in one of the worker contexts (see the diagram for stack #2 below if you haven't read my [previous article][4]). After all, every fetch request and every save done in a worker context will pass through the main context before hitting the master context in the background thread. Therefore I expected there to be at least a small impact on the main thread.

[4]:http://floriankugler.com/blog/2013/4/2/the-concurrent-core-data-stack

Of course the only way to find out is to measure! And that's what I did: I ran the same large import operation (approximately 15,000 objects) on top of three different core data stack setups and evaluated the performance behavior with Instruments &ndash; especially with regard to the effect of the import operation on the main thread and therefore the user interface responsiveness. Read on for the results of this core data stack shootout!

## Three different core data stacks

The first setup is a not so smart solution you sometimes see or read about. I included this stack on purpose as a reference point for the better alternatives. In this case the core data stack consists of a main managed object context initialized with the [`NSMainQueueConcurrencyType`][5], and a background managed object context initialized with the [`NSPrivateQueueConcurrencyType`][5]. The main context is configured to be the parent context of the background context. In this setup the background context is used for the data import.

[5]:https://developer.apple.com/library/mac/documentation/Cocoa/Reference/CoreDataFramework/Classes/NSManagedObjectContext_Class/NSManagedObjectContext.html#//apple_ref/doc/c_ref/NSManagedObjectContextConcurrencyType

![](/images/cd-stack-1.png)

The second setup is the one I [described in my previous article][10]. It consists of three layers: the master context in a private queue, the main context as its child in the main queue, and one or multiple worker contexts as children of the main context in the private queue. In this example the worker contexts are used to import the data.

[10]:http://floriankugler.com/blog/2013/4/2/the-concurrent-core-data-stack

![](/images/cd-stack-2.png)

The third option is a more conservative stack which does not use the relatively new feature of [nested managed object contexts][20]. This stack consists of two independent managed object contexts which are both connected to the same persistent store coordinator. One of the contexts is set up on the main queue, the other one on a background queue. Change propagation between the contexts is achieved by subscribing to the [`NSManagedObjectContextDidSaveNotification`][21] and calling [`mergeChangesFromContextDidSaveNotification:`][22] on the other context.

[20]:http://developer.apple.com/library/ios/releasenotes/DataManagement/RN-CoreData/index.html#//apple_ref/doc/uid/TP40010637-CH1-SW1
[21]:https://developer.apple.com/library/mac/documentation/Cocoa/Reference/CoreDataFramework/Classes/NSManagedObjectContext_Class/NSManagedObjectContext.html#//apple_ref/c/data/NSManagedObjectContextDidSaveNotification
[22]:https://developer.apple.com/library/mac/documentation/Cocoa/Reference/CoreDataFramework/Classes/NSManagedObjectContext_Class/NSManagedObjectContext.html#//apple_ref/occ/instm/NSManagedObjectContext/mergeChangesFromContextDidSaveNotification:

![](/images/cd-stack-3.png)

## Expectations

Clearly the first setup with the context on the main thread connected to the persistent store should perform pretty poorly. Every fetch request and every save operation will fully block the main thread while data is read or written to/from disk. This setup shouldn't perform much better than if you would just import directly into the main context.

I had high hopes for the second stack with its three contexts set up in a nested fashion, because it's pretty elegant and you don't have to deal with change propagation yourself. The context on the main thread operates only in-memory and therefore all operations on it should be pretty fast. I wasn't sure though how much time it would take the main context to act as an intermediary between the worker and the master context, routing requests forth and back.

The third setup seems to be the one which interferes least with the main thread. However, we still have to propagate the changes from the background context to the main context using [`mergeChangesFromContextDidSaveNotification:`][25]. I was curious how this change propagation would stack up performance-wise against what the nested setup does internally.

[25]:https://developer.apple.com/library/mac/documentation/Cocoa/Reference/CoreDataFramework/Classes/NSManagedObjectContext_Class/NSManagedObjectContext.html#//apple_ref/occ/instm/NSManagedObjectContext/mergeChangesFromContextDidSaveNotification:

## Profiling results

Core Data stack #3 with its independent managed object contexts blew the other two options out of the water. It literally crushed them. I didn't expect the nested setup #2 to be so much inferior. Let's have a look at the numbers first:

<table>
<tr>
<th style="text-align:left;width:40%;">Setup</th>
<th style="text-align:right;width:25%;">Total time</th>
<th style="text-align:right">&nbsp;&nbsp; Time on main thread</th>
</tr>
<tr>
<td><strong>Stack 1:</strong> main - background as nested contexts</td>
<td style="text-align:right">83 s</td>
<td style="text-align:right">43 s</td>
</tr>
<tr>
<td><strong>Stack 2:</strong> master - main - worker as nested contexts</td>
<td style="text-align:right">105 s</td>
<td style="text-align:right">29 s</td>
</tr>
<tr>
<td><strong>Stack 3:</strong> master - background as independent contexts</td>
<td style="text-align:right">67 s</td>
<td style="text-align:right">0.27 s</td>
</tr>
</table>

To visualize these results better let me show you some Instruments traces from the CPU strategy view. In these traces all the work done on the main thread is colored in blue, whereas all the work done in the background is colored in grey.

![](/images/cd-traces.png)

What a difference! Stack #2 with its nested contexts spends quite a lot of time in the main thread shuttling messages and data forth and back between the background worker context and the background master context. Actually, the total import time is slower than with stack #1 by almost the same amount of time as the main context spends as an intermediary between the other two contexts. I didn't expect this to bind so many resources compared to the tiny sliver of blue in the trace of stack #3, which is caused by merging the data from the background into the main context.

Of course you could argue that an import of 15,000 objects is unrealistic or should be solved differently anyway. However, if you break those numbers down to smaller amounts of objects, e.g. 100 at a time, then we are still talking about work done on the main thread on the order of hundreds of milliseconds. This matters for keeping the user interface responsive.

By the way, all tests have been performed on an iPad mini with Instruments running in non-deferred mode. And as a disclaimer: the import process used in these examples still has plenty of optimization opportunities left, like using a [faster method of parsing date strings][30], parallelizing work better and being a bit smarter about when and how often to save. These measures will not change the time by orders of magnitude, but they might cut it in half. So, don't take these numbers as reference points to what's possible in terms of data import performance. They just serve as comparison values between the different core data stack setups.

[30]:http://soff.es/how-to-drastically-improve-your-app-with-an-afternoon-and-instruments

## Conclusion

The old-school setup of independent managed object contexts using the same persistent store coordinator is clearly superior in terms of performance. The stack with the nested contexts is a bit easier to set up, but you really pay for this convenience. If you are experiencing any problems with user interface responsiveness during data imports and you are not using a setup like stack #3 yet, I strongly recommend you to give it a try!

---

**Update** (2013-04-30)

Some people asked me how often I was saving during the import operation. In the original data above the importer was not very smart about this and saved once after importing each entity type and once every 500 relationships (First all objects are imported, then all relationships are resolved). Since the majority of the objects has the same entity type, this resulted in a huge save operation with approximately 10,000 objects.

In order to quantify the impact of this I changed the algorithm to save once every 500 objects and then once every 500 relationships as before. The whole import performs a bit better now, but it doesn't make any difference in terms of the time spent on the main thread:

<table>
<tr>
<th style="text-align:left;width:40%;">Setup</th>
<th style="text-align:right;width:25%;">Total time</th>
<th style="text-align:right">Time on main thread</th>
</tr>
<tr>
<td><strong>Stack 2:</strong> master - main - worker as nested contexts</td>
<td style="text-align:right">87 s</td>
<td style="text-align:right">31 s</td>
</tr>
<tr>
<td><strong>Stack 3:</strong> master - background as independent contexts</td>
<td style="text-align:right">57 s</td>
<td style="text-align:right">0.23 s</td>
</tr>
</table>

In order to illustrate the frequency of saves, here is a trace of the import from the core data instrument:

![](/images/core-data-activity-trace.png)

In order to be fair towards nested managed object context I have to make one more remark. The internal change propagation when saving a child context seems to be doing something more than what happens when calling `mergeChangesFromContextDidSaveNotification:`. Saving a worker context in stack #2 causes a `NSFetchedResultsController` to update even if only a relationship of an object changed. Saving and merging the background context from stack #3 doesn't trigger the update in this case.

However, a quick experiment to fix this issue in the dumbest possible way only increased the time stack #3 spent on the main thread by *1.5* seconds. The additional work done stems from this code before the merge, which makes sure that object is not a fault before the merge happens:

```objc
NSArray* objects = [notification.userInfo valueForKey:NSUpdatedObjectsKey];
for (NSManagedObject* obj in objects) {
    NSManagedObject* mainThreadObject = [mainContext objectWithID:obj.objectID];
    [mainThreadObject willAccessValueForKey:nil];
}
```

---

**Update** (2013-05-13)

I wrote a follow up post ([Backstacke with Nested Managed Object Contexts](/blog/2013/5/11/backstage-with-nested-managed-object-contexts)) which explains why merging changes manually is so much faster than saving a child context.

