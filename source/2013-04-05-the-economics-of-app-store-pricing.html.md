---
title: The Economics of App Store Pricing
date: 2013-04-05
---

[Michael Jurewitz][1] recently wrote a [great][2] [series][3] [of][4] [blog][5] [posts][6] about App Store Pricing. You really should read it if you haven't done so yet. Michael makes a great point that understanding demand curves is crucial to understand the effects of your pricing strategy. In this post I will go into a bit more depth about how the law of demand is derived and what this means for real world applications.

[1]: http://jury.me
[2]: http://jury.me/blog/2013/3/31/understanding-app-store-pricing-part-1
[3]: http://jury.me/blog/2013/3/31/understanding-app-store-pricing-part-2
[4]: http://jury.me/blog/2013/3/31/understanding-app-store-pricing-part-3
[5]: http://jury.me/blog/2013/3/31/understanding-app-store-pricing-part-4
[6]: http://jury.me/blog/2013/4/1/understanding-app-store-pricing-part-5-pricing-kaleidoscope


## The Demand Curve

A typical demand curve as you will see it in many textbooks looks something like this:

![](/images/Demand-curve.png)

However, graphs like this can be misleading. They easily create the false impression that we are looking at something mathematical and measurable. However, none of these attributes apply to demand curves. In order to explain why, we have to look at how demand curves are derived.

The laws of supply and demand are actually not made up by bored economists, they are inherent to human action and can be logically derived, independent from empirical evidence. If you have a programming background, doesn't this sound appealing? Let's have a look at the logic behind this.

We start out with the basic axiom that humans act. In the context of economics this means that we employ scarce resources to achieve our ends. Scarcity implies, that once we used a certain resource to attain a particular end,  we cannot employ the same resource anymore to achieve other ends. This is called opportunity costs. Every economic transaction (in fact, every action) has opportunity costs in the form of all the things we forgo to attain an end.

When we enter into an economic transaction we fundamentally express our preference for a particular good or service relative to all available alternatives. The very fact that we engage in this exchange is proof that we value more what we will get than what we have to give up in exchange (at least beforehand, of course this can change in retrospect).

The higher the price of a certain good, the higher are the opportunity costs for entering into this transaction. The number of people who will still buy the good at a higher price (i.e. the people who still value this good higher than all alternatives) can only decrease or stay equal at best. Therefore we know that the demand curve slopes downward with decreasing price. To be more precise, we actually have to draw discrete data points instead of a smooth curve, because both price and quantity are discrete values.

![](/images/Demand-scatter.png)

Unfortunately that's pretty much the extent of what we can say with certainty: The demand for a certain good will be the same or higher at a lower price point, if &ndash; and here comes the catch &ndash; *everything else stays equal*. The law of demand stems from the logical change of opportunity costs when the price of a good changes. That's a "function" with one independent variable. Therefore it is only valid if we can control all other factors. That's what the often forgotten footnote to the laws of supply and demand means: *"ceteris paribus"* &ndash; everything else being equal.

## Ceteris Paribus

The first consequence of the ceteris paribus assumption is that it is impossible to *measure* a demand curve of a certain good. The law of demand is a theoretical concept in our minds whose inherent properties make it impossible to measure it in the real world.  To determine the demand curve for your app you would have to collect sales data from several price points. However, this is impossible to accomplish without violating the assumption of everything else being equal. Even the change in price itself can alter the dynamics of demand in a feed forward fashion by changing the perception of your product.

![](/images/Sales-curve.png)

The second consequence of the ceteris paribus assumption is that the law of demand  only applies as long as we are talking about the *same* good. And since the price-demand relationship is derived from consumer preferences, the definition of *"good"* is fundamentally subjective. A different price tag can change the perception of your product so that it is not perceived as the same good anymore. This means that changing the price of a product can change the demand curve. Thus extrapolating demand from past to future pricing becomes even more difficult.

There are many factors which can change the perceived value of an app and therefore its price-demand relationship: developer reputation, press coverage, position in the various top-lists, getting featured, the price itself... to name just a few. Furthermore, all of them are interrelated.

So, shall we just give up to analyze and to predict sales? Certainly not! This should not discourage you from gaining a better understanding of the price-demand relationship for your products by looking into the data and even doing [basic calculations][8] as Michael Jurewitz has demonstrated in his blog series. But you should always keep the inherent limitations of the law of demand in mind when it comes to quantitative real world applications. This will shield you from feeling too certain about your predictions and jumping to wrong conclusions. It's a qualitative tool, so be careful when applying it quantitatively!

[8]: http://jury.me/blog/2013/4/1/understanding-app-store-pricing-part-5-pricing-kaleidoscope