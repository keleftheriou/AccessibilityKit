//
//  ViewController.swift
//  AccessibilityKitExample
//
//  Created by Kosta Eleftheriou on 9/3/18.
//  Copyright © 2018 Kpaw. All rights reserved.
//

import UIKit
import AccessibilityKit

class ViewController: UITableViewController {
  
  override var prefersStatusBarHidden: Bool { return true }
  
  private let cellIdentifier = "MaxFontViewCellIdentifier"
  
  class MaxFontTextViewCell: UITableViewCell {
    
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    // Do any additional setup after loading the view, typically from a nib.
    tableView.register(MaxFontTextViewCell.self, forCellReuseIdentifier: cellIdentifier)
    tableView.separatorStyle = .none
    tableView.indicatorStyle = .white
  }
  
  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return 35
  }
  
  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath)
    cell.textLabel?.text = "Section \(indexPath.section) Row \(indexPath.row)"
    return cell
  }
  
  
}

