//
//  ViewReminderViewController.swift
//  MightyMinders
//
//  Created by Justin Bane on 7/11/15.
//  Copyright (c) 2015 Justin Bane. All rights reserved.
//

import UIKit

class ViewReminderViewController: MMCustomViewController {
    
    let ref = Firebase(url: "https://mightyminders.firebaseio.com/")
    
    var reminderText: String!
    var reminderIdentifier: String!
    var completeReminder: Bool = false
    var timingText: String!
    var selectedFriendFromView: String!
    var setByFromView: String!
    
    @IBOutlet weak var minderLbl: UILabel!
    @IBOutlet weak var completeBtn: UIButton!
    @IBOutlet weak var repeatBtn: UIButton!
    @IBOutlet weak var timingLbl: UILabel!
    @IBOutlet weak var closeBtn: UIButton!
    @IBOutlet weak var setByLbl: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        minderLbl.text = reminderText
        timingLbl.text = timingText
        
        if !(selectedFriendFromView.isEmpty) {
            setByLbl.hidden = false
            let friendRef = ref.childByAppendingPath("users/\(selectedFriendFromView)")
            friendRef.observeSingleEventOfType(.Value, withBlock: { (snapshot) -> Void in
                // set data from location controller
                let first_name: String = snapshot.value.objectForKey("first_name") as! String
                let last_name: String = snapshot.value.objectForKey("last_name") as! String
                
                if self.ref.authData.uid != self.selectedFriendFromView {
                    self.setByLbl.text = "Set for: \(first_name) \(last_name)"
                } else {
                    let setForRef = self.ref.childByAppendingPath("users/\(self.setByFromView)")
                    setForRef.observeSingleEventOfType(.Value, withBlock: { (snapshot) -> Void in
                        let first_name: String = snapshot.value.objectForKey("first_name") as! String
                        let last_name: String = snapshot.value.objectForKey("last_name") as! String
                        self.setByLbl.text = "Set for you by: \(first_name) \(last_name)"
                    })
                }
                
            })
        }
        
    }
    
    override func viewDidAppear(animated: Bool) {
        // check for valid user
        if ref.authData == nil {
            super.showLogin()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func closeBtnAction(sender: AnyObject) {
        completeReminder = false
    }
    
    @IBAction func completeBtnAction(sender: AnyObject) {
        completeReminder = true
    }
    
    
    // Segues
    
    override func shouldPerformSegueWithIdentifier(identifier: String, sender: AnyObject?) -> Bool {
        self.dismissViewControllerAnimated(true, completion: nil)
        return true
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
