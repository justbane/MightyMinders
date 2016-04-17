//
//  AppDelegate.swift
//  MightyMinders
//
//  Created by Justin Bane on 4/23/15.
//  Copyright (c) 2015 Justin Bane. All rights reserved.
//

import UIKit
import CoreLocation
import AeroGearPush

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    let ref = Firebase(url: "https://mightyminders.firebaseio.com/")
    let userDefaults = NSUserDefaults.standardUserDefaults()
    let environment = "prod"
    
    var window: UIWindow?
    var reminderKeys = [String]()
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
        // Override point for customization after application launch.
        application.setStatusBarStyle(UIStatusBarStyle.Default, animated: false)
        
        // Clear all the notifications on first run (get minders will re-add from FB
        // UIApplication.sharedApplication().cancelAllLocalNotifications()
        
        // Actions
        let addMinderAction:UIMutableUserNotificationAction = UIMutableUserNotificationAction()
        addMinderAction.identifier = "ADD_MINDER"
        addMinderAction.title = "Update"
        addMinderAction.activationMode = UIUserNotificationActivationMode.Foreground
        addMinderAction.authenticationRequired = false
        addMinderAction.destructive = false
        
        let ignoreMinderAction:UIMutableUserNotificationAction = UIMutableUserNotificationAction()
        ignoreMinderAction.identifier = "IGNORE_MINDER"
        ignoreMinderAction.title = "Ignore"
        ignoreMinderAction.activationMode = UIUserNotificationActivationMode.Background
        ignoreMinderAction.authenticationRequired = false
        ignoreMinderAction.destructive = true
        
        // Categories
        let mainCategory: UIMutableUserNotificationCategory = UIMutableUserNotificationCategory()
        mainCategory.identifier = "MAIN_CATEGORY"
        
        let minimalActionsArray: NSArray = [addMinderAction, ignoreMinderAction]
        
        mainCategory.setActions(minimalActionsArray as? [UIUserNotificationAction], forContext: UIUserNotificationActionContext.Minimal)
        
        // Add notification set
        let categories: NSSet = NSSet(objects: mainCategory)
        
        // Notifications
        let mySettings: UIUserNotificationSettings = UIUserNotificationSettings(forTypes: [.Alert, .Badge, .Sound], categories: categories as? Set<UIUserNotificationCategory>)
        UIApplication.sharedApplication().registerUserNotificationSettings(mySettings)
        
        // Push notifications
        UIApplication.sharedApplication().registerForRemoteNotifications()
        
        // Background fetch - dont need it currently but setting it up anyway
        UIApplication.sharedApplication().setMinimumBackgroundFetchInterval(UIApplicationBackgroundFetchIntervalMinimum)
        
        // Push analytics
        AGPushAnalytics.sendMetricsWhenAppLaunched(launchOptions)
        
        return true
    }
    
    
    // MARK: Handle remote notification action
    func application(application: UIApplication, handleActionWithIdentifier identifier: String?, forRemoteNotification userInfo: [NSObject : AnyObject], withResponseInfo responseInfo: [NSObject : AnyObject], completionHandler: () -> Void) {
        
        if identifier == "ADD_MINDER" {
            NSNotificationCenter.defaultCenter().postNotificationName("addMinderPressed", object: nil, userInfo: userInfo)
            
        }
        if identifier == "IGNORE_MINDER" {
            // what shall we do here?
            print("ignored")
            
        }
        
        completionHandler()
    }
    
    // MARK: Recieve push
    func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject]) {
        
        // Push analytics
        AGPushAnalytics.sendMetricsWhenAppAwoken(application.applicationState, userInfo: userInfo)
        
    }
    
    // MARK: Register for push
    func application(application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData) {
        
        if environment == "prod" {
            // Store push server keys - prod
            userDefaults.setValue("d90767e5-86b1-4169-a15c-2422cdcd3c1c", forKey: "variantID")
            userDefaults.setValue("946dfa15-3eb6-4e9f-9578-752be6094358", forKey: "variantSecret")
            
            // REST credentials - prod
            userDefaults.setValue("1ce88109-d9f0-447e-b990-5b65240d8a73", forKey: "restUsername")
            userDefaults.setValue("8f9b189d-f55e-4cd0-b417-19f0136d440a", forKey: "restPassword")
            
        } else {
            // Store push server keys - dev
            userDefaults.setValue("eb234d8c-1829-483b-ad2a-a855eeacc2b2", forKey: "variantID")
            userDefaults.setValue("2f2f8f44-a6ba-40f4-b8a1-fc06ac367315", forKey: "variantSecret")
            
            // REST credentials - dev
            userDefaults.setValue("f8de81a1-ce56-496e-8e6d-f179244b7450", forKey: "restUsername")
            userDefaults.setValue("e37fb59b-0895-4d85-9d34-6d8a2b3cce86", forKey: "restPassword")
        }

        
        let registration = AGDeviceRegistration(serverURL: NSURL(string: "https://push-baneville.rhcloud.com/ag-push/")!)
        
        registration.registerWithClientInfo({ (clientInfo: AGClientDeviceInformation!)  in
            
            // apply the token, to identify this device
            clientInfo.deviceToken = deviceToken
            // store token for later
            self.userDefaults.setObject(deviceToken, forKey: "deviceToken")
            
            clientInfo.variantID = self.userDefaults.valueForKey("variantID")! as? String
            clientInfo.variantSecret = self.userDefaults.valueForKey("variantSecret")! as? String
            
            // --optional config--
            // set some 'useful' hardware information params
            let currentDevice = UIDevice()
            clientInfo.operatingSystem = currentDevice.systemName
            clientInfo.osVersion = currentDevice.systemVersion
            clientInfo.deviceType = currentDevice.model
            
            if self.userDefaults.valueForKey("storedUserEmail") != nil {
                if let email = self.userDefaults.valueForKeyPath("storedUserEmail") as? String {
                    clientInfo.alias = email
                }
            }
            
            }, success: {
                print("UPS registration worked");
                
            }, failure: { (error:NSError!) -> () in
                print("UPS registration Error: \(error.localizedDescription)")
        })
    }
    
    // MARK: Failed to register
    func application(application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: NSError) {
        print(error)
    }
    
    // MARK: Required methods
    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

