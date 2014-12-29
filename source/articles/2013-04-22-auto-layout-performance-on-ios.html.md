---
title: Auto Layout Performance on iOS
date: 2013-04-22
---

[Auto Layout][1] made its first appearance with Mac OS X Lion. One year later Apple [introduced it on iOS 6][2] as the new and preferred way of laying out views (Auto Layout is enabled by default). It's main advantage is that it allows for more flexible layouts when dealing with multiple screen sizes, interface orientations and languages.

The project I'm currently working on with [Chris Eidhof][3] uses Auto Layout for most of its interface layout. However, as the project was nearing its final stages and we started to look more into performance issues, the question arose how Auto Layout actually impacts performance. We found ourselves disabling Auto Layout in more and more places, because it had a significant performance hit.

Searching for information about the performance characteristics of Auto Layout didn't bring up anything useful. Therefore I started my own Auto Layout profiling experiment and can now share some useful information with you in order to be able to make good decisions of when to use or not to use this technology.

[1]:https://developer.apple.com/library/mac/#documentation/UserExperience/Conceptual/AutolayoutPG/Articles/Introduction.html
[2]:https://developer.apple.com/library/ios/#releasenotes/General/WhatsNewIniOS/Articles/iOS6.html
[3]:http://chris.eidhof.nl


## Auto Layout Performance in Theory

With Auto Layout you specify a series of explicit and implicit constraints for each view. Explicit constraints are the ones [you create in Interface Builder][10] or in code (`[NSLayoutConstraint constraintWith...]`) like width, height, spacing or alignment constraints. Implicit constraints are the constraints which are created from properties like the [content hugging priority][11] and [compression resistance priority][12].

Each constraint is basically just a simple linear equation. All constraints together define a [system of linear equations][13] which unambiguously describe the layout, given that you have set up the constraints correctly. In order to translate the constraints into frames, Auto Layout has to solve this system of linear equations. Therefore Auto Layout necessarily presents a performance hit compared to setting the frames of the views yourself. The question is just: how much time does it take?

We know that [constraint satisfaction][14] problems as Auto Layout are decision problem of [polynomial complexity][15] (Auto Layout uses the [Cassowary constraint solver][16]). That means that the amount of time it takes to solve the constraint system increases disproportionally relative to the number of constraints involved. We will be able to clearly see this characteristic in the measurements below.

The polynomial complexity of the Auto Layout algorithm tells us already, that it probably can deal with a small number of views, but will run into serious performance problems for a large number of views. But what is "small", and what is "large"? Furthermore the interdependency of the constraints also plays a role in the time it takes to calculate the layout, as we will see below.

[10]:http://floriankugler.com/blog/2013/4/15/interface-builder-ndash-curse-or-convenience
[11]:http://developer.apple.com/library/ios/#documentation/UIKit/Reference/UIView_Class/UIView/UIView.html#//apple_ref/occ/instm/UIView/contentHuggingPriorityForAxis:
[12]:http://developer.apple.com/library/ios/documentation/UIKit/Reference/UIView_Class/UIView/UIView.html#//apple_ref/occ/instm/UIView/contentCompressionResistancePriorityForAxis:
[13]:http://en.wikipedia.org/wiki/System_of_linear_equations
[14]:http://en.wikipedia.org/wiki/Constraint_satisfaction
[15]:http://en.wikipedia.org/wiki/P_(complexity)
[16]:http://www.cs.washington.edu/research/constraints/cassowary/


## Profiling Auto Layout

In order to measure the performance hit of Auto Layout I created a small and ugly test app ([check it on GitHub][20]) which layouts and draws an arbitrary number of views in different ways:

[20]:https://github.com/dkduck/AutoLayoutProfiling

- Each view is laid out relative to the same super view
- Each view is laid out relative to a sibling
- Each view is nested into the previous one

All tests were performed on an iPad mini (1st generation, for future reference...) and profiled with Instruments. For each attempt I entered the number of views to render and then chose the way the should be rendered by tapping one of the buttons. The subsequent work done to accomplish this task was measured with the time profiling instrument.

