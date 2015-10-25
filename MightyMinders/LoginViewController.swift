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
            // user authenticated with Firebase
            self.dismissViewControllerAnimated(true, completion: nil)
        }
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        view.endEditing(true)
        super.touchesBegan(touches, withEvent: event)
    }
    
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
                    
                    let registration = AGDeviceRegistration(serverURL: NSURL(string: "https://push-baneville.rhcloud.com/ag-push/")!)
                    
                    registration.registerWithClientInfo({ (clientInfo: AGClientDeviceInformation!)  in
                        
                        // apply the token, to identify this device
                        clientInfo.deviceToken = self.userDefaults.objectForKey("deviceToken") as? NSData
                        
                        clientInfo.variantID = "eb234d8c-1829-483b-ad2a-a855eeacc2b2"
                        clientInfo.variantSecret = "2f2f8f44-a6ba-40f4-b8a1-fc06ac367315"
                        
                        // --optional config--
                        // set some 'useful' hardware information params
                        clientInfo.alias = self.ref.authData.providerData["email"] as? String
                        
                        }, success: {
                            print("device alias updated");
                            
                        }, failure: { (error:NSError!) -> () in
                            print("device alias update error: \(error.localizedDescription)")
                    })
                    
                    
                    self.dismissViewControllerAnimated(true, completion: nil)
                }
                self.activity.hidden = true
        })
        
    }
    
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
            let emailError = UIAlertView(title: "Error", message: "Please enter you email address and click \"I forgot my password\" again.", delegate: nil, cancelButtonTitle: "OK")
            emailError.show()
        }
        
        
        
    }
    
}
