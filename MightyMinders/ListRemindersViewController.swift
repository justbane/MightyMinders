//
//  ListRemindersViewController.swift
//  MightyMinders
//
//  Created by Justin Bane on 11/10/15.
//  Copyright © 2015 Justin Bane. All rights reserved.
//

import UIKit

class ListRemindersViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    let ref = Firebase(url: "https://mightyminders.firebaseio.com/")
    let userDefaults = NSUserDefaults.standardUserDefaults()
    var reminderData: [FDataSnapshot!] = []
    var theirReminderData: [FDataSnapshot!] = []
    var reminderKeys = Set<String>()
    var selectedReminder: [String: Double]!
    let sectionsInTable = ["Set For You", "Set for Friends"]
    
    @IBOutlet weak var tableView: UITableView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        
        // table view setup
        tableView.delegate = self
        tableView.dataSource = self
        //tableView.separatorInset = UIEdgeInsetsZero
        
        self.getReminders()
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func getReminders() {
        
        // private minders
        let userMindersRef = ref.childByAppendingPath("minders/\(ref.authData.uid)/private")
        
        // listen for add of new minders
        userMindersRef.observeEventType(.Value, withBlock: { (snapshot) -> Void in
            let enumerator = snapshot.children
            while let data = enumerator.nextObject() as? FDataSnapshot {
                //print(data.key)
                if !self.reminderKeys.contains(data.key) {
                    self.reminderKeys.insert(data.key)
                    self.reminderData.append(data)
                }
                
            }
            self.tableView.reloadData()
        })
        
        // shared minders
        let sharedMindersRef = ref.childByAppendingPath("shared-minders")
        
        // listen for add of new minders
        // set for you
        sharedMindersRef.queryOrderedByChild("set-for").queryEqualToValue(ref.authData.uid).observeEventType(.Value, withBlock: { (snapshot) -> Void in
            let enumerator = snapshot.children
            while let data = enumerator.nextObject() as? FDataSnapshot {
                //print(data.key)
                if !self.reminderKeys.contains(data.key) {
                    self.reminderKeys.insert(data.key)
                    self.reminderData.append(data)
                }
            }
            self.tableView.reloadData()
            
        })
        
        // set by you
        sharedMindersRef.queryOrderedByChild("set-by").queryEqualToValue(ref.authData.uid).observeEventType(.Value, withBlock: { (snapshot) -> Void in
            // set reminders object
            let enumerator = snapshot.children
            while let data = enumerator.nextObject() as? FDataSnapshot {
                //print(data.key)
                if !self.reminderKeys.contains(data.key) {
                    self.reminderKeys.insert(data.key)
                    self.theirReminderData.append(data)
                }
            }
            self.tableView.reloadData()
        })
        
    }
    
    override func shouldPerformSegueWithIdentifier(identifier: String, sender: AnyObject?) -> Bool {
        
        // check to see if segue should happen (have they selected a reminder?
        if identifier == "ListViewUnwindSegue" {
            if let sendingBtn = sender as? CustomButton {
                selectedReminder = sendingBtn.locationData
            }
        }
        
        return true
    }
    
    @IBAction func selectReminderAction(sender: AddRemoveButtonView) {
        
        self.dismissViewControllerAnimated(true, completion: nil)
        
    }
    
    @IBAction func closeBtnAction(sender: AnyObject) {
        
        self.dismissViewControllerAnimated(true, completion: nil)
        
    }
    
    func getSectionItems(section: Int) -> Int {
        
        var count = 0
        
        if section == 0 {
            count = reminderData.count
        }
        
        if section == 1 {
            count = theirReminderData.count
        }
        
        return count
        
    }
    
    // tableView requirements
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return sectionsInTable.count
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return getSectionItems(section)
    }
    
    func tableView(tableView: UITableView, estimatedHeightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sectionsInTable[section]
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier("remindersTableCell") as! ListViewTableViewCell
        cell.separatorInset = UIEdgeInsetsZero
        cell.layoutMargins = UIEdgeInsetsZero
        cell.preservesSuperviewLayoutMargins = false
        cell.selectionStyle = UITableViewCellSelectionStyle.None
        
        if reminderData.count > 0 && indexPath.section == 0 {
            let reminders = reminderData[indexPath.row].value.valueForKey("location")
            if let location = reminders {
                cell.viewBtn.locationData = [
                    "latitude": (location.valueForKey("latitude") as? Double)!,
                    "longitude": (location.valueForKey("longitude") as? Double)!
                ]
                
                if let name = location.valueForKey("name") as? NSString {
                    (cell.contentView.viewWithTag(101) as! UILabel).text = name as String
                }
                
                if let address = location.valueForKey("address") as? NSString {
                    (cell.contentView.viewWithTag(102) as! UILabel).text = address as String
                }
            }
        }
        
        if theirReminderData.count > 0 && indexPath.section == 1 {
            let reminders = theirReminderData[indexPath.row].value.valueForKey("location")
            if let location = reminders {
                cell.viewBtn.locationData = [
                    "latitude": (location.valueForKey("latitude") as? Double)!,
                    "longitude": (location.valueForKey("longitude") as? Double)!
                ]
                
                if let name = location.valueForKey("name") as? NSString {
                    (cell.contentView.viewWithTag(101) as! UILabel).text = name as String
                }
                
                if let address = location.valueForKey("address") as? NSString {
                    (cell.contentView.viewWithTag(102) as! UILabel).text = address as String
                }
            }
        }
        
        // cell button setup
        cell.viewBtn.addTarget(self, action: "selectReminderAction:", forControlEvents: .TouchUpInside)
        
        // return the cell with data
        return cell
    }

}
