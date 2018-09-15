//
//  Test.swift
//  SPUserResizableView
//
//  Created by Kosta Eleftheriou on 9/13/18.
//

import Foundation
import UIKit

public class Test: NSObject {

  @objc
  public static func testString() -> NSAttributedString {
    let s = NSMutableAttributedString()
    s.append(NSAttributedString(string: "This is a ", attributes: [.foregroundColor: UIColor.white]))
    s.append(NSAttributedString(string: "COOL", attributes: [.foregroundColor: UIColor.cyan]))
    s.append(NSAttributedString(string: " example of ", attributes: [.foregroundColor: UIColor.white]))
    s.append(NSAttributedString(string: "DYNAMIC", attributes: [.foregroundColor: UIColor.red]))
    s.append(NSAttributedString(string: " font ", attributes: [.foregroundColor: UIColor.white]))
    s.append(NSAttributedString(string: "RESIZINGi 😃", attributes: [.foregroundColor: UIColor.green]))

    let paragraphStyle = NSMutableParagraphStyle()
    paragraphStyle.alignment = .center

    //s.append(NSAttributedString(string: " "))

    s.addAttribute(.paragraphStyle, value: paragraphStyle, range: NSRange(location: 0, length: s.length))
    s.addAttribute(.font, value: UIFont(name: "Noteworthy-Bold", size: 300)!, range: NSRange(location: 0, length: s.length))
//    s.addAttribute(.font, value: UIFont.systemFont(ofSize: 10), range: NSRange(location: 0, length: s.length))
    
//    return NSAttributedString(string: "I see you. I hear you. Winter, ", attributes: [.font: UIFont.systemFont(ofSize: 10)])
    

    return s
    
    
    //    var temp = ""
    //    Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { _ in
    //      temp += " "
    //      let i = Int(round(drand48() * 6))
    //      for _ in 0..<i { temp += "\(i)" }
    //      self.attributedText = NSAttributedString(string: temp)
    //    }
    
    
    //    Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { _ in
    //      UIView.animate(withDuration: 0.5) {
    //        self.frame = CGRect(origin: .zero, size: CGSize(width: 20 + 300 * drand48(), height: 20 + 300 * drand48()))
    //      }
    //    }
  }
  
}
