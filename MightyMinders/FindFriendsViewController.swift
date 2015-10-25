//
//  FindFriendsViewController.swift
//  MightyMinders
//
//  Created by Justin Bane on 8/12/15.
//  Copyright (c) 2015 Justin Bane. All rights reserved.
//

import UIKit

class FindFriendsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate {

    let ref = Firebase(url: "https://mightyminders.firebaseio.com/")
    
    var searchActive: Bool = false;
    var friendData: [FDataSnapshot!] = []
    var searchDataCount: Int = 0
    var currentFriends = Set<String>()
    
    @IBOutlet weak var closeBtn: UIButton!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        // table view setup
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorInset = UIEdgeInsetsZero
        
        // setup searchbar
        searchBar.delegate = self
        searchBar.keyboardAppearance = UIKeyboardAppearance.Dark
        searchBar.autocapitalizationType = UITextAutocapitalizationType.None
        
        // get current friends
        let currentFriendsRef = ref.childByAppendingPath("friends/\(ref.authData.uid)/remind-me")
        currentFriendsRef.observeEventType(.Value, withBlock: { (snapshot) -> Void in
            let enumerator = snapshot.children
            while let data = enumerator.nextObject() as? FDataSnapshot {
                //println(data.key)
                self.currentFriends.insert(data.key)
            }
        })
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func closeBtnAction(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func allowBtnAction(sender: CustomButton) {
        
        var errors = false
        
        if (sender.actionData != nil) {
            
            // add to my allowed list
            let remindMeRef = ref.childByAppendingPath("friends/\(ref.authData.uid)/remind-me")
            remindMeRef.updateChildValues([sender.actionData: "true"] as [NSObject : AnyObject], withCompletionBlock: { (error:NSError?, ref:Firebase!) in
                if error != nil {
                    let saveError = UIAlertView(title: "Error", message: "An error occured saving the data", delegate: nil, cancelButtonTitle: "OK")
                    saveError.show()
                    errors = true
                }
            })
            
            // add to their can remind list
            let canRemindRef = ref.childByAppendingPath("friends/\(sender.actionData)/can-remind")
            canRemindRef.updateChildValues([ref.authData.uid: "true"] as [NSObject : AnyObject], withCompletionBlock: { (error:NSError?, ref:Firebase!) in
                if error != nil {
                    let saveError = UIAlertView(title: "Error", message: "An error occured saving the data", delegate: nil, cancelButtonTitle: "OK")
                    saveError.show()
                    errors = true
                }
            })
            
            if !errors {
                self.dismissViewControllerAnimated(true, completion: nil)
            }
        }
        
    }
    
    // searchbar requirements
    func searchBarTextDidBeginEditing(searchBar: UISearchBar) {
        searchActive = true;
    }
    
    func searchBarTextDidEndEditing(searchBar: UISearchBar) {
        searchActive = false;
    }
    
    func searchBarCancelButtonClicked(searchBar: UISearchBar) {
        searchActive = false;
    }
    
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        searchActive = false;
    }
    
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        
        if searchText != "" && searchText.characters.count >= 2 && searchText.containsString("@") {
            
            // user authenticated with Firebase
            let usersRef = ref.childByAppendingPath("users")
            
            // listen for add of new minders
            usersRef.queryOrderedByChild("email_address").queryStartingAtValue("\(searchText)").queryEndingAtValue("\(searchText)~").observeEventType(.Value, withBlock: { snapshot in
                
                if snapshot.value.count != nil {

                    // remove data from array and reset count
                    self.friendData.removeAll(keepCapacity: false)
                    self.searchDataCount = 0
                    
                    // iterate the results and add to array
                    let enumerator = snapshot.children
                    while let data = enumerator.nextObject() as? FDataSnapshot {
                        if data.key != self.ref.authData.uid && !self.currentFriends.contains(data.key) {
                            self.friendData.append(data)
                        }
                        //println(data);
                    }
                    
                    // update table
                    if self.friendData.count > 0 {
                        // set row count and reload
                        self.searchDataCount = self.friendData.count
                        self.tableView.reloadData()
                    }
                }
                
            })
            
        }
        
    }

    
    // tableView requirements
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchDataCount
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
        
        // cell button setup
        cell.allowBtn.actionData = friendData[indexPath.row].key
        cell.allowBtn.addTarget(self, action: "allowBtnAction:", forControlEvents: .TouchUpInside)
        
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
