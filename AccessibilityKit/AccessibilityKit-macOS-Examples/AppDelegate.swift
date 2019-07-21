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
    let controller = ViewController()
    window.contentView!.addSubview(controller.view)
    window.makeKey()
  }
  
}

class ViewController: NSViewController {
  
  let textView = MyTextView()
  
  override func loadView() {
    textView.insertText("Dynamic font sizing. Try resizing this window.")
    textView.drawsBackground = false
    textView.alignment = .center
    textView.verticalAlignment = .center
    
    view = textView
    view.autoresizingMask = [.width, .height]
  }
  
  override func viewWillLayout() {
    super.viewWillLayout()
    view.frame = view.superview!.bounds
    // Either make the cursor or the selection background visible,
    // so that we can see the actual height of text lines.
    //textView.window?.makeFirstResponder(textView)
    textView.selectAll(nil)
  }
  
}

class MyTextView: AKTextView {
  // Grow the cursor rect towards the left, not the right, to avoid the cursor getting clippped
  // since we are not considering it when doing our font sizing calculations...
  override func drawInsertionPoint(in rect: NSRect, color: NSColor, turnedOn flag: Bool) {
    let desiredWidth = font!.pointSize * 0.05
    let rect = NSRect(x: rect.maxX - desiredWidth, y: rect.origin.y, width: desiredWidth, height: rect.height)
    super.drawInsertionPoint(in: rect, color: NSColor.systemBlue, turnedOn: flag)
  }
}
