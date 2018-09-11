import UIKit

public class AKTextView: UIView {
  
  public enum VerticalAlignment {
    case top
    case center
    case bottom
  }
  
  public var verticalAlignment: VerticalAlignment = .center {
    didSet { setNeedsDisplay() }
  }
  
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
      longestWord = components.map { ($0, $0.withFontSize(50).boundingRect(with: .greatestFiniteSize, options: drawingOptions.subtracting(.usesLineFragmentOrigin), context: nil).width) }.max { $0.1 < $1.1 }?.0
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
    return round(fontSize / fontSizeAccuracyThreshold) * fontSizeAccuracyThreshold
  }
  
  private var longestWord: NSAttributedString!
  private let drawingOptions: NSStringDrawingOptions = [.usesLineFragmentOrigin]
  
  
  private func binarySearch(string: NSAttributedString, minFontSize: CGFloat, maxFontSize: CGFloat, fitInside: CGSize, canvasSize: CGSize, options: NSStringDrawingOptions) -> CGFloat {
    let avgSize = roundedFontSize((minFontSize + maxFontSize) / 2)
    if avgSize == minFontSize || avgSize == maxFontSize { return minFontSize }
    let result = string.withFontSize(avgSize).boundingRect(with: canvasSize, options: options, context: nil)
    if fitInside.contains(result.size) {
      return binarySearch(string: string, minFontSize:avgSize, maxFontSize:maxFontSize, fitInside: fitInside, canvasSize:canvasSize, options: options)
    } else {
      return binarySearch(string: string, minFontSize:minFontSize, maxFontSize:avgSize, fitInside: fitInside, canvasSize:canvasSize, options: options)
    }
  }
  
  // TODO: To draw strings repeatedly, it is more efficient to use NSLayoutManager, as described in Drawing Strings in Text Layout Programming Guide.
  // NSTextContainer *textContainer = [[NSTextContainer alloc] initWithSize:CGSizeMake(width, CGFLOAT_MAX)];
  // NSLayoutManager *layoutManager = [[NSLayoutManager alloc] init];
  // [layoutManager addTextContainer:textContainer];
  // NSTextStorage *textStorage = [[NSTextStorage alloc] initWithAttributedString:formattedString];
  // [textStorage addLayoutManager:layoutManager];
  // CGRect rect = [layoutManager usedRectForTextContainer:textContainer];
  // CGRect rect = [layoutManager boundingRectForGlyphRange:NSMakeRange(0, [[self textStorage] length]) inTextContainer:textContainer];
  
  override public func draw(_ rect: CGRect) {
    guard longestWord != nil else { return }
    // TODO: For some reason this is not always equal to bounds, as described in the docs. Also oddly enough,
    // the origin on the first call is sometimes fractional, eg (0.0, -0.125) instead of .zero...
    //assert(rect == bounds)
    
    // First, fit the largest word inside our bounds. Do NOT use .usesLineFragmentOrigin or .usesDeviceMetrics here, or else iOS may decide to break up the word in multiple lines...
    var maxFontSize = roundedFontSize(2 * min(rect.height, rect.width))
    maxFontSize = binarySearch(string: longestWord, minFontSize: minFontSize, maxFontSize: maxFontSize, fitInside: rect.size, canvasSize: .greatestFiniteSize, options: drawingOptions.subtracting(.usesLineFragmentOrigin))
    
    // Now continue searching using the entire text, and restrict to our actual width while checking for height overflow.
    if attributedText.length > longestWord.length {
      maxFontSize = binarySearch(string: attributedText, minFontSize: minFontSize, maxFontSize: maxFontSize, fitInside: rect.size, canvasSize: CGSize(width: rect.width, height: .greatestFiniteMagnitude), options: drawingOptions)
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

