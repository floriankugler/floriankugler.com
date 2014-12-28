---
title: Interface Builder – Curse or Convenience?
date: 2013-04-15
---

Apple's Interface Builder is supposed to assist you with several important tasks in the process of creating user interfaces:

- Laying out views
- Wiring up outlets and actions
- Creating segues between view controllers (with storyboards)

After working on a fairly complex iPad app for the last six months together with [Chris Eidhof][1], my personal bottom line for Interface Builder doesn't look too positive with regard to these tasks. In fact, I'm willing to try out abandoning Interface Builder alltogether for the next project. This may sound pretty radical, but let me walk you through my thought process.

[1]: http://chris.eidhof.nl

We started the project from scratch and were able to target iOS 6 only. Therefore we decided to give Storyboards and Auto Layout a try. After all, it's mostly better to embrace the technologies Apple promotes than to fight them for too long. At least if they don't present a major hassle for your work.

Let's have a look how Interface Builder stacks up against implementing the user interface in code for its most important tasks. Please keep in mind that these experiences stem for one particular large project and might not be true for smaller or just different projects.


## Laying out views

With Auto Layout each views' position and size needs to be unambiguously  determined by a system of constraints. Interface Builder tries to support this process by guessing which constraints you want to create whenever you position a new view or resize/move an existing one. In fact, at no point in time Interface Builder [lets you create an ambiguous layout][10]. The result of this approach is that Interface Builder is constantly making changes to the constraint system that don't coincide with what you are actually trying to achieve.

[10]:http://oleb.net/blog/2013/03/things-you-need-to-know-about-cocoa-autolayout/

![](/images/ib-constraints1.png)

Conceptually layout constraints are a very expressive way of arranging interface elements. Once you wrap your head around this approach it becomes pretty clear which constraints are needed in order to achieve a certain result. This can make using Interface Builder for this process incredibly frustrating. You know exactly what you want to achieve, but Interface Builder keeps interfering.

I really do like Auto Layout. But in Interface Builder creating non-trivial constraint systems is incredibly fragile. Once you finally managed to carefully adjust all the constraints according to your needs, every change to the layout becomes a nail-biting event.

In contrast creating constraints in code is very straightforward and stable. Even making disruptive changes to existing layouts is not too difficult. Furthermore it's easy to create pixel perfect layouts, because you just type in the correct dimensions. On the other hand Interface Builder's lack of a zoom level beyond 100% forces you to click through various inspector pains to enter precise numbers.

The bottom line is that to me Interface Builder is more a burden than a help for laying out views with Auto Layout. Of course Apple's constraint API is pretty verbose, but [a few helper functions][2] go a long way towards writing concise and expressive layout code like this:

[2]: http://github.com/dkduck/FLKAutoLayout

```objc
[button1 alignTop:@"20" leading:@"20" toView:button1.superview];
NSArray* buttons = @[button1, button2, button3];
[UIView alignTopEdgesOfViews:buttons];
[UIView equalWidthsForViews:buttons];
[UIView spaceOutViewsHorizontally:buttons @"10"];
```

## Wiring up actions and outlets

Creating connections between the graphical interface layout and actions or outlets in code was a pretty big deal when Interface Builder was [first introduced in NeXTSTEP][11].

[11]:http://en.wikipedia.org/wiki/Interface_builder

To me it's a "nice to have" feature, but it's not setting the world in fire anymore. Usually it just saves you one trivial line of code per connection. It certainly is not a reason for wether to use interface builder or not.


## Storyboards and Segues

The idea of Storyboards is nice. They create a visual representation of the application flow and should also save some code you usually have to write in order to invoke transitions between view controllers.

However, keeping the storyboard(s) organized can be a major pain, especially for large scale projects where the interface doesn't consist of mostly standard controls. Every view controller looks kind of the same in Interface builder and the segue connection lines are all over the place. The idea of having a nice visual representation of the application flow pretty much stays an idea...

![](/images/ib-storyboard.png)

What about not having to write the code for view controller transitions? Well, when a new view controller comes on screen you mostly have to hand over some objects to this controller to work with. With storyboards you use the prepareForSegue: method for this, since you don't trigger the transition from your own code. If you have multiple transition paths from one view controller, its prepareForSegue: implementation can become pretty ugly. So we ended up writing a lot of this kind of code:

```objc
- (void)prepareForSegue:(UIStoryboardSegue*)segue {
    if ([segue.identifier isEqualToString:SEGUE_SHOW_USER]) {
        [self prepareUserViewController:segue.destinationViewController];
    } else if ([segue.identifier isEqualToString:SEGUE_SHOW_TEAM) {
        [self prepareTeamViewController:segue.destinationViewController];
    } else if ([segue.identifier isEqualToString:SEGUE_SHOW_SCORES) {
        [self prepareScoresViewController:segue.destinationViewController];
    }
}

- (void)prepareUserViewController:(UIViewController*)controller {
    ...
}

- (void)prepareTeamViewController:(UIViewController*)controller {
    ...
}

- (void)prepareScoresViewController:(UIViewController*)controller {
    ...
}
```

This doesn't exactly look like saving a lot of code. But wait, what about the code you normally have to write to trigger the transition in the first place? It is handy that you can just drag a segue e.g. from a collection view cell to another view controller. This way you don't need to hook into the collectionView:didSelectItemAtIndexPath: delegate method in order to trigger the transition &ndash; one point for you, Interface Builder!

However, I don't see a big advantage of replacing the implementation of this method by the implementation of the prepareForSegue: method. The only thing you're really saving is the call to  pushViewController:animated: or something similar depending on the transition.

I'm not particularly opposed to using storyboards, but I also don't see a lot of added value in them. Anyway, storyboards are certainly no reason for me to stick with interface builder.


## Roundup

One of the main purposes of Interface Builder is to layout views in an easy way. The fragility of this process with layout constraints makes me prefer doing it in code. That's where Interface Builder defeats its own purpose for me.

I will try the "Interface Builder"-less approach with my next project and let you know how it goes!

