---
title: Making AutoLayout code less painful
date: 2013-03-26
---

AutoLayout was introduced on the Mac with OS X Lion (do I remember correctly?) and made its way into iOS with version 6. Many people seem to be not particularly fond of it, but I think it's great. It feels like the correct solution to the problem of laying out user interface elements, especially with changing screen sizes, orientations and support for multiple languages.

I fully agree that the support for layout constraints in Interface builder is less than optimal. But creating constraints in code is actually pretty straightforward. The API is pretty verbose though. Apple created the visual format language to make it more concise. However, the visual format language only covers a subset of the constraints we need to create on a regular basis.

I've created [FLKAutoLayout](https://github.com/floriankugler/FLKAutoLayout) to make constraints in code more readable and to provide convenience methods for several more complex layout scenarios. It's definitely still in its infancy, I have just added the first version 0.1.0 to CocoaPods. Check it out and let me know if you have any suggestions!