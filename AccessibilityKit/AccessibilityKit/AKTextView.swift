#if os(iOS)
import UIKit
#endif

@objc
public enum VerticalAlignment : Int {
  case top
  case center
  case bottom
}

#if os(macOS)
open class AKTextView: NSTextView {
  
  public override init(frame frameRect: NSRect) {
    super.init(frame: frameRect)
    setup()
  }
  
  public override init(frame frameRect: NSRect, textContainer container: NSTextContainer?) {
    super.init(frame: frameRect, textContainer: container)
    setup()
  }
  
  required public init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  private func setup() {
    // We want our bounds to remain fixed
    isVerticallyResizable = false
    isHorizontallyResizable = false
    // Remove internal horizontal padding
    textContainer?.lineFragmentPadding = 0
    // Remove all padding
    textContainerInset = .zero
  }
  
  private func resizeFont() {
    let fitSize = bounds.size
    let attributedText = NSAttributedString(string: string, attributes: [.font: NSFont.systemFont(ofSize: 12)])
    let longestWord = attributedText.longestWord
    var maxFontSize = AKTextUtilities.roundedFontSize(2 * min(fitSize.height, fitSize.width))
    maxFontSize = AKTextUtilities.binarySearch2(string: longestWord,    maxFontSize: maxFontSize, fitSize: fitSize, singleLine: true)
    maxFontSize = AKTextUtilities.binarySearch2(string: attributedText, maxFontSize: maxFontSize, fitSize: fitSize, singleLine: false)
    font = NSFont.systemFont(ofSize: maxFontSize)
  }
  
  open override func didChangeText() {
    super.didChangeText()
    resizeFont()
  }
  
  open override func layout() {
    super.layout()
    resizeFont()
  }
  
  // TODO: vertical alignment option
}

#else

open class AKView: UIView {
  
  @objc
  public var verticalAlignment: VerticalAlignment = .center {
    didSet { setNeedsDisplay() }
  }
  
  @objc
  public var attributedText = NSAttributedString() {
    didSet {
      precondition(attributedText.hasFontFullySpecified, "You must specify a font for all parts of the string.")
      defer { setNeedsDisplay() }
      longestWord = attributedText.longestWord
    }
  }
  
  ///////////////////////////////////////////////////////////////////////////////////////

  override public init(frame: CGRect) {
    super.init(frame: frame)
    contentMode = .redraw
    isOpaque = false
  }
  
  private var longestWord: NSAttributedString!
  private let drawingOptions: NSStringDrawingOptions = [.usesLineFragmentOrigin]
  
  // TODO: calculate the font size on `layoutSubviews`, and only apply the vertical aligntment here
  override public func draw(_ rect: CGRect) {
    guard longestWord != nil else { return }
    // TODO: For some reason this is not always equal to bounds, as described in the docs. Also oddly enough,
    // the origin on the first call is sometimes fractional, eg (0.0, -0.125) instead of .zero...
    //assert(rect == bounds)
    
    // Ensure we never break a word into multiple lines.
    // First, fit the largest word inside our bounds. Do NOT use .usesLineFragmentOrigin or .usesDeviceMetrics here, or else iOS may decide to break up the word in multiple lines...
    var maxFontSize = AKTextUtilities.roundedFontSize(2 * min(rect.height, rect.width))
    maxFontSize = AKTextUtilities.binarySearch1(string: longestWord, maxFontSize: maxFontSize, fitSize: rect.size, options: drawingOptions.subtracting(.usesLineFragmentOrigin))
    
    // Now continue searching using the entire text, and restrict to our actual width while checking for height overflow.
    if attributedText.length > longestWord.length {
      maxFontSize = AKTextUtilities.binarySearch1(string: attributedText, maxFontSize: maxFontSize, fitSize: rect.size, options: drawingOptions)
    }
    
    // Re-run to get the final boundingRect.
    let result = attributedText.withFontSize(maxFontSize).boundingRect(with: CGSize(width: rect.width, height: .greatestFiniteMagnitude), options: drawingOptions, context: nil)
    
    let vShift: CGFloat = {
      switch verticalAlignment {
      case .top: return 0
      case .center: return (rect.height - result.height)/2
      case .bottom: return rect.height - result.height
      }
    }()
    
    let box = CGRect(center: CGPoint(x: rect.center.x, y: result.center.y + vShift), size: CGSize(width: rect.width, height: result.height))
    attributedText.withFontSize(maxFontSize).draw(with: box, options: drawingOptions, context: nil)
  }
  
