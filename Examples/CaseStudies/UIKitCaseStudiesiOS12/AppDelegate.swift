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

