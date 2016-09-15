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
    let userDefaults = UserDefaults.standard
    
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
        activity.isHidden = true
        
        // Set the background color
        // let background = Colors(colorString: "blue").getGradient()
        // background.frame = self.view.bounds
        // blueView.layer.insertSublayer(background, atIndex: 0)
        
        errorTxt!.isHidden = true
        
        emailFld.delegate = self
        passFld.delegate = self
        fnameFld.delegate = self
        lnameFld.delegate = self
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
        super.touchesBegan(touches, with: event)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
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
            fnameFld.layer.borderColor = UIColor.red.cgColor
            error = true;
        }
        
        if lnameFld.text!.isEmpty {
            lnameFld.layer.borderWidth = 1.0 as CGFloat
            lnameFld.layer.borderColor = UIColor.red.cgColor
            error = true;
        }
        
        if passFld.text!.isEmpty {
            passFld.layer.borderWidth = 1.0 as CGFloat
            passFld.layer.borderColor = UIColor.red.cgColor
            error = true;
        }
        
        if emailFld.text!.isEmpty {
            emailFld.layer.borderWidth = 1.0 as CGFloat
            emailFld.layer.borderColor = UIColor.red.cgColor
            error = true;
        }
        
        if error {
            return false
        }
        
        return true
    }
    
    // MARK: Actions
    @IBAction func doRegistration(_ sender: AnyObject) {
        
        activity.isHidden = false
        
        if (validate() && FIRAuth.auth()?.currentUser == nil) {
            FIRAuth.auth()?.createUser(withEmail: emailFld.text!, password: passFld.text!,
                completion: { (user, error) in
                    
                    if error != nil {
                        self.errorTxt.isHidden = false
                        if let errorCode = FIRAuthErrorCode(rawValue: error!.code) {
                            
                            switch(errorCode) {
                                
                            case .errorCodeEmailAlreadyInUse:
                                self.errorTxt.text = "Error: This email is already in use!"
                                self.emailFld.layer.borderWidth = 1.0 as CGFloat
                                self.emailFld.layer.borderColor = UIColor.red.cgColor
                                
                            case .errorCodeInvalidEmail:
                                self.errorTxt.text = "Error: This email is invalid. Please follow the user@domain.com format."
                                self.emailFld.layer.borderWidth = 1.0 as CGFloat
                                self.emailFld.layer.borderColor = UIColor.red.cgColor
                                
                            default:
                                self.errorTxt.text = "Error: Unknown Error!"
                                
                            }
                            
                        }
                        
                    } else {
                        
                        if user?.uid != nil {
                            
                            // Update device token
                            self.ref.child("devices").child((FIRAuth.auth()?.currentUser?.uid)!).setValue(["token": FIRInstanceID.instanceID().token()!])
                            
                            Users(currentEmail: self.emailFld.text! as String, currentFirstName: self.fnameFld.text! as String, currentLastName: self.lnameFld.text! as String).updateProfileData({ (error) -> Void in
                                if error {
                                    
                                    self.errorTxt?.text = "Error: Please fill in all fields!"
                                    self.errorTxt.isHidden = false
                                    
                                } else {
                                    
                                    self.errorTxt?.text = "Success"
                                    self.errorTxt.textColor = UIColor.green
                                    self.errorTxt.isHidden = false
                                    
                                    self.dismiss(animated: true, completion: nil)
                                }
                                self.activity.isHidden = true
                            })
                            
                        }
                        
                    }
                    
            })
            
        } else {
            
            self.errorTxt?.text = "Error: Please fill in all fields!"
            self.errorTxt.isHidden = false
            activity.isHidden = true
            
        }
    }
    
    
    // End Class
}
