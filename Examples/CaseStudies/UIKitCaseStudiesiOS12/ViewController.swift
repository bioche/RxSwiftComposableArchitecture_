//
//  ViewController.swift
//  UIKitCaseStudiesiOS12
//
//  Created by Bioche on 11/05/2020.
//  Copyright © 2020 Point-Free. All rights reserved.
//

import UIKit
import ComposableArchitecture

class ViewController: UIViewController {
  
  override func viewDidLoad() {
    super.viewDidLoad()
    // Do any additional setup after loading the view.
    
    view.backgroundColor = .red
    
    let r = Row(count: 36, id: UUID())
    
  }
  
  
  struct Row: Equatable, Identifiable {
    var count: Int
    let id: UUID
  }
  
  
}

