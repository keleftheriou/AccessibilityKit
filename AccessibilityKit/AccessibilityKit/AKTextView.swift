import UIKit

fileprivate class TextUtilities {
  
  fileprivate static func roundedFontSize(_ fontSize: CGFloat, accuracyThreshold: CGFloat) -> CGFloat {
    return round(fontSize / accuracyThreshold) * accuracyThreshold
  }
  
  fileprivate static func binarySearch(string: NSAttributedString, minFontSize: CGFloat, maxFontSize: CGFloat, fitSize: CGSize, options: NSStringDrawingOptions, accuracyThreshold: CGFloat) -> CGFloat {
    let avgSize = roundedFontSize((minFontSize + maxFontSize)/2, accuracyThreshold: accuracyThreshold)
    if avgSize == minFontSize || avgSize == maxFontSize { return minFontSize }
    let singleLine = !options.contains(.usesLineFragmentOrigin)
    let canvasSize = CGSize(width: singleLine ? .greatestFiniteMagnitude : fitSize.width, height: .greatestFiniteMagnitude)
    if fitSize.contains(string.withFontSize(avgSize).boundingRect(with: canvasSize, options: options, context: nil).size) {
      return binarySearch(string: string, minFontSize:avgSize, maxFontSize:maxFontSize, fitSize: fitSize, options: options, accuracyThreshold: accuracyThreshold)
    } else {
      return binarySearch(string: string, minFontSize:minFontSize, maxFontSize:avgSize, fitSize: fitSize, options: options, accuracyThreshold: accuracyThreshold)
    }
  }
  
}

public class AKTextView: UIView {
  
  @objc
  public enum VerticalAlignment : Int {
    case top
    case center
    case bottom
  }
  
  @objc
  public var verticalAlignment: VerticalAlignment = .center {
    didSet { setNeedsDisplay() }
  }
  
  @objc
  public var attributedText = NSAttributedString() {
    didSet {
      defer { setNeedsDisplay() }
      longestWord = nil
      let components = attributedText.components.filter { $0.length > 0 }
      guard !components.isEmpty else { return }
      // Ensure we never break a word into multiple lines.
      // Find the longest word in terms of drawing width, and start our font size search with a ceiling size that is guaranteed to render this word in a single line.

      // NOTE: If we don't specify the same arbitrary font size here, two long words with very similar sizes might "flip" in terms of which one is longest as the font size changes, eg:
      // > ["example", "dynamic"].map { $0.boundingRect(with: .greatestFiniteSize, options: [], attributes: [.font: UIFont.systemFont(ofSize: 100)], context: nil).width }
      // [40.13671875, 40.5029296875] // "dynamic" is always larger, regardless of specified font size, as expected
      // > ["example", "dynamic"].map { $0.boundingRect(with: .greatestFiniteSize, options: [], attributes: [:], context: nil).width }
      // [45.357421875, 44.68359375] // "example" is larger when no font is specified. What font is even used here??
      longestWord = components.map { ($0, $0.withFontSize(50).boundingRect(with: .greatestFiniteSize, options: drawingOptions, context: nil).width) }.max { $0.1 < $1.1 }?.0
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
    maxFontSize = TextUtilities.binarySearch(string: longestWord, minFontSize: minFontSize, maxFontSize: maxFontSize, fitSize: rect.size, options: drawingOptions.subtracting(.usesLineFragmentOrigin), accuracyThreshold: fontSizeAccuracyThreshold)
    
    // Now continue searching using the entire text, and restrict to our actual width while checking for height overflow.
    if attributedText.length > longestWord.length {
      maxFontSize = TextUtilities.binarySearch(string: attributedText, minFontSize: minFontSize, maxFontSize: maxFontSize, fitSize: rect.size, options: drawingOptions, accuracyThreshold: fontSizeAccuracyThreshold)
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


public class AKEditableTextView: UITextView {
  
  private let fontSizeAccuracyThreshold: CGFloat = 0.1
  // NOTE: .usesDeviceMetrics might result in chopped text. Presumably the way UITextView decides to draw does *not* include that option
  private let drawingOptions: NSStringDrawingOptions = [.usesLineFragmentOrigin, .usesFontLeading]
  func roundedFontSize(_ fontSize: CGFloat) -> CGFloat { return TextUtilities.roundedFontSize(fontSize, accuracyThreshold: fontSizeAccuracyThreshold) }
  
  public override var attributedText: NSAttributedString! {
    set {
      // For some reason, if the attributed text does not have a font we may have line spacing / positioning issues
      precondition(newValue.attributes(at: 0, effectiveRange: nil)[.font] != nil)
      super.attributedText = newValue
    }
    get {
      return super.attributedText
    }
  }
  
  public override init(frame: CGRect, textContainer: NSTextContainer?) {
    super.init(frame: frame, textContainer: textContainer)
    
    // Remove the padding top and left of the text view
    self.textContainer.lineFragmentPadding = 0 // horizontal padding
    self.textContainerInset = UIEdgeInsets.zero
    
    isScrollEnabled = false
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  // TODO: To draw strings repeatedly, it is more efficient to use NSLayoutManager, as described in Drawing Strings in Text Layout Programming Guide.
//  func testFunc(rect: CGRect) {
//    let layoutManager = NSLayoutManager()
//    let textContainer = NSTextContainer(size: rect.size)
//    let textStorage = NSTextStorage(attributedString: attributedText)
//    textStorage.addLayoutManager(layoutManager)
//    layoutManager.addTextContainer(textContainer)
//    let glyphRange = layoutManager.glyphRange(for: textContainer)
//    // draw or just get boundingRect
//    layoutManager.drawGlyphs(forGlyphRange: glyphRange, at: rect.origin)
//    layoutManager.boundingRect(forGlyphRange: glyphRange, in: textContainer)
//  }
  
  public override func layoutSubviews() {
    super.layoutSubviews()
    
    let longestWord = attributedText.components.map { ($0, $0.withFontSize(50).boundingRect(with: .greatestFiniteSize, options: drawingOptions, context: nil).width) }.max { $0.1 < $1.1 }?.0

    
    let minFontSize: CGFloat = 1
    var maxFontSize: CGFloat = 500
    maxFontSize = TextUtilities.binarySearch(string: longestWord!,   minFontSize: minFontSize, maxFontSize: maxFontSize, fitSize: textContainer.size, options: drawingOptions.subtracting(.usesLineFragmentOrigin), accuracyThreshold: fontSizeAccuracyThreshold)
    maxFontSize = TextUtilities.binarySearch(string: attributedText, minFontSize: minFontSize, maxFontSize: maxFontSize, fitSize: textContainer.size, options: drawingOptions, accuracyThreshold: fontSizeAccuracyThreshold)
    
    attributedText = attributedText.withFontSize(maxFontSize)
  }
  
}


fileprivate extension CGSize {
  
  static let greatestFiniteSize = CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
  
  func contains(_ size: CGSize) -> Bool {
    return width >= size.width && height >= size.height
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
    let result = NSMutableAttributedString(attributedString: self)
    // TODO: should iterate through all existing font attributes and change their sizes
    let font = (attributes(at: 0, effectiveRange: nil)[.font] as? UIFont)?.withSize(fontSize) ?? UIFont.systemFont(ofSize: fontSize)
    result.addAttribute(.font, value: font, range: NSRange(location: 0, length: length))
    return result
  }
}

