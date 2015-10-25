//
//  ProfileViewController.swift
//  MightyMinders
//
//  Created by Justin Bane on 8/9/15.
//  Copyright (c) 2015 Justin Bane. All rights reserved.
//

import UIKit

class ProfileViewController: UIViewController {
    
    let ref = Firebase(url: "https://mightyminders.firebaseio.com/")
    var profileData: FDataSnapshot!
    
    @IBOutlet weak var closeBtn: UIButton!
    @IBOutlet weak var firstNameFld: MMTextField!
    @IBOutlet weak var lastNameFld: MMTextField!
    @IBOutlet weak var emailFld: MMTextField!
    @IBOutlet weak var currPasswdFld: MMTextField!
    @IBOutlet weak var newPasswdFld: MMTextField!
    @IBOutlet var logoutBtn: UIButton!
    @IBOutlet weak var saveBtn: UIButton!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        // get user data to fields
        let usersRef = self.ref.childByAppendingPath("users/\(ref.authData.uid)")
        usersRef.observeEventType(.Value, withBlock: { (snapshot) -> Void in
            // set reminders object
            self.profileData = snapshot
            self.firstNameFld.text = self.profileData.value.objectForKey("first_name") as? String
            self.lastNameFld.text = self.profileData.value.objectForKey("last_name") as? String
            self.emailFld.text = self.profileData.value.objectForKey("email_address") as? String
            
        })
        
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        view.endEditing(true)
        super.touchesBegan(touches, withEvent: event)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func saveProfileData(sender: AnyObject) {
        
        var dataToSend = [String: String]()
        let currentEmail = profileData.value.objectForKey("email_address") as? String
        
        if newPasswdFld.text == "" {
            if let first_name = firstNameFld.text {
                dataToSend["first_name"] = first_name
            }
            
            if let last_name = lastNameFld.text {
                dataToSend["last_name"] = last_name
            }
            
            if emailFld.text != currentEmail {
                //check for passwd
                if currPasswdFld.text == "" {
                    let passwdError = UIAlertView(title: "Error", message: "Please enter your current password to change your email", delegate: nil, cancelButtonTitle: "OK")
                    passwdError.show()
                } else {
                    
                    // change user email
                    ref.changeEmailForUser(currentEmail, password: currPasswdFld.text,
                        toNewEmail: emailFld.text, withCompletionBlock: { error in
                            if error != nil {
                                // There was an error processing the request
                                let emailError = UIAlertView(title: "Error", message: "There was an error changing your email, please try again", delegate: nil, cancelButtonTitle: "OK")
                                emailError.show()
                            } else {
                                // Email changed successfully
                                if let email_address = self.emailFld.text {
                                    dataToSend["email_address"] = email_address
                                    self.updateProfileData(dataToSend)
                                }
                            }
                    })
                    
                    
                }
                
            } else {
                dataToSend["email_address"] = currentEmail
                updateProfileData(dataToSend)
            }

        }
        
        // passwd reset
        if currPasswdFld.text != "" && newPasswdFld.text != "" {
            
            // update passwd
            ref.changePasswordForUser(currentEmail, fromOld: currPasswdFld.text,
                toNew: newPasswdFld.text, withCompletionBlock: { error in
                    if error != nil {
                        // There was an error processing the request
                        let passwdError = UIAlertView(title: "Error", message: "There was an error changing your password", delegate: nil, cancelButtonTitle: "OK")
                        passwdError.show()
                    } else {
                        // Password changed successfully
                        let passwdMsg = UIAlertView(title: "Success!", message: "Your password has been changed.", delegate: nil, cancelButtonTitle: "OK")
                        passwdMsg.show()
                        self.currPasswdFld.text = ""
                        self.newPasswdFld.text = ""
                    }
            })
            
        }
        
    }
    
    func updateProfileData(dataToUpdate: [String: String]) {
        
        if dataToUpdate.count > 0 {
            let profileRef = self.ref.childByAppendingPath("users/\(ref.authData.uid)")
            profileRef.setValue(dataToUpdate)
            let profileMsg = UIAlertView(title: "Success!", message: "Your profile information has been updated.", delegate: nil, cancelButtonTitle: "OK")
            profileMsg.show()
        }
        
    }
    
    @IBAction func logoutAction(sender: UIButton) {
        
        // kill firebase session
        ref.unauth()
        self.dismissViewControllerAnimated(true, completion: nil)
        
    }
    
    @IBAction func closeBtnAction(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }

}
