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
  
  class MyTextView: AKTextView {
    let gradient = CAGradientLayer()
    override func layout() {
      super.layout()
      if gradient.superlayer == nil {
        drawsBackground = false
        wantsLayer = true
        gradient.colors = [NSColor.white.cgColor, NSColor.gray.cgColor]
        layer!.insertSublayer(gradient, at: 0)
      }
      gradient.frame = bounds
    }
  }
  
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