  required public init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}


open class AKLabel: UILabel {
  @objc
  public var verticalAlignment: VerticalAlignment = .center
  
  public override var attributedText: NSAttributedString! {
    set {
      precondition(newValue.hasFontFullySpecified, "You must specify a font for all parts of the string.")
      super.attributedText = newValue
      setNeedsLayout()
    }
    get {
      return super.attributedText
    }
  }
  
  public override init(frame: CGRect) {
    super.init(frame: frame)
    numberOfLines = 0
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  public override func layoutSubviews() {
    super.layoutSubviews()
    
    guard attributedText != nil, attributedText.length > 0 else { return }
    let longestWord = attributedText.longestWord
    
    let fitSize = bounds.size    
    var maxFontSize = AKTextUtilities.roundedFontSize(2 * min(fitSize.height, fitSize.width))
    maxFontSize = AKTextUtilities.binarySearch2(string: longestWord,    maxFontSize: maxFontSize, fitSize: fitSize, singleLine: true)
    maxFontSize = AKTextUtilities.binarySearch2(string: attributedText, maxFontSize: maxFontSize, fitSize: fitSize, singleLine: false)
    
    super.attributedText = attributedText.withFontSize(maxFontSize)
  }
  
  public override func draw(_ rect: CGRect) {
    if verticalAlignment != .center {
      let textRect = attributedText.boundingRect(with: bounds.size, options: .usesLineFragmentOrigin, context: nil)
      let padding = max(0, rect.height - textRect.height)
      let yShift = verticalAlignment == .top ? -padding/2 : padding/2
      UIGraphicsGetCurrentContext()!.translateBy(x: 0, y: yShift)
    }
    super.draw(rect)
  }
  
}


open class AKTextView: UITextView {
  
  @objc
  public var verticalAlignment: VerticalAlignment = .center
  
  public override var attributedText: NSAttributedString! {
    set {
      precondition(newValue.hasFontFullySpecified, "You must specify a font for all parts of the string.")
      super.attributedText = newValue
      setNeedsLayout()
    }
    get {
      return super.attributedText
    }
  }
  
  public override init(frame: CGRect, textContainer: NSTextContainer?) {
    super.init(frame: frame, textContainer: textContainer)
    isScrollEnabled = false
    // Remove internal horizontal padding
    self.textContainer.lineFragmentPadding = 0
    // Remove all padding
    self.textContainerInset = .zero
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  public override func layoutSubviews() {
    super.layoutSubviews()
    
    guard attributedText != nil, attributedText.length > 0 else { return }
    let longestWord = attributedText.longestWord
    
    // We don't simply use `textContainer.size` because it will have infinite Y size if scrolling is enabled
    let fitSize = UIEdgeInsetsInsetRect(bounds, textContainerInset).size
    var maxFontSize = AKTextUtilities.roundedFontSize(2 * min(fitSize.height, fitSize.width))
    maxFontSize = AKTextUtilities.binarySearch2(string: longestWord,    maxFontSize: maxFontSize, fitSize: fitSize, singleLine: true)
    maxFontSize = AKTextUtilities.binarySearch2(string: attributedText, maxFontSize: maxFontSize, fitSize: fitSize, singleLine: false)
    
    // NOTE: `UITextView` seems to *not* use the .usesDeviceMetrics drawing option of the `boundingRect` functions
    super.attributedText = attributedText.withFontSize(maxFontSize)
    
    // Check that all glyphs fit inside our textContainer
    let glyphRange = layoutManager.glyphRange(for: textContainer)
    assert(glyphRange.location == 0 && glyphRange.length == layoutManager.numberOfGlyphs)
    
    // We are all set, unless we want to vertically align center or bottom
    guard verticalAlignment != .top else { return }
    
    // Both of these return the same height, but different width. Not sure why.
    //let textRect = attributedText.boundingRect(with: fitSize, options: drawingOptions, context: nil)
    let textRect = layoutManager.boundingRect(forGlyphRange: glyphRange, in: textContainer)
    let padding = max(0, fitSize.height - textRect.height)
    let yShift = verticalAlignment == .center ? padding/2 : padding
    // The first view is a _UITextContainerView
    subviews.first?.transform = CGAffineTransform(translationX: 0, y: yShift)
  }
  
}

#endif // os(iOS)
