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

    
    let ref = Firebase(url: "https://mightyminders.firebaseio.com/")
    let locationManager: CLLocationManager = CLLocationManager()
    
    var privateData: FDataSnapshot!
    var sharedData: FDataSnapshot!
    var sharedByData: FDataSnapshot!
    var reminderKeys = Set<String>()
    var currentLocation: CLLocation!
    
    @IBOutlet weak var addReminderBtn: AddRemoveButtonView!
    @IBOutlet weak var totalMindersLbl: UILabel!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var locationMarkBtn: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // do any additional setup after loading the view, typically from a nib.
        // ref.unauth()
        
        // setup location manager
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestAlwaysAuthorization()
        
        // delegate map view
        mapView.delegate = self
    }
    
    override func viewDidAppear(animated: Bool) {
        // view is shown again
        // println("Updates viewDidAppear fired")
        
        // check for valid user
        if ref.authData == nil {
            super.showLogin()
        } else {
            //get the reminders
            getReminders()
        }
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // dispose of any resources that can be recreated.
    }
    
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
        
        // only edit if not the add button
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
    
    @IBAction func unwindFromViewReminder(segue: UIStoryboardSegue) {
        if segue.identifier == "CompleteBtnUnwindSegue" {
            if let reminderViewController = segue.sourceViewController as? ViewReminderViewController {
                // remove reminder if complete selected
                if reminderViewController.completeReminder  {
                    removeMinder(reminderViewController.reminderIdentifier)
                }
                
            }
        }
    }
    
    @IBAction func unwindFromProfileView(segue: UIStoryboardSegue) {
        if segue.identifier == "LogoutUnwindSegue" {
            // check for valid user
            if ref.authData == nil {
                showLogin()
                reminderKeys.removeAll(keepCapacity: false)
                totalMindersLbl.text = "0"
                // cancel the notifications
                UIApplication.sharedApplication().cancelAllLocalNotifications()
                
            }
        }
    }
    
    @IBAction func locateMe(sender: UIButton) {
        if mapView.userTrackingMode.rawValue == 0 {
            mapView.setUserTrackingMode(.Follow, animated: true)
        } else {
            mapView.setUserTrackingMode(.None, animated: false)
        }
        
    }
    
    
    
    // App functions
    
    func getReminders() {
        // reset the map
        if let annotations = self.mapView?.annotations {
            self.mapView.removeAnnotations(annotations)
            if let overlays = self.mapView?.overlays {
                self.mapView?.removeOverlays(overlays)
            }
        }
        
        if ref.authData != nil {

            // private minders
            let userMindersRef = ref.childByAppendingPath("minders/\(ref.authData.uid)/private")
            
            // listen for add of new minders
            userMindersRef.observeEventType(.Value, withBlock: { (snapshot) -> Void in
                // set reminders object
                self.privateData = snapshot
                if self.privateData!.value.count != nil {
                    self.updateReminders("private")
                }
            })
            
            // shared minders
            let sharedMindersRef = ref.childByAppendingPath("shared-minders")
            
            // listen for add of new minders
            // set for you
            sharedMindersRef.queryOrderedByChild("set-for").queryEqualToValue(ref.authData.uid).observeEventType(.Value, withBlock: { (snapshot) -> Void in
                // set reminders object
                self.sharedData = snapshot
                if self.sharedData!.value.count != nil {
                    self.updateReminders("shared")
                }
            })
            // set for you (removal)
            sharedMindersRef.queryOrderedByChild("set-for").queryEqualToValue(ref.authData.uid).observeEventType(.ChildRemoved, withBlock: { (snapshot) -> Void in
                // remove the offending minder
                if snapshot.value.count != nil {
                    self.removeMinder(snapshot.key)
                }
            })
            
            
            // listen for add of new minders
            // set by you
            sharedMindersRef.queryOrderedByChild("set-by").queryEqualToValue(ref.authData.uid).observeEventType(.Value, withBlock: { (snapshot) -> Void in
                // set reminders object
                self.sharedByData = snapshot
                if self.sharedByData!.value.count != nil {
                    self.updateReminders("shared-set-by")
                }
            })
            
            // set by you (removal)
            sharedMindersRef.queryOrderedByChild("set-by").queryEqualToValue(ref.authData.uid).observeEventType(.ChildRemoved, withBlock: { (snapshot) -> Void in
                // remove the offending minder
                if snapshot.value.count != nil {
                    self.removeMinder(snapshot.key)
                }
            })
            
            
        }
        
    }
    
    func updateReminders(type: String) {
        if type == "private" {
            
            // cancel the notifications
            UIApplication.sharedApplication().cancelAllLocalNotifications()
            
            // process private minders
            let privateAnnotations = Minders(reminderSubData: privateData!, type: "private").processMinders()
            for annotation in privateAnnotations {
                
                // remove then add annotation to map
                if let annotations = self.mapView?.annotations as? [Annotation] {
                    if annotations.count > 0 {
                        for item in annotations {
                            if !(item.key.isEmpty) && item.key == annotation.key {
                                self.removePinAndOverlay(annotation)
                            }
                        }
                    }
                }
                // add to map
                mapView.addAnnotation(annotation)
                addRadiusOverlayForMinder(annotation)
                // add to keys
                reminderKeys.insert(annotation.key)
                
                let region = self.regionWithMinder(annotation)
                
                // set localNotification
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
            
            // process shared minders
            var sharedAnnotations = Minders(reminderSubData: sharedData!, type: "shared").processMinders()
            
            if type == "shared-set-by" {
                sharedAnnotations = Minders(reminderSubData: sharedByData!, type: "shared").processMinders()
            }
            
            for annotation in sharedAnnotations {
                
                // fire notification if new reminder
                if UIApplication.sharedApplication().applicationState != UIApplicationState.Active {
                    if !(reminderKeys.contains(annotation.key)) {
                        let ln:UILocalNotification = UILocalNotification()
                        ln.alertAction = annotation.title
                        ln.alertBody = annotation.content
                        ln.fireDate = NSDate(timeIntervalSinceNow: 2)
                        ln.soundName = UILocalNotificationDefaultSoundName
                        UIApplication.sharedApplication().scheduleLocalNotification(ln)
                    }
                }
                
                // remove annotation from map
                if let annotations = self.mapView?.annotations as? [Annotation] {
                    if annotations.count > 0 {
                        for item in annotations {
                            if !(item.key.isEmpty) && item.key == annotation.key {
                                self.removePinAndOverlay(annotation)
                            }
                        }
                    }
                }
                
                // add to map
                mapView.addAnnotation(annotation)
                addRadiusOverlayForMinder(annotation)
                // add to keys
                reminderKeys.insert(annotation.key)
                
                let region = self.regionWithMinder(annotation)
                
                // set localNotification
                if annotation.setFor == ref.authData.uid {
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
        
        // update total
        totalMindersLbl.text = String(reminderKeys.count)
        
    }
    
    func removeMinder(key: String) {
        for annotation in self.mapView.annotations {
            if let minderAnnotation = annotation as? Annotation {
                if minderAnnotation.key == key {
                    
                    var removeRef = ref.childByAppendingPath("minders/\(ref.authData.uid)/private/\(key)")
                    // if shared minder
                    
                    if minderAnnotation.type == "shared" {
                        removeRef = ref.childByAppendingPath("shared-minders/\(key)")
                    }
                    
                    removeRef.removeValueWithCompletionBlock({ (error, Firebase) -> Void in
                        if error == nil {
                            self.removePinAndOverlay(minderAnnotation)
                            // remove the key
                            self.reminderKeys.remove(key)
                            // update total
                            self.totalMindersLbl.text = String(self.reminderKeys.count)
                        }
                    })
                    
                }
            }
        }
    }
    
    func removePinAndOverlay(minderAnnotation: Annotation) {
        // remove the pin
        self.mapView.removeAnnotation(minderAnnotation)
        
        // remove the region
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
    
    
    
    // Regions & Overlays
    
    func regionWithMinder(annotation: Annotation) -> CLCircularRegion {
        let region = CLCircularRegion(center: annotation.coordinate, radius: 100, identifier: annotation.key)
        region.notifyOnEntry = (annotation.event == 0)
        region.notifyOnExit = (annotation.event == 1)
        return region
    }
    
    func addRadiusOverlayForMinder(annotation: Annotation) {
        mapView?.addOverlay(MKCircle(centerCoordinate: annotation.coordinate, radius: 100))
    }
    
    
    
    // Location manager fence events
    
    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        if status == .AuthorizedAlways || status == .AuthorizedWhenInUse {
            locationManager.startUpdatingLocation()
            mapView.setUserTrackingMode(.Follow, animated: true)
        }
    }
    
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        let alert = UIAlertController(title: "Location Error", message: "There was an error geting your location: \(error.localizedDescription)", preferredStyle: UIAlertControllerStyle.Alert)
        let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil)
        
        // Add the actions
        alert.addAction(okAction)
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        currentLocation = locationManager.location
        // update the button if still tracking user
        if mapView.userTrackingMode.rawValue == 1 {
            let markImage = UIImage(named: "compass-on") as UIImage!
            locationMarkBtn.setImage(markImage, forState: .Normal)
        } else {
            let markImage = UIImage(named: "compass") as UIImage!
            locationMarkBtn.setImage(markImage, forState: .Normal)
        }
        // set map region and add current location annotation
        mapView.showsUserLocation = true
    }
    
    
    
    // Button Actions
    
    func editButtonAction(sender: AnyObject) {
        performSegueWithIdentifier("AddReminderSegue", sender: sender)
    }
    
    func viewButtonAction(sender: AnyObject) {
        performSegueWithIdentifier("ViewReminderSegue", sender: sender)
        
    }
    
    
    
    // MARK - required methods
    
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        if let annotation = annotation as? Annotation {
            // draw map view and setup the annotation buttons and handler
            let reuseId = "pin"
        
            var pinView = mapView.dequeueReusableAnnotationViewWithIdentifier(reuseId)
            
            pinView = MKAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.canShowCallout = true
            
            pinView!.image = annotation.pinImage()
            pinView!.centerOffset = CGPointMake(0, -8)
            
            // this is for pin view - requires different object type
            //pinView!.pinColor = annotation.pinColor()
            
            if annotation.setFor != ref.authData.uid || annotation.type == "private" {
                let completeIcon = UIImage(named: "edit-notepad.png")
                let completeButton: UIButton = UIButton(type: UIButtonType.Custom)
                completeButton.frame = CGRectMake(32, 32, 32, 32)
                completeButton.setImage(completeIcon, forState: .Normal)
                completeButton.addTarget(self, action: "editButtonAction:", forControlEvents: UIControlEvents.TouchUpInside)
                pinView!.leftCalloutAccessoryView = completeButton as UIView
            }
            
            let viewIcon = UIImage(named: "info.png")
            let viewButton: UIButton = UIButton(type: UIButtonType.Custom)
            viewButton.frame = CGRectMake(32, 32, 32, 32)
            viewButton.setImage(viewIcon, forState: .Normal)
            viewButton.addTarget(self, action: "viewButtonAction:", forControlEvents: UIControlEvents.TouchUpInside)
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
}
