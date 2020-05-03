//
//  AppDelegate.swift
//  CoronaML
//
//  Created by Demchenko Artem on 03.05.2020.
//  Copyright © 2020 Home. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        window = UIWindow(frame: UIScreen.main.bounds)
        
        let rootViewController = ClassificationViewController.init(nibName: String(describing:  ClassificationViewController.self), bundle: nil)
        let navigationController = UINavigationController(rootViewController: rootViewController)
        window?.rootViewController = navigationController
        window?.tintColor = UIColor.windowTintColor
        window?.makeKeyAndVisible()
        
        return true
    }
    
}

