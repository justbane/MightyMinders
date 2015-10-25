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
    
    var window: UIWindow?
    var reminderKeys = [String]()
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
        // Override point for customization after application launch.
        application.setStatusBarStyle(UIStatusBarStyle.Default, animated: false)
        
        // local notifications
        application.registerUserNotificationSettings(UIUserNotificationSettings(forTypes: [.Sound, .Alert, .Badge], categories: nil))
        UIApplication.sharedApplication().cancelAllLocalNotifications()
        // push notifications
        UIApplication.sharedApplication().registerForRemoteNotifications()
        
        // background fetch - dont need it currently but setting it up anyway
        UIApplication.sharedApplication().setMinimumBackgroundFetchInterval(UIApplicationBackgroundFetchIntervalMinimum)
        
        // push analytics
        AGPushAnalytics.sendMetricsWhenAppLaunched(launchOptions)
        
        return true
    }
    
    
    // recieve push
    func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject]) {
        
        // push analytics
        AGPushAnalytics.sendMetricsWhenAppAwoken(application.applicationState, userInfo: userInfo)
        
    }
    
    // register for push
    func application(application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData) {
        print("APNS Success")
        
        let registration = AGDeviceRegistration(serverURL: NSURL(string: "https://push-baneville.rhcloud.com/ag-push/")!)
        
        registration.registerWithClientInfo({ (clientInfo: AGClientDeviceInformation!)  in
            
            // apply the token, to identify this device
            clientInfo.deviceToken = deviceToken
            // store token for later
            self.userDefaults.setObject(deviceToken, forKey:  "deviceToken")
            
            clientInfo.variantID = "eb234d8c-1829-483b-ad2a-a855eeacc2b2"
            clientInfo.variantSecret = "2f2f8f44-a6ba-40f4-b8a1-fc06ac367315"
            
            // --optional config--
            // set some 'useful' hardware information params
            let currentDevice = UIDevice()
            clientInfo.operatingSystem = currentDevice.systemName
            clientInfo.osVersion = currentDevice.systemVersion
            clientInfo.deviceType = currentDevice.model
            
            if self.ref.authData != nil {
                if let email = self.ref.authData.providerData["email"] as? String {
                    clientInfo.alias = email
                }
            }
            
            }, success: {
                print("UPS registration worked");
                
            }, failure: { (error:NSError!) -> () in
                print("UPS registration Error: \(error.localizedDescription)")
        })
    }
    
    // failed to register
    func application(application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: NSError) {
        print(error)
    }
    
    
    // Required methods

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

