---
title: Layer Trees vs. Flat Drawing – Graphics Performance Across iOS Device Generations
date: 2013-05-24
---

Buttery smooth scroll views are the pride of many iOS developers and the figurehead of great iOS apps. I wasn't developing for the iOS platform in the early days, but from today's perspective it seems to me that Tweetie by [Loren Brichter][1] was one of the first very successful apps which really cultivated the art of squeezing out every bit of graphics performance the devices had to offer. Loren was [very open about his technique][2] to just draw the contents of each cell with Core Graphics as a single bitmap, so that the GPU was able to do what it could do best – pushing around opaque textures.

[1]:https://twitter.com/lorenb
[2]:http://web.archive.org/web/20100922230053/http://blog.atebits.com/2008/12/fast-scrolling-in-tweetie-with-uitableview/

This goes way back to 2008, when the iPhone 3G just had came out and the first generation iPhone was not a device you would have wanted to abandon just now. Also retina screens had not taken the stage yet. More recently the Twitter engineering team published a [post about their techniques][100] to make scroll views really smooth, which equally includes rendering table view cells as flat bitmaps.

[100]:http://engineering.twitter.com/2012/02/simple-strategies-for-smooth-animation.html

Since the first iPhone the capabilities of the device's CPU and GPU have increased dramatically, but new hardware features like retina displays place higher demands on them at the same time. Also on the software side things have changed, e.g. CAGradientLayer was introduced with iOS 3. With these developments in mind, I was curious to what extent the old wisdom of drawing views as flat bitmaps in order to get great performance was still holding up.

In this article I will present the results of a simple benchmark I performed on the iPhone 3G, 4, 4S and 5 as well as the iPad 3, iPad mini and iPad 4. Based on these results I will discuss which strategy will likely yield the best results for different use cases.

## First time rendering & layer animation

Smooth table view scrolling has two ingredients. First you need to be able to bring a new table view cell on screen within 1/60 of a second (that's approximately 16ms, in case of really fast scrolling it might also be more than one cell). Second, you need to be able to move the cells which are already on screen around at 60 frames per second. The first aspect involves the CPU and the GPU to different degrees depending on your code, whereas the second aspect relies mainly on the GPU (if you are not changing cells which are already on screen).

I wanted to test both aspects of graphics performance in an isolated fashion. For this purpose I created a simple app which could render a view like this:

![](/images/test-cell.png)

This view is 100 points in height and spanned the whole display width on the iPhone as well as on the iPad. It consists of an opaque gradient in the background, a 100x100 image on the left and two labels with a transparent background. I created three versions of this view which all produced an identical output.

The first version was constructed with several subviews. One for the gradient, an `UIImageView` for the image and two `UILabel`s for the text. The second version was constructed out of several sublayers. A `CAGradientLayer` for the background gradient, a `CALayer` for the image with its `contents` property set to a `CGImageRef` and two `CATextLayer`s. The last version was drawn as flat texture with Core Graphics.

To test how fast these views could be brought on screen, I measured the time it would take to render 5 to 30 of these views in increments of 5, taking 60 samples during each step. In order to measure how many of these views could be animated at 60 frames per second once they were on screen, I incrementally rendered more and more of these views in my test app until the frame rate dropped below 60fps when animating their position randomly.

## Measuring Technique

You can find the test project I used for these benchmarks on [GitHub][201], so I'm only going to describe the the rough outline here. For both measurements I used [`CADisplayLink`][200] to update the screen. The selector you specify when initializing `CADisplayLink` gets called 60 times per second (if what your doing doesn't take too long) and conveniently the display link object, which you get as first and only argument, has a `timestamp` property which tells you the timestamp associated with the last frame that was displayed.

[200]:http://developer.apple.com/library/ios/#documentation/QuartzCore/Reference/CADisplayLink_ClassRef/Reference/Reference.html
[201]:https://github.com/dkduck/CostOfLayersVsDrawing

To measure how fast new views could be brought on screen I simply removed and re-created the superview which contained a variable number of the test views.

```objc
- (void)setupDisplayLink {
    CADisplayLink* displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(nextFrame:)];
    [displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
}

- (void)nextFrame:(CADisplayLink*)displayLink {
    // ...
    [view removeFromSuperview];
    view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height)];
    for (NSUInteger i = 0; i < numberOfViews; i++) {
        // add new views ...
    }
    [self.view addSubview:view];
}
```

After 60 iterations with a fixed number of views I logged the average time each cycle took, increased the number of views to be displayed by 5 and moved on to the next round.

To measure how fast the views which were already on screen could be animated, the method called by the display link was a bit different:

```objc
- (void)nextFrame:(CADisplayLink*)displayLink {
    // ...
    view.transform = CGAffineTransformMakeTranslation(self.randomNumber * 50 - 25, self.randomNumber * 50 - 25);
}
```

This simply sets a different, random translation transform on the container view with each display cycle. Since setting a transform like this doesn't hinder the display link from calling the method 16ms later, even if the resulting GPU operation takes longer, I measured the actual frame rate with the OpenGL ES Driver instrument and averaged the value over a couple of seconds.

## Performance of first time rendering

### iPhone

The following chart shows the average time it took to render one test view onto the screen on the iPhone 3G, 4, 4S and 5. The three bars in each group represent the different versions of the view: composed of subviews, composed of sublayers and plain Core Graphics drawing.

