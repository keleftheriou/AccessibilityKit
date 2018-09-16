//
//  AppDelegate.swift
//  AccessibilityKit-macOS-Examples
//
//  Created by Kosta Eleftheriou on 9/16/18.
//  Copyright © 2018 Kpaw. All rights reserved.
//

import Cocoa

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
  
  override func loadView() {
    let view = NSView()
    view.autoresizingMask = [.width, .height]
    view.wantsLayer = true
    view.layer?.backgroundColor = NSColor.green.cgColor
    view.layer?.borderWidth = 2
    view.layer?.borderColor = NSColor.blue.cgColor
    self.view = view
  }
  
  override func viewWillLayout() {
    super.viewWillLayout()
    view.frame = view.superview!.bounds
  }
  
}