![](/images/al-profiling-app.png)

![](/images/al-instruments-time-profiler.png)

The following graph shows the performance cost of Auto Layout for flat view hierarchies. You can clearly see the polynomial time behavior of the constraint solving algorithm here. Note the scale of the x-axis: In this case we are laying out between 100 and 1000 views. The time quickly goes beyond one second above approximately 200 views. The difference between laying the views out relative to each other or independent from each other is notable, but relatively small.

![](/images/al-flat.png)

The next graph shows the performance characteristics for nested view hierarchies. In this example every new view is a subview of the previous one and its constraints are defined relative to its immediate super view. At first glance the curve looks deceivingly similar &ndash; but have a look at the scale of the x-axis again. This time we are laying out between just 20 and 200 and views. The layout takes already longer than one second for approximately 50 views.

![](/images/al-nested.png)

We clearly see that nested view hierarchies are way more expensive than flat ones. Of course the number of views used for these tests is way beyond what you will encounter in real life apps. But testing this way demonstrates the time characteristics of Auto Layout's algorithm very well.



## A Real World Example

In order to give you a better idea of what these results mean in the real world, I will give you an example from a current project. Have a look at the screenshot below to get an idea of the complexity of the layout. I added the light green boxes so that you can see what the view hierarchy looks like.

![](/images/al-app-screenshot.png)

We are dealing with 27 views distributed in a view hierarchy with a maximum depth of 2. I haven't isolated the exact time it takes to layout this part of the screen, but I will give you the numbers of how long it takes to layout the whole screen with Auto Layout enabled and disabled only for the area in question (average time of ten samples).

- With Auto Layout: **183ms**
- Without Auto Layout: **122ms**

Auto Layout takes up approximately one third of the time it takes in total to bring this view on screen (there is still quite some optimization potential left in other areas as well...). Of course it depends on the specific use case if an extra 60ms spent on layout matters or not. In our case it mattered a lot, because we have to bring these kind of views on screen very quickly while the user pages through the "cards".


## Conclusion

Auto Layout is a technology with benefits and drawbacks. I think it is important to talk about both sides in order to be able to make good decisions. I hope that the measurements and examples above provide some insight into the performance cost of Auto Layout, so that you have a better idea if this is relevant for your use case or not. In the end the question is not if Auto Layout is good or bad. The question is if it is the right tool for the job.

My conclusion is that Auto Layout is great for views which are not created on the fly and where a few hundreds of a second more or less don't make a big impact. For these cases the benefits of Auto Layout can easily outweigh the small performance cost.

For views where the amount of time it takes to create them is crucial (like the contents of table view & collection view cells, paging views, etc.) you have to keep the view hierarchy very simple and closely watch the performance impact of Auto Layout. In these cases it might be worthwhile to try disabling Auto Layout before you go straight to drawing everything manually with Core Graphics.

Anyway, measure the difference it makes and make the right choice for you!

Speaking of measuring: I will talk about using Instruments to optimize app performance at [UIKonf][40] in Berlin on May 2nd. Come by if you can &ndash; it will be an awesome event!

[40]:http://www.uikonf.com

---

**Update** (2013-05-28)

[Martin Pilkington][50] posted an [article on his blog][51] reexamining my findings. And he makes a good point regarding the measurement of nested subviews: You should always install the constraints at the nearest common ancestor of the two views you are constraining to each other. In my example of nested subviews I installed all constraints on the root view, which was an oversight on my part.

[50]:https://twitter.com/pilky
[51]:http://pilky.me/view/36

This changes the scale of the graph for the contrived example of nesting hundreds of views inside of each other to the better. It doesn't change a lot though when looking at the lower end of the curve, which reflects the range of nesting levels you would see in a real world application.

The conclusion though stays pretty much the same: Auto Layout is fast enough for many use cases. However, if what you're doing is really performance sensitive, try laying the views out manually and measure if the difference it makes is significant for your application!
