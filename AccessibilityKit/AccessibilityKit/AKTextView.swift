import UIKit

fileprivate class TextUtilities {
  
  fileprivate static func roundedFontSize(_ fontSize: CGFloat, accuracyThreshold: CGFloat) -> CGFloat {
    return round(fontSize / accuracyThreshold) * accuracyThreshold
  }
  
  private static func _binarySearch1(string: NSAttributedString, minFontSize: CGFloat, maxFontSize: CGFloat, fitSize: CGSize, options: NSStringDrawingOptions, accuracyThreshold: CGFloat) -> CGFloat {
    return binarySearch(string: string, minFontSize: minFontSize, maxFontSize: maxFontSize, fitSize: fitSize, accuracyThreshold: accuracyThreshold) { string in
      let singleLine = !options.contains(.usesLineFragmentOrigin)
      let canvasSize = CGSize(width: singleLine ? .greatestFiniteMagnitude : fitSize.width, height: .greatestFiniteMagnitude)
      return string.boundingRect(with: canvasSize, options: options, context: nil).size
    }
  }
  
  private static func _binarySearch2(string: NSAttributedString, minFontSize: CGFloat, maxFontSize: CGFloat, fitSize: CGSize, singleLine: Bool, accuracyThreshold: CGFloat) -> CGFloat {
    return binarySearch(string: string, minFontSize: minFontSize, maxFontSize: maxFontSize, fitSize: fitSize, accuracyThreshold: accuracyThreshold) { string in
      let layoutManager = NSLayoutManager()
      let textContainer = NSTextContainer(size: CGSize(width: singleLine ? .greatestFiniteMagnitude : fitSize.width, height: .greatestFiniteMagnitude))
      textContainer.lineFragmentPadding = 0
      let textStorage = NSTextStorage(attributedString: string)
      textStorage.addLayoutManager(layoutManager)
      layoutManager.addTextContainer(textContainer)
      let glyphRange = layoutManager.glyphRange(for: textContainer)
      return layoutManager.boundingRect(forGlyphRange: glyphRange, in: textContainer).size
    }
  }
  
  private static func binarySearch(string: NSAttributedString, minFontSize: CGFloat, maxFontSize: CGFloat, fitSize: CGSize, accuracyThreshold: CGFloat, sizingFunction: (NSAttributedString) -> CGSize) -> CGFloat {
    let avgSize = roundedFontSize((minFontSize + maxFontSize)/2, accuracyThreshold: accuracyThreshold)
    if avgSize == minFontSize || avgSize == maxFontSize { return minFontSize }
    if fitSize.contains(sizingFunction(string.withFontSize(avgSize))) {
      return binarySearch(string: string, minFontSize:avgSize, maxFontSize:maxFontSize, fitSize: fitSize, accuracyThreshold: accuracyThreshold, sizingFunction: sizingFunction)
    } else {
      return binarySearch(string: string, minFontSize:minFontSize, maxFontSize:avgSize, fitSize: fitSize, accuracyThreshold: accuracyThreshold, sizingFunction: sizingFunction)
    }
  }
  
  
  // From the docs: "The `boundingRect` methods return fractional sizes; to use a returned size to size views, you must raise its value to the nearest higher integer using the ceil function."
  fileprivate static func binarySearch1(string: NSAttributedString, minFontSize: CGFloat, maxFontSize: CGFloat, fitSize: CGSize, options: NSStringDrawingOptions, accuracyThreshold: CGFloat) -> CGFloat {
    return _binarySearch1(string: string, minFontSize: minFontSize, maxFontSize: maxFontSize, fitSize:fitSize.floored, options: options, accuracyThreshold: accuracyThreshold)
  }
  
  // From the docs: "The `boundingRect` methods return fractional sizes; to use a returned size to size views, you must raise its value to the nearest higher integer using the ceil function."
  fileprivate static func binarySearch2(string: NSAttributedString, minFontSize: CGFloat, maxFontSize: CGFloat, fitSize: CGSize, singleLine: Bool, accuracyThreshold: CGFloat) -> CGFloat {
    return _binarySearch2(string:string, minFontSize:minFontSize, maxFontSize:maxFontSize, fitSize:fitSize.floored, singleLine:singleLine, accuracyThreshold:accuracyThreshold)
  }
  
}

@objc
public enum VerticalAlignment : Int {
  case top
  case center
  case bottom
}

public class AKLabel: UIView {
  
  @objc
  public var verticalAlignment: VerticalAlignment = .center {
    didSet { setNeedsDisplay() }
  }
  
