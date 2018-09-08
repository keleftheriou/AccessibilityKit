# AccessibilityKit ♿️

## AKTextView

AKTextView is a text view that **automatically** uses the largest possible font size, spanning **multiple lines** as needed. It's great for when you need some text or label to be as visually accessible as possible, or just generally more appealing.

You can also use all attributes of `NSAttributableString`, as well as a built-in vertical alignment option. Text is **efficiently** rendered as large as possible, within the bounds of the view.

## Examples
![Animated example of AKTextView, portrait](/assets/textview-portrait.gif) ![Animated example of AKTextView, landscape](/assets/textview-landscape.gif)

## Why?

- `UILabel`'s `adjustsFontSizeToFitWidth` doesn't play nice with multiple lines.
- `UITextView` doesn't have `adjustsFontSizeToFitWidth`.
- Other solutions might render text incorrectly.
- Other solutions don't support attributable strings.
- Other solutions are slow.
- 😠😤😩

## Usage

```
let view = AKTextView()

// Use a simple or fancy NSAttributableString
view.attributedText = .init(string: "Some text here", attributes: [.foregroundColor: UIColor.black])

// Optionally set the vertical alignment to top, center or bottom.
view.verticalAlignment = .center // default
```

## That's it! 👏

AccessibilityKit is used in the award-winning, low-vision keyboard [FlickType](https://www.flicktype.com).
