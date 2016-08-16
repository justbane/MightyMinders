//
//  AddFriendViewController.swift
//  MightyMinders
//
//  Created by Justin Bane on 9/8/15.
//  Copyright (c) 2015 Justin Bane. All rights reserved.
//

import UIKit

class AddFriendViewController: MMCustomViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate {

    let ref = FIRDatabase.database().reference()
    let userDefaults = NSUserDefaults.standardUserDefaults()
    var friendData: [FIRDataSnapshot!] = []
    var friendKeys: [String] = []
    var selectedFriend: [String: String]!
    
    @IBOutlet weak var closeBtn: UIButton!
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        // Table view setup
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorInset = UIEdgeInsetsZero
        
        // Get keys data
        let canRemindKeys = ref.child("friends/\(FIRAuth.auth()?.currentUser?.uid)/can-remind")
        canRemindKeys.observeEventType(.Value, withBlock: { (snapshot) -> Void in
            // Set object
            let enumerator = snapshot.children
            
            // Reset arrays - reset the table
            self.friendKeys.removeAll(keepCapacity: false)
            self.friendData.removeAll(keepCapacity: false)
            self.tableView.reloadData()
            
            // Iterate over data
            while let data = enumerator.nextObject() as? FIRDataSnapshot {
                self.friendKeys.append(data.key)
            }
            // Get friends
            self.getFriends()
        })
        
    }
    
    override func viewDidAppear(animated: Bool) {
        // Check for valid user
        if FIRAuth.auth()?.currentUser == nil {
            super.showLogin()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func getFriends() {
        
        // Add to friends list
        if friendKeys.count > 0 {
            // Loop over firend IDs
            for uid in friendKeys {
                let canRemindFriends = ref.child("users/\(uid)")
                canRemindFriends.observeEventType(.Value, withBlock: { snapshot in
                    self.friendData.append(snapshot)
                    if self.friendData.count > 0 {
                        // Reload the table
                        self.tableView.reloadData()
                    }
                    
                })
            }
            
        }
        
    }
    
    // MARK: Segues
    override func shouldPerformSegueWithIdentifier(identifier: String, sender: AnyObject?) -> Bool {
        
        // Check to see if segue should happen (have they selected a location?
        if identifier == "AddFriendUnwindSegue" {
            if let sendingBtn = sender as? AddRemoveButtonView {
                selectedFriend = sendingBtn.actionData
            }
        }
        
        return true
    }
    
    // MARK: Button Actions
    @IBAction func addFriendBtnAction(sender: AddRemoveButtonView) {
        
        self.dismissViewControllerAnimated(true, completion: nil)
        
    }

    @IBAction func closeBtnAction(sender: AnyObject) {
        
        self.dismissViewControllerAnimated(true, completion: nil)
        
    }
    
    // MARK: Table View Methods
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return friendData.count
    }
    
    func tableView(tableView: UITableView, estimatedHeightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier("friendsTableCell") as! FindFriendsTableViewCell
        cell.separatorInset = UIEdgeInsetsZero
        cell.layoutMargins = UIEdgeInsetsZero
        cell.preservesSuperviewLayoutMargins = false
        cell.selectionStyle = UITableViewCellSelectionStyle.None
        
        // Cell button setup
        cell.addBtn.actionData = [
            "id": friendData[indexPath.row].key,
            "first_name": friendData[indexPath.row].value!.valueForKey("first_name") as! String,
            "last_name": friendData[indexPath.row].value!.valueForKey("last_name") as! String
        ]
        cell.addBtn.addTarget(self, action: #selector(addFriendBtnAction), forControlEvents: .TouchUpInside)
        
        var name : String = ""
        
        if let firstName = friendData[indexPath.row].value!.valueForKey("first_name") as? NSString {
            name += firstName as String
        }
        
        if let lastName = friendData[indexPath.row].value!.valueForKey("last_name") as? NSString {
            name += " \(lastName)"
        }
        
        (cell.contentView.viewWithTag(101) as! UILabel).text = name
        
        if let email = friendData[indexPath.row].value!.valueForKey("email_address") as? NSString {
            (cell.contentView.viewWithTag(102) as! UILabel).text = email as String
        }
        
        // TODO: Add profile images
//        if var imageURL = contacts[indexPath.row].valueForKey("profile_img") as? NSString {
//        
//            if imageURL == "" {
//                imageURL = "/images/NoAvatar.gif"
//            }
//        
//            let urlString: NSString = "http:/internal.hdmz.com\(imageURL)"
//            let imgURL: NSURL? = NSURL(string: urlString as String)
//        
//            let request: NSURLRequest = NSURLRequest(URL: imgURL!)
//            NSURLConnection.sendAsynchronousRequest(request, queue: NSOperationQueue.mainQueue(), completionHandler: {(response: NSURLResponse!, data: NSData!, error: NSError!) -> Void in
//        
//                if error == nil {
//        
//                    dispatch_async(dispatch_get_main_queue(), {
//                        if let cellToUpdate = self.tblView.cellForRowAtIndexPath(indexPath) {
//                            var imageToUpdate = Images().roundCorners(cellToUpdate.contentView.viewWithTag(100) as! UIImageView, radiusSize: 22.5)
//                            imageToUpdate.image = UIImage(data: data)
//                            self.imageCache[imageURL as String] = UIImage(data: data)
//                        }
//                    })
//        
//                }
//        
//            })
//        
//        }
        
        // Return the cell with data
        return cell
    }

}
