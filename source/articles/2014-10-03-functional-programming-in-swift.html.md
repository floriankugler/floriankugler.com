---
title: Functional Programming in Swift
date: 2014-10-03
---

A few months ago I started working on the [Functional Programming in Swift](http://www.objc.io/books) book together with [Chris Eidhof](https://twitter.com/chriseidhof) and [Wouter Swierstra](https://twitter.com/wouterswierstra), and we've just released the first version into the wild. It has been a challenging and educational experience, since my knowledge of functional programming was tangential at best when Chris, deeply familiar with functional programming himself, convinced me to join this project.

READMORE

I want to take the opportunity of the release of the book to write up some personal thoughts on how it came to life, as well as how Swift and its more obscure and foreign features (for Objective-C developers at least) have grown on me since.


## The Background

I've spent the overwhelming majority of my programming career working in object oriented languages. When I started out more than 20 years ago, I first learned Turbo Pascal before jumping right into x86 assembler and a bit later C. When I was first introduced to object oriented programming with Object Pascal, I couldn't really wrap my head around it at first, and didn't see much value in it for a little while longer.

Eventually I got used to it and it became second nature. Over the years I developed mainly in Delphi, PHP, MATLAB, Javascript, and finally Objective-C. The only point of contact with a radically different programming paradigm was a Prolog excursion in a university course — and to be honest, I hated it at the time.

So here I was, with 20+ years of imperative and object oriented programming experience, just having agreed to co-write a book about [Functional Programming in Swift](http://www.objc.io/books). Luckily, both Chris and Wouter are deeply familiar with functional programming, so my inexperience in this area actually added a valuable angle onto the subject. After all, the book should be understandable for people like me.


## Getting Started

Like for everybody else, Swift was a big surprise for me when Apple announced it in June. We started writing two weeks after WWDC, so at this time Swift was still very foreign to me.

I immediately liked the strict typing and optionals, at least on a conceptional level. Of course in practice I struggled with both aspects as many other Objective-C developers did as well. However, I always thought that these features were a good idea and that it would be simply a matter of time until I would have internalized them.

It wasn't until I saw the first Swift code snippets from Chris though that I realized the extent of the potential change that Apple had presented us with. Suddenly I was faced with very small amounts of Swift code, neatly packed into small functions, that I had a hard time to understand.

How was that possible?

It reminded me of this university course in Prolog: I was looking at code, but my brain just couldn't recognize any of the familiar patterns.

After a longer talk with Chris I had a somewhat better grasp of some basic concepts, like e.g. [generics](http://en.wikipedia.org/wiki/Generic_programming) and [currying](http://en.wikipedia.org/wiki/Currying). He even tried to explain [Monads](http://en.wikipedia.org/wiki/Monad_%28functional_programming%29) to me, not fully successful I have to admit.

Anyway, it was time to put these newly gained insights into practice: I started working on the chapter about wrapping Core Image with a functional API (which is available as [sample chapter](http://www.objc.io/books), as well as in the form of an [objc.io article](http://www.objc.io/issue-16/functional-swift-apis.html)).

I quickly started to like what I was developing. It felt like a breeze of fresh air to be able to easily work with functions and to define custom types with next to no overhead.


## Jumping into the Deep End

Chris had just finished the first draft of a chapter about a functional approach to parsing, and I took on the task to read through it and see if I could follow. It was really, *really* hard.

I think it took me at least a day before I had a basic grasp on what was happening there. The reason for this was not that the draft was badly written, but that Chris had internalized functional programming concepts since a long time, whereas I had to wrap my head around every single line of code in there.

I started to rewrite some sections and to insert explanations that I had to figure out by myself. During this process the playground of this chapter came in very handy to test my assumptions and to make sure that my changes actually worked.

Next, I started refactoring and extending a sample project — a very simple spreadsheet application — that makes use of the before mentioned parsing library. This was the point at which the power of Swift's type system really started to dawn on me.

My goal was to add correct operator precedence to the formula parser in the spreadsheet app. To make this happen, I had to refactor some of the existing code and I swear that I didn't know what I was doing a lot of the time. And although I often just made a good guess of what had to be changed, I didn't break anything: when the app compiled, it worked.

Swift's strict type checking guided me while flying half blind. I was impressed.


## Status Quo

Even after working on the book over the course of three months, Objective-C still feels way more natural to me than Swift. That's not a big surprise though, as I haven't written any real production code with it yet. (That will change soon!) I've really learned to appreciate the new tools Swift has given me though — I wouldn't want to miss generics, first class functions, enumerations, structs and many other of the new features anymore.


## Get the Book

For more information on the book head over the [Functional Programming in Swift website](http://www.objc.io/books). I really hope that we were able to create a book that introduces functional programming concepts in a gentle way, so that it's easy to follow along for people like me. I also hope that you'll learn to appreciate Swift's new capabilities, even if it's just in theory at first. I'm sure that we'll look back in a couple of years and wonder how we got work done without them.


