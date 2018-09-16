//
//  ViewController.swift
//  AccessibilityKitExample
//
//  Created by Kosta Eleftheriou on 9/3/18.
//  Copyright © 2018 Kpaw. All rights reserved.
//

import UIKit
import AccessibilityKit_iOS

class MaxFontTextViewCell: UITableViewCell {
  
  let maxFontTextView = AKLabel()
  let gradient = CAGradientLayer()
  
  override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    maxFontTextView.backgroundColor = .clear
    contentView.addSubview(maxFontTextView)
    contentView.layer.insertSublayer(gradient, at: 0)
  }
  
  override func layoutSubviews() {
    super.layoutSubviews()
    let safeBounds = contentView.safeAreaLayoutGuide.layoutFrame
    gradient.frame = safeBounds
    // `AKTextView` does not have any default padding, so add some here
    maxFontTextView.frame = UIEdgeInsetsInsetRect(safeBounds, UIEdgeInsetsMake(10, 10, 10, 10))
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}

class ViewController: UITableViewController {
  
  var dataSource: [String] = [
    "LARGE FONT SIZE",
    "Accessible text 😎",
    "What if the text is longer?",
    "The quick brown fox jumped over the lazy dog.",
    "Cool, it works! 💪",
    "Multiple line support",
    "Super fast font sizing",
    "CUSTOM ALIGNMENT OPTIONS",
    "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt.",
    ]
  
  private let cellIdentifier = "MaxFontViewCellIdentifier"
  
  override func viewDidLoad() {
    super.viewDidLoad()
    // Do any additional setup after loading the view, typically from a nib.
    tableView.register(MaxFontTextViewCell.self, forCellReuseIdentifier: cellIdentifier)
    tableView.separatorStyle = .none
    tableView.alwaysBounceVertical = true
    tableView.showsVerticalScrollIndicator = false
    tableView.backgroundColor = .black
    
    #if targetEnvironment(simulator)
    Timer.scheduledTimer(withTimeInterval: 2.5, repeats: true) { timer in
      UIView.animate(withDuration: 1.0) {
        self.tableView.scrollToRow(at: self.tableView.indexPathsForVisibleRows!.last!, at: .top, animated: false)
      }
    }
    #endif
  }
  
  override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
    tableView.reloadData()
  }

  override var prefersStatusBarHidden: Bool { return true }
}

extension ViewController {
  
  override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    return 200
  }
  
  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return 10000
  }
  
  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as! MaxFontTextViewCell
    
    // Pretty colors
    let bgTopColors    = [UIColor.gray,  UIColor.white]
    let bgBottomColors = [UIColor.black, UIColor.gray ]
    let textColors     = [UIColor.white, UIColor.black]
    
    cell.gradient.colors = [bgTopColors[indexPath.row % bgTopColors.count].cgColor, bgBottomColors[indexPath.row % bgBottomColors.count].cgColor]
    cell.gradient.startPoint = .init(x: 0, y: 0) // default is (0.5, 0.0)
    cell.gradient.endPoint   = .init(x: 1, y: 1) // default is (0.5, 1.0)
    
    // This paragraph style is the default - putting it here so it's easier to experiment with.
    let paragraphStyle = NSMutableParagraphStyle()
    paragraphStyle.lineBreakMode = .byWordWrapping
    paragraphStyle.alignment = .center
    
    // This vertical alignment is the default - putting it here so it's easier to experiment with.
    cell.maxFontTextView.verticalAlignment = .center
    
    // Set the attributed string that will fit the entire bounds of this cell
    cell.maxFontTextView.attributedText = .init(
      string: "\(dataSource[indexPath.row % dataSource.count])", attributes: [
        .font: UIFont.systemFont(ofSize: 12), // You *must* specify a font - the size is ignored.
        .foregroundColor: textColors[indexPath.row % textColors.count],
        .paragraphStyle: paragraphStyle,
      ])
    return cell
  }
  
}
