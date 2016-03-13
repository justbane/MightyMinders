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
    @IBOutlet weak var closeBtn: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        activity.hidden = true
        if isModal() {
            closeBtn.hidden = false
        }
        
        // setup swipe down to hide keyboard
        let swipe: UISwipeGestureRecognizer = UISwipeGestureRecognizer(target: self, action: "dismissKeyboard")
        swipe.direction = UISwipeGestureRecognizerDirection.Down
        self.view.addGestureRecognizer(swipe)
        
    }
    
    override func viewWillAppear(animated: Bool) {
        // check for valid user
        if ref.authData == nil {
            super.showLogin()
        } else {
            // if selected friend exits
            if !selectedFriend.isEmpty {
                let first_name: String = selectedFriend["first_name"]! as! String
                let last_name: String = selectedFriend["last_name"]! as! String
                addFriendBtn.setTitle("\(first_name) \(last_name)", forState: .Normal)
            }
            
            // Setup interface values if editing a reminder
            if reminderIdentifier != nil {
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
                    ref.childByAppendingPath("users/\(selectedFriendFromView)").observeSingleEventOfType(.Value, withBlock: { (snapshot) -> Void in
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
    }
    
    override func viewDidAppear(animated: Bool) {
        // view is shown again
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
    
    func closeViewController() {
        
        if isModal() {
            self.dismissViewControllerAnimated(true, completion: nil)
        } else {
            self.navigationController?.popViewControllerAnimated(true)
        }
        
    }
    
    @IBAction func closeBtnAction(sender: AnyObject) {
        
        closeViewController()
        
    }
    
    @IBAction func addReminder(sender: AnyObject) {
        
        activity.hidden = false
        activity.startAnimating()
        
        let setFor = (selectedFriend.count > 0 ? selectedFriend["id"] : ref.authData.uid) as! String
        
        // validate
        if selectedLocation.count < 1 || reminderTxt.text == "" {
            
            //check for the location
            let locationError = UIAlertView(title: "Error", message: "Please select a location and enter some reminder text", delegate: nil, cancelButtonTitle: "OK")
            locationError.show()
        
        } else {
            
            // FIXME: need to complete add request then update
            
            // save to firebase if editing else if adding new
//            if let identifier = reminderIdentifier {
//                usersMindersRef.updateChildValues(userMinder as [NSObject : AnyObject], withCompletionBlock: { (error:NSError?, ref:Firebase!) in
//                    if error != nil {
//                        let saveError = UIAlertView(title: "Error", message: "An error occured saving the reminder", delegate: nil, cancelButtonTitle: "OK")
//                        saveError.show()
//                    } else {
//                        self.activity.hidden = true
//                        self.activity.stopAnimating()
//                        self.closeViewController()
//                    }
//                })
//
//                // remove minder from private if adding a friend
//                if (selectedFriend.count > 0 && selectedFriend["id"] as! String != ref.authData.uid as String) {
//                    let usersMinderRemove = ref.childByAppendingPath("minders/\(ref.authData.uid)/private/\(identifier)")
//                    usersMinderRemove.removeValue()
//                    sendReminderNotification(userMinder)
//                }
                
//            } else {
            
                // FIXME: This works but does not complete.
                
                Minders().addReminder(reminderTxt.text, location: selectedLocation, timing: whenSelector.selectedSegmentIndex, setBy: ref.authData.uid, setFor: setFor, completion: { (returnedMinder, error) -> Void in
                    self.sendReminderNotification(returnedMinder)
                })
                
//            }
            
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
                    }
                    
                })
                
            })
            
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
    
    func isModal() -> Bool {
        if((self.presentingViewController) != nil) {
            return true
        }
        
        if(self.presentingViewController?.presentedViewController == self) {
            return true
        }
        
        if(self.navigationController?.presentingViewController?.presentedViewController == self.navigationController) {
            return true
        }
        
        if((self.tabBarController?.presentingViewController?.isKindOfClass(UITabBarController)) != nil) {
            return true
        }
        
        return false
    }

}
