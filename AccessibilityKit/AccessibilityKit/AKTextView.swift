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
  
  @objc
  public var verticalAlignment: VerticalAlignment = .center {
    didSet { setNeedsDisplay(bounds)}
  }
  
  public override init(frame frameRect: NSRect) {
    super.init(frame: frameRect)
    setup()
  }
  
  public override init(frame frameRect: NSRect, textContainer container: NSTextContainer?) {
    super.init(frame: frameRect, textContainer: container)
    setup()
  }
  
  public required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  private func setup() {
    // We want our bounds to remain fixed
    isVerticallyResizable = false
    isHorizontallyResizable = false
    // Remove internal horizontal padding
    textContainer?.lineFragmentPadding = 0
  }
  
  private func resizeFont() {
    var text = string
    if text.isEmpty { text = " " } // To ensure the caret always has an appropriate size
    let attributedText = NSAttributedString(string: text, attributes: [.font: NSFont.systemFont(ofSize: 12)])
    let longestWord = attributedText.longestWord
    let fitSize = NSSize(width: textContainer!.size.width, height: bounds.height - 2 * textContainerInset.height)
    font = NSFont.systemFont(ofSize: AKTextUtilities.maxFontSize(string: attributedText, longestWord: longestWord, fitSize: fitSize))
  }
  
  open override func didChangeText() {
    super.didChangeText()
    resizeFont()
  }
  
  open override func layout() {
    super.layout()
    resizeFont()
  }
  
  open override func draw(_ dirtyRect: NSRect) {

    if verticalAlignment != .top {
      let glyphRange = layoutManager!.glyphRange(for: textContainer!)
      let textRect = layoutManager!.boundingRect(forGlyphRange: glyphRange, in: textContainer!)
      let padding = max(0, bounds.height - textRect.height - 2 * textContainerInset.height)
      let yShift = verticalAlignment == .center ? padding/2 : padding
      NSGraphicsContext.current!.cgContext.translateBy(x: 0, y: yShift)
    }
    
    super.draw(dirtyRect)
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

  public override init(frame: CGRect) {
    super.init(frame: frame)
    contentMode = .redraw
    isOpaque = false
  }
  
  private var longestWord: NSAttributedString!
  private let drawingOptions: NSStringDrawingOptions = [.usesLineFragmentOrigin] // Must use `.usesLineFragmentOrigin`. Other options may also be used.
  
  // TODO: calculate the font size on `layoutSubviews`, and only apply the vertical aligntment here
  open override func draw(_ rect: CGRect) {
    guard longestWord != nil else { return }
    // TODO: For some reason this is not always equal to bounds, as described in the docs. Also oddly enough,
    // the origin on the first call is sometimes fractional, eg (0.0, -0.125) instead of .zero...
    //assert(rect == bounds)
    
    let maxFontSize = AKTextUtilities.maxFontSize(string: attributedText, longestWord: longestWord, fitSize: rect.size) { string, maxWidth in
      AKTextUtilities.sizingFunction1(string: string, maxWidth: maxWidth, options: drawingOptions)
    }
    
    // Re-run to get the actual used boundingRect.
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
  
  public required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}


open class AKLabel: UILabel {
  @objc
  public var verticalAlignment: VerticalAlignment = .center
  
  open override var attributedText: NSAttributedString! {
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
  
  required public init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  open override func layoutSubviews() {
    super.layoutSubviews()
    guard attributedText != nil, attributedText.length > 0 else { return }
    let longestWord = attributedText.longestWord
    super.attributedText = attributedText.withFontSize(AKTextUtilities.maxFontSize(string: attributedText, longestWord: longestWord, fitSize: bounds.size))
  }
  
  open override func draw(_ rect: CGRect) {
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
  
  open override var attributedText: NSAttributedString! {
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
  
  public required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  open override func layoutSubviews() {
    super.layoutSubviews()
    
    guard attributedText != nil, attributedText.length > 0 else { return }
    let longestWord = attributedText.longestWord
    
    // We don't simply use `textContainer.size` because it will have infinite Y size if scrolling is enabled
    let fitSize = UIEdgeInsetsInsetRect(bounds, textContainerInset).size
    let maxFontSize = AKTextUtilities.maxFontSize(string: attributedText, longestWord: longestWord, fitSize: fitSize)
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
