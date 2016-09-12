//
//  ViewController.swift
//  MightyMinders
//
//  Created by Justin Bane on 4/23/15.
//  Copyright (c) 2015 Justin Bane. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

class ViewController: MMCustomViewController, MKMapViewDelegate, CLLocationManagerDelegate {

    let ref = FIRDatabase.database().reference()
    let locationManager: CLLocationManager = CLLocationManager()
    let userDefaults = NSUserDefaults.standardUserDefaults()
    
    var privateData: FIRDataSnapshot!
    var sharedData: FIRDataSnapshot!
    var sharedByData: FIRDataSnapshot!
    var reminderKeys = Set<String>()
    var currentLocation: CLLocation!
    
    @IBOutlet weak var addReminderBtn: AddRemoveButtonView!
    @IBOutlet weak var totalMindersLbl: UILabel!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var locationMarkBtn: UIButton!
    @IBOutlet weak var listViewBtn: CustomButton!
    @IBOutlet weak var minderActivity: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Listen for notification actions
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(addMinderFromNotification), name: "addMinderPressed", object: nil)
        
        // Do any additional setup after loading the view, typically from a nib.
        // ref.unauth()
        
        // Setup location manager
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestAlwaysAuthorization()
        
        // Delegate map view
        mapView.delegate = self
    }
    
    override func viewDidAppear(animated: Bool) {
        // View is shown again
        // print("Updates viewDidAppear fired")
        
        // Check for valid user
        if FIRAuth.auth()?.currentUser == nil {
            super.showLogin()
        } else {
            // Get the reminders
            getReminders()
        }
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: Activity
    func startActivity() {
        // Show the activity
        minderActivity.startAnimating()
        minderActivity.hidden = false;
    }
    
    func stopActivity() {
        minderActivity.stopAnimating()
        minderActivity.hidden = true;
    }
    
    
    // MARK: Segues
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "ViewReminderSegue" {
            let reminderViewController = segue.destinationViewController as! ViewReminderViewController
            
            if let annotation = self.mapView.selectedAnnotations[0] as? Annotation {
                reminderViewController.reminderText = annotation.content
                reminderViewController.reminderIdentifier = annotation.key
                reminderViewController.timingText = annotation.event == 0 ? "Arriving" : "Leaving"
                reminderViewController.selectedFriendFromView = annotation.setFor
                reminderViewController.setByFromView = annotation.setBy
            }
        }
        
        // Only edit if not the add button
        if sender!.tag! != 101 {
            if segue.identifier == "AddReminderSegue" && self.mapView.selectedAnnotations.count != 0 {
                let addReminderViewController = segue.destinationViewController as! AddReminderViewController
                
                if let annotation = self.mapView.selectedAnnotations[0] as? Annotation {
                    addReminderViewController.reminderTextFromView = annotation.content
                    addReminderViewController.reminderIdentifier = annotation.key
                    addReminderViewController.reminderTimingFromView = annotation.event == 0 ? 0 : 1
                    addReminderViewController.selectedLocationFromView["name"] = annotation.title
                    addReminderViewController.selectedLocationFromView["address"] = annotation.subtitle
                    addReminderViewController.selectedLocationFromView["latitude"] = annotation.coordinate.latitude
                    addReminderViewController.selectedLocationFromView["longitude"] = annotation.coordinate.longitude
                    addReminderViewController.selectedFriendFromView = annotation.setFor
                }
            }
        }
    }
    
    
    // MARK: Notification actions
    func addMinderFromNotification(notification: NSNotification) {
        
        let data = notification.userInfo! as! [String: AnyObject]
        var latitude = 0.0
        var longitude = 0.0
        var centerMap = false
        
        
        if let lat = data["latitude"] as? String {
            latitude = Double(lat)!
            centerMap = true
        }
        if let long = data["longitude"] as? String {
            longitude = Double(long)!
            centerMap = true
        }
        
        let coordinates = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        
        // Center map on new minder
        if centerMap {
            mapView.setCenterCoordinate(coordinates, animated: true)
        }
        
    }
    
    // MARK: Segue unwinds
    @IBAction func unwindFromViewReminder(segue: UIStoryboardSegue) {
        if segue.identifier == "CompleteBtnUnwindSegue" {
            if let reminderViewController = segue.sourceViewController as? ViewReminderViewController {
                // Remove reminder if complete selected
                if reminderViewController.completeReminder  {
                    removeMinder(reminderViewController.reminderIdentifier)
                }
                
            }
        }
    }
    
    @IBAction func unwindFromProfileView(segue: UIStoryboardSegue) {
        if segue.identifier == "LogoutUnwindSegue" {
            // Check for valid user
            if FIRAuth.auth()?.currentUser == nil {
                showLogin()
                reminderKeys.removeAll(keepCapacity: false)
                totalMindersLbl.text = "0"
                
                // Cancel the notifications
                UIApplication.sharedApplication().cancelAllLocalNotifications()
            }
        }
    }
    
    @IBAction func unwindFromReminderListView(segue: UIStoryboardSegue) {
        
        let listController = segue.sourceViewController as! ListRemindersViewController
        
        if segue.identifier == "ListViewUnwindSegue" {
            
            let data = listController.selectedReminder
            var latitude = 0.0
            var longitude = 0.0
            
            if let lat = data["latitude"] {
                latitude = lat
            }
            if let long = data["longitude"] {
                longitude = long
            }
            
            let coordinates = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            
            // Center map on new minder
            mapView.setCenterCoordinate(coordinates, animated: true)
            
        }
        
    }
    
    // MARK: Get reminders
    func getReminders() {
        
        // Cancel the notifications then add from firebase
        UIApplication.sharedApplication().cancelAllLocalNotifications()
        
        // Reset the map
        removeAllAnnotationAndOverlays()
        
        self.startActivity()
        if FIRAuth.auth()?.currentUser != nil {

            // Private minders
            Minders().getPrivateMinders({ (privateReminders) in
                self.privateData = privateReminders
                if self.privateData!.value!.count != nil {
                    self.updateReminders("private")
                } else {
                    self.stopActivity()
                }
            })
            
            // Shared minders
            Minders().getSharedReminders({ (sharedReminders) in
                self.sharedData = sharedReminders
                if self.sharedData!.value!.count != nil {
                    self.updateReminders("shared")
                } else {
                    self.stopActivity()
                }
            })
            
            // Set for you (removal)
            Minders().listenForRemindersRemovedForMe({ (remindersRemovedForMe) in
                // Remove the offending minders
                if remindersRemovedForMe.value!.count != nil {
                    self.removeMinder(remindersRemovedForMe.key)
                } else {
                    self.stopActivity()
                }
            })
            
            // Listen for add of new minders
            // Set by you
            Minders().getRemindersSetByYou({ (remindersSetByYou) in
                self.sharedByData = remindersSetByYou
                if self.sharedByData!.value!.count != nil {
                    self.updateReminders("shared-set-by")
                } else {
                    self.stopActivity()
                }
            })
            
            // Set by you (removal)
            Minders().listenForRemindersRemovedByMe({ (remindersRemovedByMe) in
                if remindersRemovedByMe.value!.count != nil {
                    self.removeMinder(remindersRemovedByMe.key)
                } else {
                    self.stopActivity()
                }
            })
            
        }
        
    }
    
    // MARK: Update reminders
    func updateReminders(type: String) {
        
        if type == "private" {
            
            // Process private minders
            let privateAnnotations = Minders().processMinders(privateData!, type: "private")
            
            for annotation in privateAnnotations {
                
                // Add to map
                mapView.addAnnotation(annotation)
                addRadiusOverlayForMinder(annotation)
                
                // Add to keys
                reminderKeys.insert(annotation.key)
                
                let region = self.regionWithMinder(annotation)
                
                // Set localNotification
                let ln:UILocalNotification = UILocalNotification()
                ln.alertAction = annotation.title
                ln.alertBody = annotation.content
                ln.region = region
                ln.regionTriggersOnce = false
                ln.soundName = UILocalNotificationDefaultSoundName
                UIApplication.sharedApplication().scheduleLocalNotification(ln)
            }
        
        }
        
        if type == "shared" || type == "shared-set-by" {
            
            // Process shared minders
            let sharedAnnotations: Set<Annotation>
            
            if type == "shared-set-by" {
                sharedAnnotations = Minders().processMinders(sharedByData!, type: "shared")
            } else {
                sharedAnnotations = Minders().processMinders(sharedData!, type: "shared")
            }

            for annotation in sharedAnnotations {
                
                // Add to map
                mapView.addAnnotation(annotation)
                addRadiusOverlayForMinder(annotation)
            
                // Add to keys
                reminderKeys.insert(annotation.key)
            
                let region = self.regionWithMinder(annotation)
            
                // Set localNotification
                if annotation.setFor == FIRAuth.auth()?.currentUser?.uid {
                    let ln:UILocalNotification = UILocalNotification()
                    ln.alertAction = annotation.title
                    ln.alertBody = annotation.content
                    ln.region = region
                    ln.regionTriggersOnce = false
                    ln.soundName = UILocalNotificationDefaultSoundName
                    UIApplication.sharedApplication().scheduleLocalNotification(ln)
                }
            }
            
        }
        
        // Insert keys to defaults
        userDefaults.setObject(Array(reminderKeys), forKey: "reminderKeys")
        
        // Update total
        totalMindersLbl.text = String(reminderKeys.count)
        
        // Hide activity
        stopActivity()
    }
    
    // MARK: Remove reminders
    func removeMinder(key: String) {
        for annotation in self.mapView.annotations {
            if let minderAnnotation = annotation as? Annotation {
                if minderAnnotation.key == key {
                    
                    var removeRef = ref.child("minders").child((FIRAuth.auth()?.currentUser?.uid)!).child("private").child(key)
                    
                    // If shared minder
                    if minderAnnotation.type == "shared" {
                        removeRef = ref.child("shared-minders").child(key)
                    }
                    
                    removeRef.removeValueWithCompletionBlock({ (error, Firebase) -> Void in
                        if error == nil {
                            self.removePinAndOverlay(minderAnnotation)
                            
                            // Remove the key
                            self.reminderKeys.remove(key)
                            
                            // Update total
                            self.totalMindersLbl.text = String(self.reminderKeys.count)
                            
                        }
                    })
                    
                    // Send the notification if shared
                    if minderAnnotation.type == "shared" {
                        self.sendCompleteNotification(minderAnnotation)
                    }
                    
                    // Insert keys to defaults
                    userDefaults.setObject(Array(reminderKeys), forKey: "reminderKeys")
                    
                    // Get/update the reminders
                    self.getReminders()
                    
                }
            }
        }
    }
    
    // MARK: Remove pin and overlay
    func removePinAndOverlay(minderAnnotation: Annotation) {
        // Remove the pin
        self.mapView.removeAnnotation(minderAnnotation)
        
        // Remove the region
        if let overlays = self.mapView?.overlays {
            for overlay in overlays {
                if let circleOverlay = overlay as? MKCircle {
                    let coord = circleOverlay.coordinate
                    if coord.latitude == minderAnnotation.coordinate.latitude && coord.longitude == minderAnnotation.coordinate.longitude {
                        self.mapView?.removeOverlay(circleOverlay)
                        break
                    }
                }
            }
        }
    }
    
    // MARK: Send complete notification
    func sendCompleteNotification(userMinder: Annotation) {
        
        if (FIRAuth.auth()?.currentUser?.uid)! as String != userMinder.setBy {
            
            let restReq = HTTPRequests()
            let setBy = userMinder.setBy
            let setFor = userMinder.setFor
            let content = userMinder.content
            var token: String = ""
            var senderName: String = "Someone"
            
            // Get sender profile data
            let setByRef = self.ref.child("users").child(setFor)
            setByRef.observeSingleEventOfType(.Value, withBlock: { (snapshot) -> Void in
                let first_name: String = snapshot.value!.objectForKey("first_name") as! String
                let last_name: String = snapshot.value!.objectForKey("last_name") as! String
                senderName = "\(first_name) \(last_name)"
                
                // Get reciever device token
                self.ref.child("devices").child(setBy).observeEventType(.Value, withBlock: { (snapshot) in
                    if snapshot.value != nil {
                        token = snapshot.value!.objectForKey("token") as! String
                    }
                    
                    if token != "" {
                        let data: [String: AnyObject] = [
                            "to": token,
                            "notification": [
                                "title": "MightyMinder Completed",
                                "body": "\(senderName) completed a reminder!: \(content) - Swipe to update your reminders",
                            ]
                        ]
                        
                        // Send to push server
                        restReq.sendPostRequest(data) { (success, msg) -> () in
                            // Completion code here
                            // print(success)
                            
                            let status = msg["status"] as! String
                            if status.containsString("FAILURE") {
                                print(status)
                            }
                        }
                    }
                    
                })
                
            })
            
        }
    }
    
    // MARK: Regions & Overlays
    func regionWithMinder(annotation: Annotation) -> CLCircularRegion {
        
        var radius = 200.00
        if annotation.event == 1 {
            radius = 100.00
        }
        
        let region = CLCircularRegion(center: annotation.coordinate, radius: radius, identifier: annotation.key)
        region.notifyOnEntry = (annotation.event == 0)
        region.notifyOnExit = (annotation.event == 1)
        return region
    }
    
    func addRadiusOverlayForMinder(annotation: Annotation) {
        
        var radius = 200.00
        if annotation.event == 1 {
            radius = 100.00
        }
        
        var hasOverlay = false
        for overlay in mapView.overlays {
            if overlay.coordinate.latitude == annotation.coordinate.latitude && overlay.coordinate.longitude == annotation.coordinate.longitude {
                hasOverlay = true
                break
            }
        }
        
        if !hasOverlay {
            let circle = MKCircle(centerCoordinate: annotation.coordinate, radius: radius)
            mapView?.addOverlay(circle)
        }
        
    }
    
    func removeAllAnnotationAndOverlays() {
        // Reset the map annotations and overlays
        if let annotations = self.mapView?.annotations {
            self.mapView.removeAnnotations(annotations)
            if let overlays = self.mapView?.overlays {
                self.mapView?.removeOverlays(overlays)
            }
        }
    }
    
    // MARK: Location manager fence events
    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        if status == .AuthorizedAlways || status == .AuthorizedWhenInUse {
            locationManager.startUpdatingLocation()
            mapView.setUserTrackingMode(.Follow, animated: true)
        }
    }
    
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        let alert = UIAlertController(title: "Location Error", message: "There was an error getting your location. MightyMinders needs your location to work correctly. Please adjust your location settings in the Settings app.", preferredStyle: UIAlertControllerStyle.Alert)
        let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil)
        
        // Add the actions
        alert.addAction(okAction)
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        currentLocation = locationManager.location
        // Update the button if still tracking user
        if mapView.userTrackingMode.rawValue == 1 {
            let markImage = UIImage(named: "compass-on") as UIImage!
            locationMarkBtn.setImage(markImage, forState: .Normal)
        } else {
            let markImage = UIImage(named: "compass") as UIImage!
            locationMarkBtn.setImage(markImage, forState: .Normal)
        }
        // Set map region and add current location annotation
        mapView.showsUserLocation = true
    }
    
    // MARK: Button Actions
    func editButtonAction(sender: AnyObject) {
        performSegueWithIdentifier("AddReminderSegue", sender: sender)
    }
    
    func viewButtonAction(sender: AnyObject) {
        performSegueWithIdentifier("ViewReminderSegue", sender: sender)
        
    }
    
    @IBAction func locateMe(sender: UIButton) {
        if mapView.userTrackingMode.rawValue == 0 {
            mapView.setUserTrackingMode(.Follow, animated: true)
        } else {
            mapView.setUserTrackingMode(.None, animated: false)
        }
        
    }
    
    // MARK: Required methods for mapview
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        if let annotation = annotation as? Annotation {
            // Draw map view and setup the annotation buttons and handler
            let reuseId = "pin"
        
            var pinView = mapView.dequeueReusableAnnotationViewWithIdentifier(reuseId)
            
            pinView = MKAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.canShowCallout = true
            
            pinView!.image = annotation.pinImage()
            pinView!.centerOffset = CGPointMake(0, -8)
            
            // This is for pin view - requires different object type
            // pinView!.pinColor = annotation.pinColor()
            
            if annotation.setFor != (FIRAuth.auth()?.currentUser?.uid)! || annotation.type == "private" {
                let completeIcon = UIImage(named: "edit-notepad.png")
                let completeButton: UIButton = UIButton(type: UIButtonType.Custom)
                completeButton.frame = CGRectMake(32, 32, 32, 32)
                completeButton.setImage(completeIcon, forState: .Normal)
                completeButton.addTarget(self, action: #selector(editButtonAction), forControlEvents: UIControlEvents.TouchUpInside)
                pinView!.leftCalloutAccessoryView = completeButton as UIView
            }
            
            let viewIcon = UIImage(named: "info.png")
            let viewButton: UIButton = UIButton(type: UIButtonType.Custom)
            viewButton.frame = CGRectMake(32, 32, 32, 32)
            viewButton.setImage(viewIcon, forState: .Normal)
            viewButton.addTarget(self, action: #selector(viewButtonAction), forControlEvents: UIControlEvents.TouchUpInside)
            pinView!.rightCalloutAccessoryView = viewButton as UIView
            
            return pinView
        }
        return nil
    }
    
    func mapView(mapView: MKMapView, rendererForOverlay overlay: MKOverlay) -> MKOverlayRenderer {
        
        let circleRenderer = MKCircleRenderer(overlay: overlay)
        circleRenderer.lineWidth = 1.0
        circleRenderer.strokeColor = UIColor.grayColor()
        circleRenderer.fillColor = UIColor.grayColor().colorWithAlphaComponent(0.25)
        return circleRenderer
        
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
}

