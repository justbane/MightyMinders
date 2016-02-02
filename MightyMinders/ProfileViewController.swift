//
//  ProfileViewController.swift
//  MightyMinders
//
//  Created by Justin Bane on 8/9/15.
//  Copyright (c) 2015 Justin Bane. All rights reserved.
//

import UIKit
import AeroGearPush

class ProfileViewController: MMCustomViewController {
    
    let ref = Firebase(url: "https://mightyminders.firebaseio.com/")
    var user: Users?
    var usersRef: UInt!
    
    @IBOutlet weak var closeBtn: UIButton!
    @IBOutlet weak var firstNameFld: MMTextField!
    @IBOutlet weak var lastNameFld: MMTextField!
    @IBOutlet weak var emailFld: MMTextField!
    @IBOutlet weak var currPasswdFld: MMTextField!
    @IBOutlet weak var newPasswdFld: MMTextField!
    @IBOutlet var logoutBtn: UIButton!
    @IBOutlet weak var saveBtn: UIButton!
    @IBOutlet weak var profileActivity: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
    }
    
    override func viewWillAppear(animated: Bool) {
        // check for valid user
        
        // show activity
        profileActivity.startAnimating()
        profileActivity.hidden = false
        
        if ref.authData == nil {
            super.showLogin()
        } else {
            // get user data to fields
            usersRef = ref.childByAppendingPath("users/\(ref.authData.uid)").observeEventType(.Value, withBlock: { (snapshot) -> Void in
                // set reminders object
                self.firstNameFld.text = snapshot.value.objectForKey("first_name") as? String
                self.lastNameFld.text = snapshot.value.objectForKey("last_name") as? String
                self.emailFld.text = snapshot.value.objectForKey("email_address") as? String
                
                self.user = Users(currentEmail: self.emailFld.text!, currentFirstName: self.firstNameFld.text!, currentLastName: self.lastNameFld.text!)
                
                // hide the activity
                self.profileActivity.stopAnimating()
                self.profileActivity.hidden = true;
            })
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        
    }
    
    override func viewDidDisappear(animated: Bool) {
        
        // remove observer
        ref.removeObserverWithHandle(usersRef)
        
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
        
        if newPasswdFld.text == "" {
            
            if emailFld.text != user!.currentEmail {
                //check for passwd
                if currPasswdFld.text == "" {
                    let passwdError = UIAlertView(title: "Error", message: "Please enter your current password to change your email", delegate: nil, cancelButtonTitle: "OK")
                    passwdError.show()
                } else {
                    
                    user!.changeEmailForUser(currPasswdFld.text!, newEmail: emailFld.text!) {(error: Bool) in
                        if error {
                            let emailError = UIAlertView(title: "Error", message: "There was an error changing your email, please try again", delegate: nil, cancelButtonTitle: "OK")
                            emailError.show()
                        } else {
                            let emailSuccess = UIAlertView(title: "Success", message: "Your email has been updated", delegate: nil, cancelButtonTitle: "OK")
                            emailSuccess.show()
                            self.currPasswdFld.text = ""
                        }
                    }
                    
                }
                
            } else {
                user!.updateProfileData(email: emailFld.text!, firstName: firstNameFld.text!, lastName: lastNameFld.text!, completion: { (error) -> Void in
                    if !error {
                        let profileMsg = UIAlertView(title: "Success!", message: "Your profile information has been updated.", delegate: nil, cancelButtonTitle: "OK")
                        profileMsg.show()
                    }
                })
            }

        }
        
        // passwd reset
        if currPasswdFld.text != "" && newPasswdFld.text != "" {
            
            // update passwd
            user!.changeUserPassword(email: emailFld.text!, oldPassword: currPasswdFld.text!, newPassword: newPasswdFld.text!, completion: { (error) -> Void in
                if error {
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
    
    
    @IBAction func logoutAction(sender: UIButton) {
        
        // kill firebase session
        ref.unauth()
        self.dismissViewControllerAnimated(true, completion: nil)
        
    }
    
    @IBAction func closeBtnAction(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }

}