  @objc
  public var attributedText = NSAttributedString() {
    didSet {
      precondition(attributedText.hasFontFullySpecified, "You must specify a font for all parts of the string.")
      defer { setNeedsDisplay() }
      longestWord = nil
      let components = attributedText.components.filter { $0.length > 0 }
      guard !components.isEmpty else { return }
      // Ensure we never break a word into multiple lines.
      // Find the longest word in terms of drawing width, and start our font size search with a ceiling size that is guaranteed to render this word in a single line.
      longestWord = components.map { ($0, $0.boundingRect(with: .greatestFiniteSize, options: drawingOptions, context: nil).width) }.max { $0.1 < $1.1 }?.0
      // TODO: Some iOS text APIs seem to calculate text bounds incorrectly in some cases, eg italic fonts, resulting in some occasional clipping. Add a space here as a hacky workaround?
    }
  }
  
  ///////////////////////////////////////////////////////////////////////////////////////

  override public init(frame: CGRect) {
    super.init(frame: frame)
    contentMode = .redraw
    isOpaque = false
  }
  
  private let minFontSize: CGFloat = 1
  
  // The resulting font size might be smaller than the ideal fit, by up to this amount. For a tighter fit, reduce this value at the cost of performance.
  // Must be greater than zero. Anything lower than 0.1 is probably unnecessary.
  private let fontSizeAccuracyThreshold: CGFloat = 1.0
  
  private func roundedFontSize(_ fontSize: CGFloat) -> CGFloat {
    return TextUtilities.roundedFontSize(fontSize, accuracyThreshold: fontSizeAccuracyThreshold)
  }
  
  private var longestWord: NSAttributedString!
  private let drawingOptions: NSStringDrawingOptions = [.usesLineFragmentOrigin]
  
