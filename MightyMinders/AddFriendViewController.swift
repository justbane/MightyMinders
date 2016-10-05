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
    let userDefaults = UserDefaults.standard
    var friendData: [FIRDataSnapshot?] = []
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
        tableView.separatorInset = UIEdgeInsets.zero
        
        // Get keys data
        let canRemindKeys = ref.child("friends").child((FIRAuth.auth()?.currentUser?.uid)!).child("can-remind")
        canRemindKeys.observe(.value, with: { (snapshot) -> Void in
            // Set object
            let enumerator = snapshot.children
            
            // Reset arrays - reset the table
            self.friendKeys.removeAll(keepingCapacity: false)
            self.friendData.removeAll(keepingCapacity: false)
            self.tableView.reloadData()
            
            // Iterate over data
            while let data = enumerator.nextObject() as? FIRDataSnapshot {
                self.friendKeys.append(data.key)
            }
            // Get friends
            self.getFriends()
        })
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
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
                canRemindFriends.observe(.value, with: { snapshot in
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
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        
        // Check to see if segue should happen (have they selected a location?
        if identifier == "AddFriendUnwindSegue" {
            if let sendingBtn = sender as? AddRemoveButtonView {
                selectedFriend = sendingBtn.actionData
            }
        }
        
        return true
    }
    
    // MARK: Button Actions
    @IBAction func addFriendBtnAction(_ sender: AddRemoveButtonView) {
        
        self.dismiss(animated: true, completion: nil)
        
    }

    @IBAction func closeBtnAction(_ sender: AnyObject) {
        
        self.dismiss(animated: true, completion: nil)
        
    }
    
    // MARK: Table View Methods
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return friendData.count
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "friendsTableCell") as! FindFriendsTableViewCell
        cell.separatorInset = UIEdgeInsets.zero
        cell.layoutMargins = UIEdgeInsets.zero
        cell.preservesSuperviewLayoutMargins = false
        cell.selectionStyle = UITableViewCellSelectionStyle.none
        
        let cellData = friendData[indexPath.row]?.value as! [String: AnyObject]
        
        // Cell button setup
        // Cell button setup
        cell.addBtn.actionData = [
            "id": (friendData[indexPath.row]?.key)!,
            "first_name": cellData["first_name"] as! String,
            "last_name": cellData["last_name"] as! String
        ]
        
        cell.addBtn.addTarget(self, action: #selector(addFriendBtnAction), for: .touchUpInside)
        
        var name: String = ""
        
        if let firstName = cellData["first_name"] {
            name += "\(firstName)"
        }
        
        if let lastName = cellData["last_name"] {
            name += " \(lastName)"
        }
        
        (cell.contentView.viewWithTag(101) as! UILabel).text = name
        
        if let email = cellData["email_address"] as? String {
            (cell.contentView.viewWithTag(102) as! UILabel).text = email
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