![](/images/iphone-view-creation-bars.png)

While the time it took to render the views with subviews and sublayers improved with each device generation, we see a huge drop in drawing performance with the iPhone 4. The retina screen results in four times the number of pixels to be drawn. And since drawing with Core Graphics is a CPU task, the improvement in CPU power is not enough to offset the increased demands of this new display generation. The iPhone 5 is the first device which is able beat the iPhone 3GS (!) in terms of Core Graphics drawing performance in this example.

The line charts below show the time each display cycle took for rendering 5 to 30 views for each device. I want to highlight here that the performance advantage on the iPhone 3GS of drawing the view with Core Graphics compared to composing it out of sublayers is quite small. Furthermore you can see that the iPhone 4S is able to render 10 views composed of sublayers at a refresh rate of 60 frames per second, but just 5 composed of subviews, since UIViews are wrappers around CALayers which cause some overhead on the CPU. These numbers increase for the iPhone 5 to 15 and 10 respectively.

![](/images/iphone-view-creation-lines.png)

### iPad

For the iPad the situation is similar to what we saw for the iPhone. However, since the iPad has to drive many more pixels than the iPhone, we even see a performance drop-off  for the non-retina iPad mini (which should be pretty much the same as the iPad 2) when drawing the test view with Core Graphics compared to subview and sublayer compositing.

![](/images/ipad-view-creation-bars.png)

The iPad 3 really stands out in this comparison. It just has abysmally bad drawing performance. The retina display is great, but the hardware was clearly not ready for it yet.


## Performance of animation

Now let's have a look at how the different generations of iPhones and iPads stack up in terms of animation performance, i.e. moving an existing view around on screen. For these tests I will only show the results for the sublayer and Core Graphics view variants, since the view composed out of subviews yields identical results to the one composed out of sublayers.

### iPhone

The following bar chart shows the number of views that could be animated smoothly at 60 frames per second on each device. As expected, in this test the view which is drawn as one flat bitmap outperforms the view composed of several sublayers dramatically (approximately 4:1, 8:1, 7:1 and 7:1 generation by generation), since the GPU only needs to move one opaque texture around per view.

![](/images/iphone-view-animation-bars.png)

However, I also want to point out that even the iPhone 3GS was able to push around 20 of my test views composed out of sublayers at 60 frames per second. That's quite a lot of views for such a small screen.

### iPad

On the iPad the performance gap between animating views which are drawn as a flat bitmap and views which are composited out of sublayers is even greater. The iPad mini has a ratio of approximately 7:1, similar to what we saw for the latest iPhone generations. But the retina iPad 3 has a ratio of 15:1 and the iPad 4 is even more extreme.

![](/images/ipad-view-animation-bars.png)

The bigger screen size of the iPad lends itself to displaying more views at once than on the iPhone, either simply by larger table views or especially when using grid views. This often makes the iPad the much more performance critical device, since its GPU (and even more so its CPU) is not that much more powerful in relation to its screen size compared to the corresponding iPhone generation.


## Conclusions

The performance characteristic of drawing views as a flat bitmap with Core Graphics has changed dramatically with the introduction of the retina screen on the iPhone and the larger screen size of the iPad. Core Graphics drawing is a CPU bound operation, and drawing four times the pixels means more load on the CPU. Furthermore CPU power generally increased in smaller steps between device generations compared to GPU power.

On the iPad and on iPhones with retina screens you will often be better off composing performance sensitive views out of sublayers than drawing them manually with Core Graphics. I have to qualify this statement with two conditions though: First, the view needs to have elements which can be expressed as layers (areas with uniform color, gradients, images). Only then you will see a meaningful difference between both techniques. And second, the GPU still needs to be able to animate the resulting layer tree fluently. This depends on the complexity of the view itself and the number of views which are on screen simultaneously.

If the GPU cannot animate the layer tree at 60 frames per second anymore, then you might benefit from flattening the view's layer hierarchy. But drawing the whole view into one bitmap isn't necessarily the only way to go. You can also experiment with flattening parts of the view by manual drawing while still using layers for e.g. a background gradient and an image. In the example used here we could draw both labels into one layer while keeping the gradient and the image in separate layers. This would reduce the number of layers the GPU has to handle by 25% and still keep the load of rendering the large background area off the CPU. Another option is to try setting `shouldRasterize` on the view's layer to `YES`. In some cases this improves animation performance at a cost of rendering time.

In this example I created the background gradient using `CAGradientLayer` for the subview and sublayer variants and `CGContextDrawLinearGradient` for the flat view. Using an image for the gradient (or prerendering the gradient into a bitmap context) is a little bit faster across the board, but doesn't change the relative performance much between the different view implementations. If you use an image though, it is extremely important that it has the exact size of the view (so that it doesn't have to be scaled) and that @1x and @2x versions are provided. Otherwise performance will be worse than drawing the gradient yourself.

Ultimately you have to profile your particular use case and find the best tradeoff for the devices you want to support. I highly recommend using the `CADisplayLink` technique to test how fast you can bring your views on screen and how often per second you can animate them. This nicely separates these two aspects of graphics performance and gives you much more reliable numbers than just manually scrolling a table view.

The bottom line is that with the introduction of retina screens custom drawing might often not be the best solution anymore and composing views out of sublayers has become a real alternative.

