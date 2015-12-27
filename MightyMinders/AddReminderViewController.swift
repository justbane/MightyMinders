//
//  AddReminderViewController.swift
//  MightyMinders
//
//  Created by Justin Bane on 5/6/15.
//  Copyright (c) 2015 Justin Bane. All rights reserved.
//

import UIKit

class AddReminderViewController: MMCustomViewController {

    let ref = Firebase(url: "https://mightyminders.firebaseio.com/")
    let userDefaults = NSUserDefaults.standardUserDefaults()
    
    var selectedLocation = [String: AnyObject]()
    var selectedFriend = [String: AnyObject]()
    
    // values from view if editing
    var reminderIdentifier: String!
    var reminderTextFromView: String!
    var reminderTimingFromView: Int!
    var reminderFriendFromView: String!
    var selectedLocationFromView = [String: AnyObject]()
    var selectedFriendFromView: String!
    
    @IBOutlet weak var screenTitleLbl: UILabel!
    @IBOutlet weak var reminderTxt: UITextView!
    @IBOutlet weak var addReminderBtn: AddRemoveButtonView!
    
    @IBOutlet weak var addLocationBtn: UIButton!
    @IBOutlet weak var addFriendBtn: UIButton!
    @IBOutlet weak var whenSelector: UISegmentedControl!
    @IBOutlet weak var activity: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        activity.hidden = true
        
