# AccessibilityKit ♿️

[![Build Status](https://travis-ci.com/FlickType/AccessibilityKit.svg?branch=master)](https://travis-ci.com/FlickType/AccessibilityKit) ![Carthage](https://img.shields.io/github/tag/FlickType/AccessibilityKit.svg?label=Carthage&colorB=999) [![License: MIT](https://img.shields.io/github/license/FlickType/AccessibilityKit.svg)](https://opensource.org/licenses/MIT) 

> **AccessibilityKit** is a collection of APIs to help you develop more visually accessible apps, for the times when iOS doesn't have you covered.


## AKTextView

`AKTextView` is a text view that _automatically_ and _efficiently_ draws text using the largest possible font size, spanning **multiple lines** as needed to fill the view's bounds. It's great for when you need some text or label to be as visually accessible as possible, or to just generally make it more appealing. It's efficient enough that it can perform real-time resizing, if you ever need to do that.

As a bonus, you can also use all attributes of `NSAttributedString`, as well as a built-in vertical alignment option. And emoji, of course.

## Examples
![Animated example of AKTextView, portrait](/assets/textview-portrait.gif) ![Animated example of AKTextView, landscape](/assets/textview-landscape.gif) ![Animated example of AKTextView](/assets/textview-resize.gif)

## Why?

- `UILabel`'s `adjustsFontSizeToFitWidth` doesn't play nice with multiple lines.
- `UITextView` doesn't have `adjustsFontSizeToFitWidth`.
- Other solutions might render text incorrectly.
- Other solutions don't support attributed strings.
- Other solutions are slow.
- 😠😤😩

## Usage

You can use `AKTextView` as a drop-in replacement for `UITextView` and `NSTextView` (iOS and macOS). There's also `AKLabel` (replacement for `UILabel`), as well as `AKView`, an even more performant and bare-bones subclass of `UIView`.

iOS:
```
let view = AKTextView()

// Use a simple or fancy NSAttributedString.
view.attributedText = .init(string: "Some text here", attributes: [
  .font: UIFont.systemFont(ofSize: 12), // Font size will be ignored
  .foregroundColor: UIColor.black,
])
// Add to the view hierarchy...
```
macOS:
```
let view = AKTextView()
view.string = "Some text here"
// Add to the view hierarchy...
```

# Text-to-speech additions coming soon

_AccessibilityKit is used in the award-winning, low-vision keyboard [FlickType](https://www.flicktype.com)._
