//
//  FriendsRemindViewController.swift
//  MightyMinders
//
//  Created by Justin Bane on 8/22/15.
//  Copyright (c) 2015 Justin Bane. All rights reserved.
//

import UIKit

class FriendsRemindViewController: MMCustomViewController, UITableViewDelegate, UITableViewDataSource {

    let ref = Firebase(url: "https://mightyminders.firebaseio.com/")
    let userDefaults = NSUserDefaults.standardUserDefaults()
    var friendData: [FDataSnapshot!] = []
    var friendKeys: [String] = []
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var friendsActivity: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        
        // Table view setup
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorInset = UIEdgeInsetsZero
        
    }
    
    override func viewDidAppear(animated: Bool) {
        
        // Show the activity
        friendsActivity.startAnimating()
        friendsActivity.hidden = false
        
        if ref.authData == nil {
            super.showLogin()
        } else {
            // Get the friend keys
            Friends().getFriendKeysThatRemindMe({ (friendsRemindMe) -> Void in
                // Set object
                let enumerator = friendsRemindMe.children
                
                // Reset arrays - reset the table
                self.friendKeys.removeAll(keepCapacity: false)
                self.friendData.removeAll(keepCapacity: false)
                self.tableView.reloadData()
                
                // Iterate over data
                while let data = enumerator.nextObject() as? FDataSnapshot {
                    self.friendKeys.append(data.key)
                }
                // Get friends
                self.getFriends()
                
                // Hide the activity
                self.friendsActivity.stopAnimating()
                self.friendsActivity.hidden = true
            })
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func getFriends() {
        
        if friendKeys.count > 0 {
            // Loop over friend IDs
            for uid in friendKeys {
                Friends().getFriends(uid, completion: { (friendsData) -> Void in
                    self.friendData.append(friendsData)
                    if self.friendData.count > 0 {
                        // Reload the table
                        self.tableView.reloadData()
                    }
                })
            }
            
        }
        
    }
    
    @IBAction func removeBtnAction(sender: CustomButton) {
        
        if (sender.actionData != nil) {
            
            // Remove from my allowed list
            Friends().removeFriendAccess(sender.actionData)
            
            // Remove from their can remind list
            Friends().removeMeFromCanRemindList(sender.actionData)
            
        }
        
    }
    
    // MARK: TableView requirements
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return friendData.count
    }
    
    
    func tableView(tableView: UITableView, estimatedHeightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier("canRemindMeCell") as! FindFriendsTableViewCell
        cell.separatorInset = UIEdgeInsetsZero
        cell.layoutMargins = UIEdgeInsetsZero
        cell.preservesSuperviewLayoutMargins = false
        cell.selectionStyle = UITableViewCellSelectionStyle.None
        
        // Cell button setup
        cell.allowBtn.actionData = friendData[indexPath.row].key
        cell.allowBtn.addTarget(self, action: #selector(removeBtnAction), forControlEvents: .TouchUpInside)
        
        var name : String = ""
        
        if let firstName = friendData[indexPath.row].value.valueForKey("first_name") as? NSString {
            name += firstName as String
        }
        
        if let lastName = friendData[indexPath.row].value.valueForKey("last_name") as? NSString {
            name += " \(lastName)"
        }
        
        (cell.contentView.viewWithTag(101) as! UILabel).text = name
        
        if let email = friendData[indexPath.row].value.valueForKey("email_address") as? NSString {
            (cell.contentView.viewWithTag(102) as! UILabel).text = email as String
        }
        
        // TODO - add profile images 
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
