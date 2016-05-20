//
//  LoginViewController.swift
//  MightyMinders
//
//  Created by Justin Bane on 4/23/15.
//  Copyright (c) 2015 Justin Bane. All rights reserved.
//

import UIKit
import AeroGearPush

class LoginViewController: UIViewController {

    let ref = Firebase(url: "https://mightyminders.firebaseio.com")
    let userDefaults = NSUserDefaults.standardUserDefaults()
    
    @IBOutlet weak var emailFld: UITextField!
    @IBOutlet weak var passFld: UITextField!
    @IBOutlet weak var loginBtn: UIButton!
    @IBOutlet weak var registerBtn: UIButton!
    @IBOutlet weak var errorTxt: UILabel!
    @IBOutlet weak var forgotPasswd: UIButton!
    @IBOutlet weak var activity: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        activity.hidden = true
        if let error = errorTxt {
            error.hidden = true;
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidAppear(animated: Bool) {
        if ref.authData != nil {
            // User authenticated with Firebase
            self.dismissViewControllerAnimated(true, completion: nil)
        }
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        view.endEditing(true)
        super.touchesBegan(touches, withEvent: event)
    }
    
    // MARK: Login action
    @IBAction func doLogin(sender: AnyObject) {
        activity.hidden = false
        ref.authUser(emailFld.text, password: passFld.text,
            withCompletionBlock: { error, authData in
                if error != nil {
                    // There was an error logging in to this account
                    self.errorTxt.hidden = false
                    if let errorCode = FAuthenticationError(rawValue: error.code) {
                        
                        switch(errorCode) {
                            
                        case .UserDoesNotExist:
                            self.errorTxt.text = "Error: Invalid user"
                        
                        case .InvalidCredentials:
                            self.errorTxt.text = "Error: Invalid email or password"
                            
                        case .InvalidEmail:
                            self.errorTxt.text = "Error: Invalid email or password"
                            
                        case .InvalidPassword:
                            self.errorTxt.text = "Error: Invalid email or password"
                            
                        default:
                            self.errorTxt.text = "Error: unknown error"
                            
                        }
                    }
                } else {
                    // We are now logged in
                    
                    // Update the APNS Alias
                    APNS().updateAlias((self.ref.authData.providerData["email"] as? String)!)
                    
                    self.dismissViewControllerAnimated(true, completion: nil)
                }
                self.activity.hidden = true
        })
        
    }
    
    // MARK: Forgot password action
    @IBAction func forgetPasswdAction(sender: AnyObject) {
        
        if emailFld.text != "" {
            ref.resetPasswordForUser(emailFld.text, withCompletionBlock: { error in
                if error != nil {
                    // There was an error processing the request
                    let passwdError = UIAlertView(title: "Error", message: "There was an error resetting your password, please try again.", delegate: nil, cancelButtonTitle: "OK")
                    passwdError.show()
                } else {
                    // Password reset sent successfully
                    let emailError = UIAlertView(title: "Success", message: "Plesae check your email for instructions on resetting your password.", delegate: nil, cancelButtonTitle: "OK")
                    emailError.show()
                }
            })
        } else {
            let emailError = UIAlertView(title: "Error", message: "Please enter your email address and click \"I forgot my password\" again.", delegate: nil, cancelButtonTitle: "OK")
            emailError.show()
        }
        
        
        
    }
    
}
