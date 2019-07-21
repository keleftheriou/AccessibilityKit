//
//  AKTextUtilities.swift
//  AccessibilityKit
//
//  Created by Kosta Eleftheriou on 9/15/18.
//  Copyright © 2018 Kpaw. All rights reserved.
//

import Foundation
#if os(iOS) || os (watchOS)
import UIKit
typealias AKStringDrawingOptions = NSStringDrawingOptions
#else
typealias AKStringDrawingOptions = NSString.DrawingOptions
#endif

class AKTextUtilities {
  
  typealias SizingFunction = (_ string: NSAttributedString, _ maxWidth: CGFloat) -> CGSize
  
  // The resulting font size might be smaller than the ideal fit, by up to this amount. For a tighter fit, reduce this value at the cost of performance.
  // Must be greater than zero. Anything lower than 0.1 is probably unnecessary.
  private static let accuracyThreshold: CGFloat = 1.0
  
  // We always use rounded font sizes to allow the OS to use glyph size caching, if available
  private static func roundedFontSize(_ fontSize: CGFloat) -> CGFloat {
    return round(fontSize / accuracyThreshold) * accuracyThreshold
  }
  
  private static func binarySearch(string: NSAttributedString, minFontSize: CGFloat = 0, maxFontSize: CGFloat, fitSize: CGSize, singleLine: Bool, sizingFunction: SizingFunction) -> CGFloat {
    if maxFontSize - minFontSize < accuracyThreshold { return roundedFontSize(minFontSize) }
    let midFontSize = (minFontSize + maxFontSize)/2
    let newSize = sizingFunction(string.withFontSize(roundedFontSize(midFontSize)), singleLine ? .greatestFiniteMagnitude : fitSize.width)
    let fits = fitSize.contains(newSize)
    if debugLogging { print("binarySearch(\(string.length), \(minFontSize), \(maxFontSize), \(fitSize)): font \(midFontSize) newSize \(newSize), fits: \(fits)") }
    if fits {
      return binarySearch(string: string, minFontSize:midFontSize, maxFontSize:maxFontSize, fitSize: fitSize, singleLine: singleLine, sizingFunction: sizingFunction)
    } else {
      return binarySearch(string: string, minFontSize:minFontSize, maxFontSize:midFontSize, fitSize: fitSize, singleLine: singleLine, sizingFunction: sizingFunction)
    }
  }
  
  // TODO: build a few per-fitSize caches
  static func maxFontSize(string: NSAttributedString, longestWord: NSAttributedString, fitSize _fitSize: CGSize, sizingFunction: SizingFunction) -> CGFloat {
    let startTime = CFAbsoluteTimeGetCurrent()
    defer { postInvocationHandler(startTime) }
    // From the docs: "The `boundingRect` methods return fractional sizes; to use a returned size to size views, you must raise its value to the nearest higher integer using the ceil function."
    let fitSize = _fitSize.floored
    // Ensure we never break a word into multiple lines.
    // Start with a good heuristic
    var maxFontSize = 2 * min(fitSize.height, fitSize.width)
    // First, fit the largest word inside our bounds.
    maxFontSize = binarySearch(string: longestWord, maxFontSize: maxFontSize, fitSize: fitSize, singleLine: true, sizingFunction: sizingFunction)
    // If the entire string was that word, we are all set
    guard string.length > longestWord.length else { return maxFontSize }

    // If the entire string fits using the current `maxFontSize`, use that and avoid further searching
    if fitSize.contains(sizingFunction(string.withFontSize(maxFontSize), fitSize.width)) { return maxFontSize }
    
    // Continue searching downwards using the entire text, starting from our previous `maxFontSize`
    return binarySearch(string: string, maxFontSize: maxFontSize, fitSize: fitSize, singleLine: false, sizingFunction: sizingFunction)
  }
  
}

extension AKTextUtilities {

  // TODO: Some iOS text APIs seem to calculate text bounds incorrectly in some cases, eg italic fonts, resulting in some occasional clipping?

  static func sizingFunction1(string: NSAttributedString, maxWidth: CGFloat, options: AKStringDrawingOptions) -> CGSize {
    return string.boundingRect(with: CGSize(width: maxWidth, height: .greatestFiniteMagnitude), options: options, context: nil).size
  }
  
  #if !os(watchOS)
  static func sizingFunction2(string: NSAttributedString, maxWidth: CGFloat) -> CGSize {
    let layoutManager = NSLayoutManager()
    let textContainer = NSTextContainer(size: CGSize(width: maxWidth, height: .greatestFiniteMagnitude))
    textContainer.lineFragmentPadding = 0
    let textStorage = NSTextStorage(attributedString: string)
    textStorage.addLayoutManager(layoutManager)
    layoutManager.addTextContainer(textContainer)
    let glyphRange = layoutManager.glyphRange(for: textContainer)
    // Check that all glyphs fit inside our textContainer
    assert(glyphRange.location == 0 && glyphRange.length == layoutManager.numberOfGlyphs)
    return layoutManager.boundingRect(forGlyphRange: glyphRange, in: textContainer).size
  }
  #endif

}

