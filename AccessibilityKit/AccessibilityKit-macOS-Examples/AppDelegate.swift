//
//  AppDelegate.swift
//  AccessibilityKit-macOS-Examples
//
//  Created by Kosta Eleftheriou on 9/16/18.
//  Copyright © 2018 Kpaw. All rights reserved.
//

import Cocoa
import AccessibilityKit_macOS

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
  
  @IBOutlet weak var window: NSWindow!
  
  func applicationDidFinishLaunching(_ aNotification: Notification) {
    // Insert code here to initialize your application
    let controller = ViewController()
    window.contentView!.addSubview(controller.view)
    window.makeKey()
  }
  
  func applicationWillTerminate(_ aNotification: Notification) {
    // Insert code here to tear down your application
  }
  
}

class ViewController: NSViewController {
  
  let textView = MyTextView()
  
  override func loadView() {
    view = textView
    view.autoresizingMask = [.width, .height]
  }
  
  override func viewWillLayout() {
    super.viewWillLayout()
    view.frame = view.superview!.bounds
  }
  
}

class MyTextView: AKTextView {
  
  private let gradient = CAGradientLayer()
  
  override func layout() {
    super.layout()
    
    // Our init function. I know.
    if gradient.superlayer == nil {
      drawsBackground = false
      wantsLayer = true
      gradient.colors = [NSColor.white.cgColor, NSColor.gray.cgColor]
      layer!.insertSublayer(gradient, at: 0)
      ///////////////////////////////////////
      alignment = .center
      verticalAlignment = .center
      textContainerInset = .init(width: 20, height: 20)
    }
    
    gradient.frame = bounds
  }
  
  override func drawInsertionPoint(in rect: NSRect, color: NSColor, turnedOn flag: Bool) {
    let desiredWidth = font!.pointSize * 0.05
    // Grow rect towards the left, not the right, to avoid the cursor sometimes getting clipped.
    let rect = NSRect(x: rect.maxX - desiredWidth, y: rect.origin.y, width: desiredWidth, height: rect.height)
    super.drawInsertionPoint(in: rect, color: NSColor.systemBlue, turnedOn: flag)
  }
}
