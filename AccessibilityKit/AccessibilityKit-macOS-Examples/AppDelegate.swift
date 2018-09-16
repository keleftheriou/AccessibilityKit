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
    window!.contentView!.addSubview(controller.view)
    window!.makeKey()
  }
  
  func applicationWillTerminate(_ aNotification: Notification) {
    // Insert code here to tear down your application
  }
  
}

class ViewController: NSViewController {
  
  let textView: NSView = {
    let view = AKTextView()
    // TODO: all this should be inside our own initializer
    view.isVerticallyResizable = false
    view.isHorizontallyResizable = false
    // Remove internal horizontal padding
    view.textContainer!.lineFragmentPadding = 0
    // Remove all padding
    view.textContainerInset = .zero
    return view
  }()
  
  override func loadView() {
    textView.autoresizingMask = [.width, .height]
    self.view = textView
  }
  
  override func viewWillLayout() {
    super.viewWillLayout()
    view.frame = view.superview!.bounds
  }
  
}
