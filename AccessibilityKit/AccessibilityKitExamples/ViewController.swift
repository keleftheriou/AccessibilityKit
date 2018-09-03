//
//  ViewController.swift
//  AccessibilityKitExample
//
//  Created by Kosta Eleftheriou on 9/3/18.
//  Copyright © 2018 Kpaw. All rights reserved.
//

import UIKit
import AccessibilityKit

class MaxFontTextViewCell: UITableViewCell {
  
  let maxFontTextView = MaxFontTextView()
  let gradient = CAGradientLayer()
  
  override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    maxFontTextView.backgroundColor = .clear
    contentView.addSubview(maxFontTextView)
    contentView.layer.insertSublayer(gradient, at: 0)
  }
  
  override func layoutSubviews() {
    gradient.frame = contentView.bounds
    maxFontTextView.frame = contentView.bounds
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}

class ViewController: UITableViewController {
  
  var dataSource: [String] = [
    "Test 😎",
    "Donec id",
    "Non mi porta! 💪",
    "Testing",
    "Gravida at eget metus.",
    "Integer posuere.\nTesting...",
    ":)",
    "Cum sociis natoque penatibus et magnis dis.",
    "Duis mollis, est non commodo luctus",
    "❤️",
    "Eget lacinia odio sem nec elit.",
    "🙉🐶",
    "Vestibulum id ligula porta felis euismod semper.",
    "Maecenas faucibus mollis interdum.",
    "Donec ullamcorper nulla non metus auctor fringilla.",
    "Aenean lacinia bibendum nulla sed consectetur.",
    "Cum sociis natoque penatibus et magnis dis parturient montes.",
    ]
  
  private let cellIdentifier = "MaxFontViewCellIdentifier"
  
  override func viewDidLoad() {
    super.viewDidLoad()
    // Do any additional setup after loading the view, typically from a nib.
    tableView.register(MaxFontTextViewCell.self, forCellReuseIdentifier: cellIdentifier)
    tableView.separatorStyle = .none
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
    return dataSource.count
  }
  
  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as! MaxFontTextViewCell
    cell.maxFontTextView.attributedText = .init(string: "\(dataSource[indexPath.row])")
    let colors = [UIColor.lightGray, UIColor.magenta, UIColor.cyan, UIColor.orange, UIColor.red, UIColor.green]
    cell.gradient.colors = [colors[indexPath.row % colors.count].cgColor, UIColor.white.cgColor]
    return cell
  }
  
}
