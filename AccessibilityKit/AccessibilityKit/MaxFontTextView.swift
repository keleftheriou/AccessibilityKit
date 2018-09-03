import UIKit

fileprivate extension CGSize {
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

public class MaxFontTextView: UIView {
  
  let maxFontSize: CGFloat = 500
  let minFontSize: CGFloat = 12
  
  private var lastBoundsUsed: CGRect!
  private var lastFontSizeUsed: CGFloat!
  private var lastAttributedText: NSAttributedString!
  
  // TODO: use NSTextStorage, and NSLayoutManager for blinking cursor?
  public var attributedText = NSAttributedString() {
    didSet { setNeedsDisplay() }
  }
  
  override public init(frame: CGRect) {
    super.init(frame: frame)
    contentMode = .redraw
  }
  
  override public func draw(_ rect: CGRect) {
    // TODO: For some reason this is not always equal to bounds, as described in the docs. Also oddly enough,
    // the origin on the first call is sometimes fractional, eg (0.0, -0.125) instead of .zero...
    //assert(rect == bounds)
    (backgroundColor ?? .black).setFill()
    UIRectFill(rect)

    // Ensure we never break a word into multiple lines.
    // Find the longest word in terms of drawing width, and start our font size search with a ceiling size that is guaranteed to render this word in a single line.
    // Assumes that the word is always going to be the longest regardless of how small the final font is (could be off due to hinting, so two long words with very
    // similar sizes might "flip" in terms of which one is longest as the font size gets smaller).
    let relativeWordWidths = attributedText.components.map { ($0, $0.boundingRect(with: CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude), context: nil).width) }
    let (_longestWord, longestWordWidth) = relativeWordWidths.max { $0.1 < $1.1 }!
    guard longestWordWidth > 0 else { return } // whitespace was "longest"
    
    // All iOS text APIs seem to calculate text bounds incorrectly in some cases, eg italic fonts, resulting in some occasional clipping. Add a space here as a hacky workaround.
    // TODO: only if italics?
    let longestWord = NSMutableAttributedString(attributedString: _longestWord)
    longestWord.append(NSAttributedString(string: " "))

    var fontSize: CGFloat = maxFontSize
    
    // Optimization: start the "search" from the previously known used value, if the string is the same (eg the cursor color changed)
    if lastAttributedText != nil && attributedText.string == lastAttributedText.string && bounds == lastBoundsUsed {
      fontSize = lastFontSizeUsed
    }
    
    repeat {
      // Do NOT use .usesLineFragmentOrigin or .usesDeviceMetrics here, or else iOS may decide to break up the word in multiple lines...
      let result = longestWord.withFontSize(fontSize).boundingRect(with: CGSize(width: .greatestFiniteMagnitude, height: rect.height), options: [], context: nil)
      if rect.size.contains(result.size) { break }
      fontSize -= 2
    } while fontSize > minFontSize
    
    var result: CGRect
    repeat {
      result = attributedText.withFontSize(fontSize).boundingRect(with: CGSize(width: rect.width, height: .greatestFiniteMagnitude), options: [.usesLineFragmentOrigin], context: nil)
      if rect.size.contains(result.size) { break }
      fontSize -= 2
    } while fontSize > minFontSize

    attributedText.withFontSize(fontSize).draw(with: CGRect(center: rect.center, size: result.size), options: [.usesLineFragmentOrigin], context: nil)
    
    lastAttributedText = attributedText
    lastFontSizeUsed = fontSize
    lastBoundsUsed = bounds
  }
  
  required public init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}
