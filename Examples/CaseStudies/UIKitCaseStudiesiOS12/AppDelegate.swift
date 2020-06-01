//
//  AppDelegate.swift
//  UIKitCaseStudiesiOS12
//
//  Created by Bioche on 11/05/2020.
//  Copyright © 2020 Point-Free. All rights reserved.
//

import UIKit
import ComposableArchitecture

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
  
  var window: UIWindow?
  
  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    
    self.window = UIWindow()
    self.window?.rootViewController = UINavigationController(
      rootViewController: RootViewController())
    self.window?.makeKeyAndVisible()
    
    return true
  }
  
  
}