extension AKTextUtilities {
  
  private static let debugLogging = false
  private static var totalTime = 0.0
  private static var totalSearches = 0
  private static func postInvocationHandler(_ startTime: TimeInterval) {
    let dt = CFAbsoluteTimeGetCurrent() - startTime
    totalTime += dt
    totalSearches += 1
    if debugLogging { print("Average font search time: \(totalTime / Double(totalSearches))") }
  }
  
}

extension CGSize {
  
  public static let greatestFiniteSize = CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
  
  public func contains(_ size: CGSize) -> Bool {
    return width >= size.width && height >= size.height
  }
  public var floored: CGSize {
    return CGSize(width: floor(width), height: floor(height))
  }
}

extension CGRect {
  
  init(center: CGPoint, size: CGSize) {
    let origin = CGPoint(x:center.x - 0.5 * size.width, y:center.y - 0.5 * size.height)
    self.init(origin: origin, size: size)
  }
  
  var center: CGPoint {
    return CGPoint(x: origin.x + 0.5 * size.width, y: origin.y + 0.5 * size.height)
  }
}

extension String {
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

extension NSAttributedString {
  
  // Breaks up an NSAttributedString into its whitespace-separated NSAttributedString components
  private var components: [NSAttributedString] {
    var result = [NSAttributedString]()
    // This does not treat non-breaking spaces correctly:
    //string.enumerateSubstrings(in: string.startIndex ..< string.endIndex, options: .byWords) { (substring, substringRange, enclosingRange, stop) in
    //  result += [self.attributedSubstring(from: NSRange(enclosingRange, in: self.string))]
    //}
    var lastPosition = 0
    let separators = CharacterSet(charactersIn: " \n") // .whitespacesAndNewlines would break on non-breaking spaces
    string.rangesOfCharacters(from: separators).forEach { skipRange in
      let range = NSRange(location: lastPosition, length: skipRange.location - lastPosition)
      result += [attributedSubstring(from: range)]
      lastPosition = skipRange.upperBound
    }
    result += [attributedSubstring(from: NSRange(location: lastPosition, length: length - lastPosition))]
    return result
  }
  
  var longestWord: NSAttributedString {
    // Without a fully specified font, the "longest word" calculation" can fail: two long words with very similar sizes might "flip" in terms of which one is longest as the font size changes, eg:
    // > ["example", "dynamic"].map { $0.boundingRect(with: .greatestFiniteSize, options: [], attributes: [.font: UIFont.systemFont(ofSize: 100)], context: nil).width }
    // [40.13671875, 40.5029296875] // "dynamic" is always larger, regardless of specified font size, as expected
    // > ["example", "dynamic"].map { $0.boundingRect(with: .greatestFiniteSize, options: [], attributes: [:], context: nil).width }
    // [45.357421875, 44.68359375] // "example" is larger when no font is specified. What font is even used here??
    // UPDATE: on watchOS (perhaps elsewhere too) this is still not robust and might choose the "wrong" word
    precondition(hasFontFullySpecified)
    return components.map { ($0, $0.boundingRect(with: .greatestFiniteSize, options: [], context: nil).width) }.max { $0.1 < $1.1 }?.0 ?? .init()
  }
  
  func withFontSize(_ fontSize: CGFloat) -> NSAttributedString {
    guard length > 0 else { return self }
    let result = NSMutableAttributedString(attributedString: self)
    result.enumerateAttribute(.font, in: NSRange(location: 0, length: result.length), options: []) { value, range, stop in
      guard let value = value else { preconditionFailure("String must have a font set in all locations.") }
      #if os(iOS) || os(watchOS)
      let oldFont: UIFont = value as! UIFont
      let newFont: UIFont = oldFont.withSize(oldFont.pointSize > 1 ? fontSize : oldFont.pointSize * fontSize)
      #else
      let oldFont: NSFont = value as! NSFont
      let newFont: NSFont = NSFont(descriptor: oldFont.fontDescriptor, size: fontSize)!
      #endif
      result.removeAttribute(.font, range: range)
      result.addAttribute(.font, value: newFont, range: range)
    }
    
    // Fix for emoji
    // https://stackoverflow.com/questions/40914624/what-is-the-nsoriginalfont-attribute-in-nsattributedstring
    result.removeAttribute(NSAttributedString.Key(rawValue: "NSOriginalFont"), range: NSMakeRange(0, result.length))
    return result
  }
  
  // For some reason, if the attributed text does not have a font we may have line spacing / positioning issues, as well as issues with
  // the calculation of `longestWord`.
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
