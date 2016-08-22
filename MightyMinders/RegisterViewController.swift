//
//  RegisterViewController.swift
//  MightyMinders
//
//  Created by Justin Bane on 4/26/15.
//  Copyright (c) 2015 Justin Bane. All rights reserved.
//

import UIKit

class RegisterViewController: UIViewController, UITextFieldDelegate {

    let ref = FIRDatabase.database().reference()
    let userDefaults = NSUserDefaults.standardUserDefaults()
    
    @IBOutlet weak var emailFld: UITextField!
    @IBOutlet weak var passFld: UITextField!
    @IBOutlet weak var submitBtn: UIButton!
    @IBOutlet weak var errorTxt: UILabel!
    @IBOutlet weak var fnameFld: UITextField!
    @IBOutlet weak var lnameFld: UITextField! = nil
    
    @IBOutlet weak var blueView: UIView!
    @IBOutlet weak var activity: UIActivityIndicatorView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        activity.hidden = true
        
        // Set the background color
        // let background = Colors(colorString: "blue").getGradient()
        // background.frame = self.view.bounds
        // blueView.layer.insertSublayer(background, atIndex: 0)
        
        errorTxt!.hidden = true
        
        emailFld.delegate = self
        passFld.delegate = self
        fnameFld.delegate = self
        lnameFld.delegate = self
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        view.endEditing(true)
        super.touchesBegan(touches, withEvent: event)
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        
        switch textField
        {
        case emailFld:
            passFld.becomeFirstResponder()
            break
        case passFld:
            fnameFld.becomeFirstResponder()
            break
        case fnameFld:
            lnameFld.becomeFirstResponder()
            break
        case lnameFld:
            self.view.endEditing(true)
            break
        default:
            textField.resignFirstResponder()
        }
        return true
        
    }
    
    // MARK: Validate
    func validate() -> Bool {
        
        var error = false
        
        if fnameFld.text!.isEmpty {
            fnameFld.layer.borderWidth = 1.0 as CGFloat
            fnameFld.layer.borderColor = UIColor.redColor().CGColor
            error = true;
        }
        
        if lnameFld.text!.isEmpty {
            lnameFld.layer.borderWidth = 1.0 as CGFloat
            lnameFld.layer.borderColor = UIColor.redColor().CGColor
            error = true;
        }
        
        if passFld.text!.isEmpty {
            passFld.layer.borderWidth = 1.0 as CGFloat
            passFld.layer.borderColor = UIColor.redColor().CGColor
            error = true;
        }
        
        if emailFld.text!.isEmpty {
            emailFld.layer.borderWidth = 1.0 as CGFloat
            emailFld.layer.borderColor = UIColor.redColor().CGColor
            error = true;
        }
        
        if error {
            return false
        }
        
        return true
    }
    
    // MARK: Actions
    @IBAction func doRegistration(sender: AnyObject) {
        
        activity.hidden = false
        
        if (validate() && FIRAuth.auth()?.currentUser == nil) {
            FIRAuth.auth()?.createUserWithEmail(emailFld.text!, password: passFld.text!,
                completion: { (user, error) in
                    
                    if error != nil {
                        self.errorTxt.hidden = false
                        if let errorCode = FIRAuthErrorCode(rawValue: error!.code) {
                            
                            switch(errorCode) {
                                
                            case .ErrorCodeEmailAlreadyInUse:
                                self.errorTxt.text = "Error: This email is already in use!"
                                self.emailFld.layer.borderWidth = 1.0 as CGFloat
                                self.emailFld.layer.borderColor = UIColor.redColor().CGColor
                                
                            case .ErrorCodeInvalidEmail:
                                self.errorTxt.text = "Error: This email is invalid. Please follow the user@domain.com format."
                                self.emailFld.layer.borderWidth = 1.0 as CGFloat
                                self.emailFld.layer.borderColor = UIColor.redColor().CGColor
                                
                            default:
                                self.errorTxt.text = "Error: Unknown Error!"
                                
                            }
                            
                        }
                        
                    } else {
                        
                        if user?.uid != nil {
                            
                            // We are now logged in
//                            let registration = AGDeviceRegistration(serverURL: NSURL(string: "https://push-baneville.rhcloud.com/ag-push/")!)
                            
//                            registration.registerWithClientInfo({ (clientInfo: AGClientDeviceInformation!)  in
//                                
//                                // Apply the token, to identify this device
//                                clientInfo.deviceToken = self.userDefaults.objectForKey("deviceToken") as? NSData
//                                
//                                clientInfo.variantID = self.userDefaults.valueForKey("variantID") as? String
//                                clientInfo.variantSecret = self.userDefaults.valueForKey("variantSecret") as? String
//                                
//                                // --optional config--
//                                // Set some 'useful' hardware information params
//                                clientInfo.alias = (user?.email)!
//                                self.userDefaults.setValue((user?.email)!, forKey: "storedUserEmail")
//                                
//                                }, success: {
//                                    print("device alias updated");
//                                    
//                                }, failure: { (error:NSError!) -> () in
//                                    print("device alias update error: \(error.localizedDescription)")
//                            })
                            
                            Users(currentEmail: self.emailFld.text! as String, currentFirstName: self.fnameFld.text! as String, currentLastName: self.lnameFld.text! as String).updateProfileData({ (error) -> Void in
                                if error {
                                    
                                    self.errorTxt?.text = "Error: Please fill in all fields!"
                                    self.errorTxt.hidden = false
                                    
                                } else {
                                    
                                    self.errorTxt?.text = "Success"
                                    self.errorTxt.textColor = UIColor.greenColor()
                                    self.errorTxt.hidden = false
                                    
                                    self.dismissViewControllerAnimated(true, completion: nil)
                                }
                                self.activity.hidden = true
                            })
                            
                        }
                        
                    }
                    
            })
            
        } else {
            
            self.errorTxt?.text = "Error: Please fill in all fields!"
            self.errorTxt.hidden = false
            activity.hidden = true
            
        }
    }
    
    
    // End Class
}
