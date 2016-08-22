//
//  APNS.swift
//  MightyMinders
//
//  Created by Justin Bane on 5/19/16.
//  Copyright © 2016 Justin Bane. All rights reserved.
//

import Foundation
import UIKit

class APNS {
    
    let ref = FIRDatabase.database().reference()
    let userDefaults = NSUserDefaults.standardUserDefaults()
    
    let url: String
    let environment: String
    
    init() {
        
        self.environment = "prod"
        self.url = "https://push-baneville.rhcloud.com/ag-push/"
        
        setCredentials()
        
    }
    
    func setCredentials() {
        
        if self.environment == "prod" {
            // Store push server keys - prod
            userDefaults.setValue("d90767e5-86b1-4169-a15c-2422cdcd3c1c", forKey: defaultKeys.variantID.rawValue)
            userDefaults.setValue("946dfa15-3eb6-4e9f-9578-752be6094358", forKey: defaultKeys.variantSecret.rawValue)
            
            // REST credentials - prod
            userDefaults.setValue("1ce88109-d9f0-447e-b990-5b65240d8a73", forKey: defaultKeys.restUsername.rawValue)
            userDefaults.setValue("8f9b189d-f55e-4cd0-b417-19f0136d440a", forKey: defaultKeys.restPassword.rawValue)
            
        } else {
            // Store push server keys - dev
            userDefaults.setValue("eb234d8c-1829-483b-ad2a-a855eeacc2b2", forKey: defaultKeys.variantID.rawValue)
            userDefaults.setValue("2f2f8f44-a6ba-40f4-b8a1-fc06ac367315", forKey: defaultKeys.variantSecret.rawValue)
            
            // REST credentials - dev
            userDefaults.setValue("f8de81a1-ce56-496e-8e6d-f179244b7450", forKey: defaultKeys.restUsername.rawValue)
            userDefaults.setValue("e37fb59b-0895-4d85-9d34-6d8a2b3cce86", forKey: defaultKeys.restPassword.rawValue)
        }
        
    }
    
    func register(token: NSData) {
        
//        let registration = AGDeviceRegistration(serverURL: NSURL(string: self.url)!)
//        
//        registration.registerWithClientInfo({ (clientInfo: AGClientDeviceInformation!)  in
//            
//            // apply the token, to identify this device
//            clientInfo.deviceToken = token
//            // store token for
//            self.userDefaults.setObject(token, forKey: defaultKeys.deviceToken.rawValue)
//            
//            clientInfo.variantID = self.userDefaults.valueForKey(defaultKeys.variantID.rawValue)! as? String
//            clientInfo.variantSecret = self.userDefaults.valueForKey(defaultKeys.variantSecret.rawValue)! as? String
//            
//            // --optional config--
//            // set some 'useful' hardware information params
//            let currentDevice = UIDevice()
//            clientInfo.operatingSystem = currentDevice.systemName
//            clientInfo.osVersion = currentDevice.systemVersion
//            clientInfo.deviceType = currentDevice.model
//            
//            let email = FIRAuth.auth()?.currentUser?.email
//            if  email != nil {
//                clientInfo.alias = email!
//            }
//            
//            }, success: {
//                print("UPS registration worked");
//                
//            }, failure: { (error:NSError!) -> () in
//                print("UPS registration Error: \(error.localizedDescription)")
//        })
        
    }
    
    func updateAlias(email: String) {
        
//        let registration = AGDeviceRegistration(serverURL: NSURL(string: self.url)!)
//        
//        registration.registerWithClientInfo({ (clientInfo: AGClientDeviceInformation!)  in
//            
//            // Apply the token, to identify this device
//            clientInfo.deviceToken = self.userDefaults.objectForKey(defaultKeys.deviceToken.rawValue) as? NSData
//            
//            clientInfo.variantID = self.userDefaults.valueForKey(defaultKeys.variantID.rawValue) as? String
//            clientInfo.variantSecret = self.userDefaults.valueForKey(defaultKeys.variantSecret.rawValue) as? String
//            
//            // Optional config --
//            // Set some 'useful' hardware information params
//            clientInfo.alias = email
//            self.userDefaults.setValue(email, forKey: defaultKeys.emailAddress.rawValue)
//            
//            }, success: {
//                print("device alias updated");
//                
//            }, failure: { (error:NSError!) -> () in
//                print("device alias update error: \(error.localizedDescription)")
//        })
        
    }
    
    
}