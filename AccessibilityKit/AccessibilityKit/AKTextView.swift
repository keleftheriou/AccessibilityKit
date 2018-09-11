import UIKit

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
    let font = (attributes(at: 0, effectiveRange: nil)[.font] as? UIFont)?.withSize(fontSize) ?? UIFont.systemFont(ofSize: fontSize)
    result.addAttribute(.font, value: font, range: NSRange(location: 0, length: length))
    return result
  }
}

public enum TextVerticalAlignment {
  case top
  case center
  case bottom
}

public class AKTextView: UIView {
  
  private let minFontSize: CGFloat = 1
  
  // The resulting font size might be smaller than the ideal fit, by up to this amount. For a tighter fit, reduce this value at the cost of performance.
  private let fontSizeAccuracyThreshold: CGFloat = 2
  
  private func roundedFontSize(_ fontSize: CGFloat) -> CGFloat {
    return round(fontSize / fontSizeAccuracyThreshold) * fontSizeAccuracyThreshold
  }
  
  private var longestWord: NSAttributedString!
  
  public var verticalAlignment = TextVerticalAlignment.center {
    didSet { setNeedsDisplay() }
  }
  
  // TODO: use NSTextStorage, and NSLayoutManager for blinking cursor?
  public var attributedText = NSAttributedString() {
    didSet {
      // Ensure we never break a word into multiple lines.
      // Find the longest word in terms of drawing width, and start our font size search with a ceiling size that is guaranteed to render this word in a single line.
      // Assumes that the word is always going to be the longest regardless of how small the final font is (could be off due to hinting, so two long words with very
      // similar sizes might "flip" in terms of which one is longest as the font size gets smaller).
      let (_longestWord, _) = attributedText.components.map { ($0, $0.boundingRect(with: .greatestFiniteSize, context: nil).width) }.max { $0.1 < $1.1 }!
      if _longestWord.length > 0 {
        // All iOS text APIs seem to calculate text bounds incorrectly in some cases, eg italic fonts, resulting in some occasional clipping. Add a space here as a hacky workaround.
        // TODO: only if italics?
        let word = NSMutableAttributedString(attributedString: _longestWord)
        word.append(NSAttributedString(string: " "))
        longestWord = word
      } else {
        longestWord = nil
      }
      setNeedsDisplay()
    }
  }
  
  override public init(frame: CGRect) {
    super.init(frame: frame)
    contentMode = .redraw
    isOpaque = false
  }
  
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
  
  override public func draw(_ rect: CGRect) {
    guard longestWord != nil else { return }
    // TODO: For some reason this is not always equal to bounds, as described in the docs. Also oddly enough,
    // the origin on the first call is sometimes fractional, eg (0.0, -0.125) instead of .zero...
    //assert(rect == bounds)
    
    // First, fit the largest word inside our bounds. Do NOT use .usesLineFragmentOrigin or .usesDeviceMetrics here, or else iOS may decide to break up the word in multiple lines...
    let startingFontSize = roundedFontSize(min(rect.height, rect.width))
    let longestWordFontSize = binarySearch(string: longestWord, minFontSize: minFontSize, maxFontSize: startingFontSize, fitInside: rect.size, canvasSize: .greatestFiniteSize, options: [])
    
    // Now continue searching using the entire text, and restrict to our actual width while checking for height overflow.
    let fontSize = binarySearch(string: attributedText, minFontSize: minFontSize, maxFontSize: longestWordFontSize, fitInside: rect.size, canvasSize: CGSize(width: rect.width, height: .greatestFiniteMagnitude), options: [.usesLineFragmentOrigin])
    
    // Re-run to get the final boundingRect.
    let result = attributedText.withFontSize(fontSize).boundingRect(with: CGSize(width: rect.width, height: .greatestFiniteMagnitude), options: [.usesLineFragmentOrigin], context: nil)
    
    let vShift: CGFloat = {
      switch verticalAlignment {
      case .top: return 0
      case .center: return (rect.height - result.height)/2
      case .bottom: return rect.height - result.height
      }
    }()
    
    let box = CGRect(center: CGPoint(x: rect.center.x, y: result.center.y + vShift), size: CGSize(width: rect.width, height: result.height))
    attributedText.withFontSize(fontSize).draw(with: box, options: [.usesLineFragmentOrigin], context: nil)
  }
  
  required public init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}