        // setup swipe down to hide keyboard
        let swipe: UISwipeGestureRecognizer = UISwipeGestureRecognizer(target: self, action: "dismissKeyboard")
        swipe.direction = UISwipeGestureRecognizerDirection.Down
        self.view.addGestureRecognizer(swipe)
        
        
        // Setup interface values if editing a reminder -- FIXME!
        if let _ = reminderIdentifier {
            screenTitleLbl.text = "Edit Reminder"
            
            reminderTxt.text = reminderTextFromView
            whenSelector.selectedSegmentIndex = reminderTimingFromView
            selectedLocation = selectedLocationFromView
            
            if let selectedName = selectedLocationFromView["name"] as? String {
                addLocationBtn.setTitle(selectedName, forState: .Normal)
            }
            
            if let selectedAddress = selectedLocationFromView["address"] as? String {
                let curText = addLocationBtn.titleForState(.Normal)!
                addLocationBtn.setTitle("\(curText) at \(selectedAddress)", forState: .Normal)
            }
            
            if !(selectedFriendFromView.isEmpty) && selectedFriendFromView != ref.authData.uid {
                let friendRef = ref.childByAppendingPath("users/\(selectedFriendFromView)")
                friendRef.observeSingleEventOfType(.Value, withBlock: { (snapshot) -> Void in
                    // set data from location controller
                    
                    let first_name: String = snapshot.value.objectForKey("first_name") as! String
                    let last_name: String = snapshot.value.objectForKey("last_name") as! String
                    self.addFriendBtn.setTitle("\(first_name) \(last_name)", forState: .Normal)
                    
                    // set local selectedLocation
                    self.selectedFriend = [
                        "id": snapshot.key,
                        "first_name": first_name,
                        "last_name": last_name
                    ]
                })
            }
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        // view is shown again
        // check for valid user
        if ref.authData == nil {
            super.showLogin()
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        view.endEditing(true)
        super.touchesBegan(touches, withEvent: event)
    }
    
    func dismissKeyboard() {
        
        reminderTxt.resignFirstResponder()
        
    }
    
    @IBAction func addReminder(sender: AnyObject) {
        
        activity.hidden = false
        
        let userMinder = [
            "content": reminderTxt.text,
            "location": selectedLocation,
            "timing": whenSelector.selectedSegmentIndex,
            "set-by": ref.authData.uid as String,
            "set-for": (selectedFriend.count > 0 ? selectedFriend["id"] : ref.authData.uid) as! String
        ]
        
        // set the ref path
        var usersMindersRef = ref.childByAppendingPath("minders/\(ref.authData.uid)/private")
        
        // are we editing?
        if let identifier = reminderIdentifier {
            usersMindersRef = ref.childByAppendingPath("minders/\(ref.authData.uid)/private/\(identifier)")
        }
        
        // is there a friend selected?
        if selectedFriend.count > 0 {
            usersMindersRef = ref.childByAppendingPath("shared-minders")
            
            // is there a friend and we are editing?
            if let identifier = reminderIdentifier {
                usersMindersRef = ref.childByAppendingPath("shared-minders/\(identifier)")
            }
        
        }
        
        // validate
        if selectedLocation.count < 1 || reminderTxt.text == "" {
            
            //check for the location
            let locationError = UIAlertView(title: "Error", message: "Please select a location and enter some reminder text", delegate: nil, cancelButtonTitle: "OK")
            locationError.show()
        
        } else {
            
            // save to firebase if editing else if adding new
            if let identifier = reminderIdentifier {
                usersMindersRef.updateChildValues(userMinder as [NSObject : AnyObject], withCompletionBlock: { (error:NSError?, ref:Firebase!) in
                    if error != nil {
                        let saveError = UIAlertView(title: "Error", message: "An error occured saving the reminder", delegate: nil, cancelButtonTitle: "OK")
                        saveError.show()
                    } else {
                        self.activity.hidden = true
                        self.navigationController?.popViewControllerAnimated(true)
                    }
                })
                
                // remove minder from private if adding a friend
                if (self.selectedFriend.count > 0 && selectedFriend["id"] as! String != ref.authData.uid as String) {
                    let usersMinderRemove = ref.childByAppendingPath("minders/\(ref.authData.uid)/private/\(identifier)")
                    usersMinderRemove.removeValue()
                    self.sendReminderNotification(userMinder)
                }
                
            } else {
                let usersMindersRefAuto = usersMindersRef.childByAutoId()
                usersMindersRefAuto.setValue(userMinder, withCompletionBlock: { (error:NSError?, ref:Firebase!) in
                    if error != nil {
                        let saveError = UIAlertView(title: "Error", message: "An error occured saving the reminder", delegate: nil, cancelButtonTitle: "OK")
                        saveError.show()
                    } else {
                        self.sendReminderNotification(userMinder)
                    }
                })
                
            }
            
        }
    }
    
    func sendReminderNotification(userMinder: NSDictionary) {
        
        if ref.authData.uid as String != userMinder["set-for"] as! String {
            
            let restReq = HTTPRequests()
            let setBy = userMinder["set-by"] as! String
            let setFor = userMinder["set-for"] as! String
            let content = userMinder["content"] as! String
            
            var senderName: String = "Someone"
            
            // get sender profile data
            let setByRef = self.ref.childByAppendingPath("users/\(setBy)")
            setByRef.observeSingleEventOfType(.Value, withBlock: { (snapshot) -> Void in
                let first_name: String = snapshot.value.objectForKey("first_name") as! String
                let last_name: String = snapshot.value.objectForKey("last_name") as! String
                senderName = "\(first_name) \(last_name)"
                
                // go reciever profile
                let setForRef = self.ref.childByAppendingPath("users/\(setFor)")
                setForRef.observeSingleEventOfType(.Value, withBlock: { (snapshot) -> Void in
                    let email: String = snapshot.value.objectForKey("email_address") as! String
                    
                    let data: [String: [String: AnyObject]] = [
                        "message": [
                            "alert": "\(senderName) set a reminder for you - Swipe to Accept: \(content)",
                            "sound": "default",
                            "apns": [
                                "action-category": "MAIN_CATEGORY",
                                "url-args" :["\(self.selectedLocation["latitude"]!)","\(self.selectedLocation["longitude"]!)"]
                            ]
                        ],
                        "criteria": [
                            "alias": ["\(email)"],
                            "variants": ["\(self.userDefaults.valueForKey("variantID") as! String)"]
                        ]
                    ]
                    
                    // send to push server
                    restReq.sendPostRequest(data, url: "https://push-baneville.rhcloud.com/ag-push/rest/sender") { (success, msg) -> () in
                        // completion code here
                        // println(success)
                        
                        let status = msg["status"] as! String
                        if status.containsString("FAILURE") {
                            print(status)
                        }
                        // dismiss
                        self.activity.hidden = true
                        self.navigationController?.popViewControllerAnimated(true)
                        
                    }
                    
                })
                
            })
            
        } else {
            self.activity.hidden = true
            navigationController?.popViewControllerAnimated(true)
        }
    }
    
    @IBAction func unwindFromLocationSelection(segue: UIStoryboardSegue) {
        
        let locationController = segue.sourceViewController as! AddLocationViewController
        
        if segue.identifier == "LocationUnwindSegue" {
            
            // set data from location controller
            let nameForLocation = locationController.selectedLocation["name"] as! String == "My current location" ? "Dropped pin" : locationController.selectedLocation["name"] as! String
            locationController.selectedLocation["name"] = nameForLocation
            
            var name: String = nameForLocation
            if let address: String = locationController.selectedLocation["address"] as? String {
                name += " at \(address)"
            }
            addLocationBtn.setTitle("\(name)", forState: .Normal)
            
            // set local selectedLocation
            selectedLocation = locationController.selectedLocation
        }
        
    }
    
    @IBAction func unwindFromFriendSelection(segue: UIStoryboardSegue) {
        
        let friendController = segue.sourceViewController as! AddFriendViewController
        
        if segue.identifier == "AddFriendUnwindSegue" {
            
            // set data from location controller
            var friendForLocation = friendController.selectedFriend
            let first_name: String = friendForLocation["first_name"]!
            let last_name: String = friendForLocation["last_name"]!
            addFriendBtn.setTitle("\(first_name) \(last_name)", forState: .Normal)
            
            // set local selectedLocation
            selectedFriend = friendController.selectedFriend
        }
        
    }

}
