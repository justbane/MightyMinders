//
//  RemindFriendsViewController.swift
//  MightyMinders
//
//  Created by Justin Bane on 8/9/15.
//  Copyright (c) 2015 Justin Bane. All rights reserved.
//

import UIKit

class RemindFriendsViewController: MMCustomViewController, UITableViewDelegate, UITableViewDataSource {

    let ref = Firebase(url: "https://mightyminders.firebaseio.com/")
    let userDefaults = NSUserDefaults.standardUserDefaults()
    var friendData: [FDataSnapshot!] = []
    var friendKeys: [String] = []
    var selectedFriend: [String: String]!
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var friendsActivity: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        // table view setup
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorInset = UIEdgeInsetsZero
        
    }
    
    override func viewDidAppear(animated: Bool) {
        
        // friends activity
        friendsActivity.startAnimating()
        friendsActivity.hidden = false
        
        if ref.authData == nil {
            super.showLogin()
        } else {
            // get keys data
            let canRemindKeys = ref.childByAppendingPath("friends/\(ref.authData.uid)/can-remind")
            canRemindKeys.observeEventType(.Value, withBlock: { (snapshot) -> Void in
                // set object
                let enumerator = snapshot.children
                
                // reset arrays - reset the table
                self.friendKeys.removeAll(keepCapacity: false)
                self.friendData.removeAll(keepCapacity: false)
                self.tableView.reloadData()
                
                // iterate over data
                while let data = enumerator.nextObject() as? FDataSnapshot {
                    self.friendKeys.append(data.key)
                }
                // get friends
                self.getFriends()
                
                // hide activity
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
        
        // add to friends list
        if friendKeys.count > 0 {
            // loop over firend IDs
            for uid in friendKeys {
                let canRemindFriends = ref.childByAppendingPath("users/\(uid)")
                canRemindFriends.observeEventType(.Value, withBlock: { snapshot in
                    self.friendData.append(snapshot)
                    if self.friendData.count > 0 {
                        // reload the table
                        self.tableView.reloadData()
                    }
                })
            }
            
        }
        
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "SelectedFriendSegue" {
            let addReminderViewController = segue.destinationViewController as! AddReminderViewController
            if let sendingBtn = sender as? AddRemoveButtonView {
                addReminderViewController.selectedFriend = sendingBtn.actionData
            }
        }
    }
    
    
    // tableView requirements
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return friendData.count
    }
    
    func tableView(tableView: UITableView, estimatedHeightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier("iCanRemindCell") as! FindFriendsTableViewCell
        cell.separatorInset = UIEdgeInsetsZero
        cell.layoutMargins = UIEdgeInsetsZero
        cell.preservesSuperviewLayoutMargins = false
        cell.selectionStyle = UITableViewCellSelectionStyle.None
        
        // cell button setup
        cell.addBtn.actionData = [
            "id": friendData[indexPath.row].key,
            "first_name": friendData[indexPath.row].value.valueForKey("first_name") as! String,
            "last_name": friendData[indexPath.row].value.valueForKey("last_name") as! String
        ]
        
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
        /*if var imageURL = contacts[indexPath.row].valueForKey("profile_img") as? NSString {
            
            if imageURL == "" {
                imageURL = "/images/NoAvatar.gif"
            }
            
            let urlString: NSString = "http:/internal.hdmz.com\(imageURL)"
            let imgURL: NSURL? = NSURL(string: urlString as String)
            
            let request: NSURLRequest = NSURLRequest(URL: imgURL!)
            NSURLConnection.sendAsynchronousRequest(request, queue: NSOperationQueue.mainQueue(), completionHandler: {(response: NSURLResponse!, data: NSData!, error: NSError!) -> Void in
                
                if error == nil {
                    
                    dispatch_async(dispatch_get_main_queue(), {
                        if let cellToUpdate = self.tblView.cellForRowAtIndexPath(indexPath) {
                            var imageToUpdate = Images().roundCorners(cellToUpdate.contentView.viewWithTag(100) as! UIImageView, radiusSize: 22.5)
                            imageToUpdate.image = UIImage(data: data)
                            self.imageCache[imageURL as String] = UIImage(data: data)
                        }
                    })
                    
                }
                
            })
            
        }*/
        
        // return the cell with data
        return cell
    }
    
}
