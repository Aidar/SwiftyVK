import UIKit
import SwiftyVK

@UIApplicationMain
final class AppDelegate: UIResponder, UIApplicationDelegate {
  
  
  
  var window: UIWindow?
  
  
  
  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey : Any]? = nil) -> Bool {
    _ = VKDelegateImpl(window_: window!)
    return true
  }
  
  
  func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
    VK.processURL(url: url, options: options)
    return true
  }
  
  @IBAction func buttonDown(_ sender: AnyObject) {
    APIWorker.action(sender.tag)
  }
}
