//
//  AppDelegate.swift
//  MightyMinders
//
//  Created by Justin Bane on 4/23/15.
//  Copyright (c) 2015 Justin Bane. All rights reserved.
//

import UIKit
import CoreLocation
import Firebase

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    let userDefaults = NSUserDefaults.standardUserDefaults()
    let environment = "prod"
    
    var window: UIWindow?
    var reminderKeys = [String]()
    
    override init() {
        // New Firebase
        FIRApp.configure()
    }
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
        // Override point for customization after application launch.
        application.setStatusBarStyle(UIStatusBarStyle.Default, animated: false)
        
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
        application.registerUserNotificationSettings(mySettings)
        
        // Push notifications
        application.registerForRemoteNotifications()
        
        // Background fetch - dont need it currently but setting it up anyway
        application.setMinimumBackgroundFetchInterval(UIApplicationBackgroundFetchIntervalMinimum)
        
        // Set observer for notification token updates
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.tokenRefreshNotification),
                                                         name: kFIRInstanceIDTokenRefreshNotification, object: nil)
        
        return true
    }
    
    // MARK: Handle remote notification action
    func application(application: UIApplication, handleActionWithIdentifier identifier: String?, forRemoteNotification userInfo: [NSObject : AnyObject], withResponseInfo responseInfo: [NSObject : AnyObject], completionHandler: () -> Void) {
        
        print(identifier)
        
//        if identifier == "ADD_MINDER" {
//            NSNotificationCenter.defaultCenter().postNotificationName("addMinderPressed", object: nil, userInfo: userInfo)
//            
//        }
//        if identifier == "IGNORE_MINDER" {
//            // what shall we do here?
//            print("ignored")
//            
//        }
        
        completionHandler()
    }
    
    // MARK: Recieve push
    func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject]) {
        
        // Recieved a push notification
        // Print message ID.
        print("Message: \(userInfo)")
        
        // Print full message.
        print("%@", userInfo)
        
    }
    
    // MARK: Register for push
    func application(application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData) {
        let tokenChars = UnsafePointer<CChar>(deviceToken.bytes)
        var tokenString = ""
        
        for i in 0..<deviceToken.length {
            tokenString += String(format: "%02.2hhx", arguments: [tokenChars[i]])
        }
        
        //Tricky line
        FIRInstanceID.instanceID().setAPNSToken(deviceToken, type: FIRInstanceIDAPNSTokenType.Unknown)
        print("Device Token:", tokenString)
        userDefaults.setValue(tokenString, forKey: "firebaseAPNSToken")
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
        
        FIRMessaging.messaging().disconnect()
        print("Disconnected from FCM.")
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        
        connectToFcm()
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    // MARK: FireBase Notifications
    func tokenRefreshNotification(notification: NSNotification) {
        if let refreshedToken = FIRInstanceID.instanceID().token() {
            print("InstanceID token: \(refreshedToken)")
            userDefaults.setValue(refreshedToken, forKey: "firebaseAPNSToken")
        }
        // Connect to FCM since connection may have failed when attempted before having a token.
        connectToFcm()
    }
    
    func connectToFcm() {
        FIRMessaging.messaging().connectWithCompletion { (error) in
            if (error != nil) {
                print("Unable to connect with FCM. \(error)")
            } else {
                print("Connected to FCM.")
            }
        }
    }


}