  override public func draw(_ rect: CGRect) {
    guard longestWord != nil else { return }
    // TODO: For some reason this is not always equal to bounds, as described in the docs. Also oddly enough,
    // the origin on the first call is sometimes fractional, eg (0.0, -0.125) instead of .zero...
    //assert(rect == bounds)
    
    // First, fit the largest word inside our bounds. Do NOT use .usesLineFragmentOrigin or .usesDeviceMetrics here, or else iOS may decide to break up the word in multiple lines...
    var maxFontSize = roundedFontSize(2 * min(rect.height, rect.width))
    maxFontSize = TextUtilities.binarySearch1(string: longestWord, minFontSize: minFontSize, maxFontSize: maxFontSize, fitSize: rect.size, options: drawingOptions.subtracting(.usesLineFragmentOrigin), accuracyThreshold: fontSizeAccuracyThreshold)
    
    // Now continue searching using the entire text, and restrict to our actual width while checking for height overflow.
    if attributedText.length > longestWord.length {
      maxFontSize = TextUtilities.binarySearch1(string: attributedText, minFontSize: minFontSize, maxFontSize: maxFontSize, fitSize: rect.size, options: drawingOptions, accuracyThreshold: fontSizeAccuracyThreshold)
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


public class AKTextView: UITextView {
  
  @objc
  public var verticalAlignment: VerticalAlignment = .center
  
  private let minFontSize: CGFloat = 1
  private let fontSizeAccuracyThreshold: CGFloat = 1.0
  private let drawingOptions: NSStringDrawingOptions = [.usesLineFragmentOrigin, .usesFontLeading]
  func roundedFontSize(_ fontSize: CGFloat) -> CGFloat { return TextUtilities.roundedFontSize(fontSize, accuracyThreshold: fontSizeAccuracyThreshold) }
  
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
    
    // Remove internal horizontal padding
    self.textContainer.lineFragmentPadding = 0
    
    isScrollEnabled = false
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  
  public override func layoutSubviews() {
    super.layoutSubviews()
    
    guard attributedText != nil, attributedText.length > 0 else { return }
    let longestWord = attributedText.components.map { ($0, $0.withFontSize(50).boundingRect(with: .greatestFiniteSize, options: drawingOptions, context: nil).width) }.max { $0.1 < $1.1 }?.0
    
    // We don't simply use `textContainer.size` because it will have infinite Y size if scrolling is enabled
    let fitSize = UIEdgeInsetsInsetRect(bounds, textContainerInset).size
    var maxFontSize = roundedFontSize(2 * min(fitSize.height, fitSize.width))

    maxFontSize = TextUtilities.binarySearch2(string: longestWord!,   minFontSize: minFontSize, maxFontSize: maxFontSize, fitSize: fitSize, singleLine: true,  accuracyThreshold: fontSizeAccuracyThreshold)
    maxFontSize = TextUtilities.binarySearch2(string: attributedText, minFontSize: minFontSize, maxFontSize: maxFontSize, fitSize: fitSize, singleLine: false, accuracyThreshold: fontSizeAccuracyThreshold)

    // NOTE: `UITextView` seems to *not* use the .usesDeviceMetrics drawing option of the `boundingRect` functions
    super.attributedText = attributedText.withFontSize(maxFontSize)
    
    // Check that all glyphs fit inside our textContainer
    let glyphRange = layoutManager.glyphRange(for: textContainer)
    assert(glyphRange.location == 0 && glyphRange.length == layoutManager.numberOfGlyphs)
    
    // We are all set, unless we want to vertically align center or bottom
    guard verticalAlignment != .top else { return }
    
    // Both of these return the same height, but different width. Not sure why.
    //let textRect = attributedText.boundingRect(with: fitSize, options: drawingOptions, context: nil)
    let textRect = layoutManager.boundingRect(forGlyphRange: layoutManager.glyphRange(for: textContainer), in: textContainer)
    let padding = max(0, fitSize.height - textRect.height)
    let yShift = verticalAlignment == .center ? padding/2 : padding
    // The first view is a _UITextContainerView
    subviews.first?.transform = CGAffineTransform(translationX: 0, y: yShift)
  }
  
}


fileprivate extension CGSize {
  
  static let greatestFiniteSize = CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
  
  func contains(_ size: CGSize) -> Bool {
    return width >= size.width && height >= size.height
  }
  var floored: CGSize {
    return CGSize(width: floor(width), height: floor(height))
  }
}

fileprivate extension CGRect {
  
  init(center: CGPoint, size: CGSize) {
    let origin = CGPoint(x:center.x - 0.5 * size.width, y:center.y - 0.5 * size.height)
    self.init(origin: origin, size: size)
  }
  
  var center: CGPoint {
    return CGPoint(x: origin.x + 0.5 * size.width, y: origin.y + 0.5 * size.height)
  }
}

fileprivate extension String {
  func rangesOfCharacters(from characterSet: CharacterSet) -> [NSRange] {
    var ranges = [Range<String.Index>]()
    var position = startIndex
    while let range = rangeOfCharacter(from: characterSet, range: position..<endIndex) {
      ranges += [range]
      guard let newPosition = index(range.upperBound, offsetBy: 1, limitedBy: endIndex) else { break }
      position = newPosition
    }
    return ranges.map { NSRange($0, in: self) }
  }
}

fileprivate extension NSAttributedString {
  
  var components: [NSAttributedString] {
    var result = [NSAttributedString]()
    var lastPosition = 0
    string.rangesOfCharacters(from: .whitespacesAndNewlines).forEach { skipRange in
      let range = NSRange(location: lastPosition, length: skipRange.location - lastPosition)
      result += [attributedSubstring(from: range)]
      lastPosition = skipRange.upperBound
    }
    result += [attributedSubstring(from: NSRange(location: lastPosition, length: length - lastPosition))]
    return result
  }
  
  func withFontSize(_ fontSize: CGFloat) -> NSAttributedString {
    guard length > 0 else { return self }
    let result = NSMutableAttributedString(attributedString: self)
    result.enumerateAttribute(.font, in: NSRange(location: 0, length: result.length), options: []) { value, range, stop in
      guard let value = value else { preconditionFailure("String must have a font set in all locations.") }
      let oldFont: UIFont = value as! UIFont
      let newFont: UIFont = oldFont.withSize(fontSize)
      result.removeAttribute(.font, range: range)
      result.addAttribute(.font, value: newFont, range: range)
    }
    
    // Fix for emoji
    // https://stackoverflow.com/questions/40914624/what-is-the-nsoriginalfont-attribute-in-nsattributedstring
    result.removeAttribute(NSAttributedStringKey(rawValue: "NSOriginalFont"), range: NSMakeRange(0, result.length))
    return result
  }
  
  // For some reason, if the attributed text does not have a font we may have line spacing / positioning issues.
  // Additionally, without a specified font, the "longest word" calculation" can fail: two long words with very similar sizes might "flip" in terms of which one is longest as the font size changes, eg:
  // > ["example", "dynamic"].map { $0.boundingRect(with: .greatestFiniteSize, options: [], attributes: [.font: UIFont.systemFont(ofSize: 100)], context: nil).width }
  // [40.13671875, 40.5029296875] // "dynamic" is always larger, regardless of specified font size, as expected
  // > ["example", "dynamic"].map { $0.boundingRect(with: .greatestFiniteSize, options: [], attributes: [:], context: nil).width }
  // [45.357421875, 44.68359375] // "example" is larger when no font is specified. What font is even used here??
  var hasFontFullySpecified: Bool {
    var result = true
    self.enumerateAttribute(.font, in: NSRange(location: 0, length: length), options: []) { value, range, stop in
      if value == nil {
        result = false
        stop.pointee = true
      }
    }
    return result
  }
}

