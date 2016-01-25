//
//  Users.swift
//  MightyMinders
//
//  Created by Justin Bane on 1/24/16.
//  Copyright © 2016 Justin Bane. All rights reserved.
//

import Foundation
import AeroGearPush


class Users {
    
    let ref = Firebase(url: "https://mightyminders.firebaseio.com/")
    let userDefaults = NSUserDefaults.standardUserDefaults()
    
    var currentEmail: String
    var currentFirstName: String
    var currentLastName: String
    
    init(currentEmail: String, currentFirstName: String, currentLastName: String) {
        
        self.currentEmail = currentEmail
        self.currentFirstName = currentFirstName
        self.currentLastName = currentLastName
        
    }
    
    func changeEmailForUser(password: String, newEmail: String, completion: (error: Bool) -> Void) {
        
        // change user email
        ref.changeEmailForUser(self.currentEmail, password: password, toNewEmail: newEmail, withCompletionBlock: { error in
            
                if error != nil {
                    // There was an error processing the request
                    completion(error: true)
                } else {
                    // Email changed successfully
                    self.updateProfileData(email: newEmail, firstName: self.currentFirstName, lastName: self.currentLastName, completion: { (error) -> Void in
                        if error {
                            // FIXME: alert an error
                        }
                    })
                    completion(error: false)
                }
        
        })
        
    }
    
    func updateProfileData(email emailAddress: String, firstName: String, lastName: String, completion: (error: Bool) -> Void) {
        
            let dataToUpdate = [
                "email_address": emailAddress,
                "first_name": firstName,
                "last_name": lastName
            ]
        
            let profileRef = self.ref.childByAppendingPath("users/\(ref.authData.uid)")
            profileRef.setValue(dataToUpdate)
            
            let registration = AGDeviceRegistration(serverURL: NSURL(string: "https://push-baneville.rhcloud.com/ag-push/")!)
            
            registration.registerWithClientInfo({ (clientInfo: AGClientDeviceInformation!)  in
                
                // apply the token, to identify this device
                clientInfo.deviceToken = self.userDefaults.objectForKey("deviceToken") as? NSData
                
                clientInfo.variantID = self.userDefaults.valueForKey("variantID") as? String
                clientInfo.variantSecret = self.userDefaults.valueForKey("variantSecret") as? String
                
                // --optional config--
                // set some 'useful' hardware information params
                clientInfo.alias = dataToUpdate["email_address"]
                self.userDefaults.setValue(dataToUpdate["email_address"], forKey: "storedUserEmail")
                
                }, success: {
                    print("device alias updated");
                    
                }, failure: { (error:NSError!) -> () in
                    print("device alias update error: \(error.localizedDescription)")
            })
            
            completion(error: false)
        
    }
    
    func changeUserPassword(email currentEmail: String, oldPassword: String, newPassword: String, completion: (error: Bool) -> Void) {
        
        ref.changePasswordForUser(currentEmail, fromOld: oldPassword,
            toNew: newPassword, withCompletionBlock: { error in
                if error != nil {
                    completion(error: true)
                } else {
                    completion(error: false)
                }
        })
        
    }
    
}