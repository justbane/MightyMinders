//
//  LoginViewController.swift
//  MightyMinders
//
//  Created by Justin Bane on 4/23/15.
//  Copyright (c) 2015 Justin Bane. All rights reserved.
//

import UIKit

class LoginViewController: UIViewController {

    let ref = Firebase(url: "https://mightyminders.firebaseio.com")
    
    @IBOutlet weak var emailFld: UITextField!
    @IBOutlet weak var passFld: UITextField!
    @IBOutlet weak var loginBtn: UIButton!
    @IBOutlet weak var registerBtn: UIButton!
    @IBOutlet weak var errorTxt: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
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
                    self.dismissViewControllerAnimated(true, completion: nil)
                }
        })
        
    }
    
}
