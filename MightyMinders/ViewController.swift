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
    let userDefaults = UserDefaults.standard
    
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
        NotificationCenter.default.addObserver(self, selector: #selector(addMinderFromNotification), name: NSNotification.Name(rawValue: "addMinderPressed"), object: nil)
        
        // Do any additional setup after loading the view, typically from a nib.
        // ref.unauth()
        
        // Setup location manager
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestAlwaysAuthorization()
        
        // Delegate map view
        mapView.delegate = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
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
        minderActivity.isHidden = false;
    }
    
    func stopActivity() {
        minderActivity.stopAnimating()
        minderActivity.isHidden = true;
    }
    
    
    // MARK: Segues
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ViewReminderSegue" {
            let reminderViewController = segue.destination as! ViewReminderViewController
            
            if let annotation = self.mapView.selectedAnnotations[0] as? Annotation {
                reminderViewController.reminderText = annotation.content
                reminderViewController.reminderIdentifier = annotation.key
                reminderViewController.timingText = annotation.event == 0 ? "Arriving" : "Leaving"
                reminderViewController.selectedFriendFromView = annotation.setFor
                reminderViewController.setByFromView = annotation.setBy
            }
        }
        
        // Only edit if not the add button
        if (sender! as AnyObject).tag! != 101 {
            if segue.identifier == "AddReminderSegue" && self.mapView.selectedAnnotations.count != 0 {
                let addReminderViewController = segue.destination as! AddReminderViewController
                
                if let annotation = self.mapView.selectedAnnotations[0] as? Annotation {
                    addReminderViewController.reminderTextFromView = annotation.content
                    addReminderViewController.reminderIdentifier = annotation.key
                    addReminderViewController.reminderTimingFromView = annotation.event == 0 ? 0 : 1
                    addReminderViewController.selectedLocationFromView["name"] = annotation.title as AnyObject?
                    addReminderViewController.selectedLocationFromView["address"] = annotation.subtitle as AnyObject?
                    addReminderViewController.selectedLocationFromView["latitude"] = annotation.coordinate.latitude as AnyObject?
                    addReminderViewController.selectedLocationFromView["longitude"] = annotation.coordinate.longitude as AnyObject?
                    addReminderViewController.selectedFriendFromView = annotation.setFor
                }
            }
        }
    }
    
    
    // MARK: Notification actions
    func addMinderFromNotification(_ notification: Notification) {
        
        let data = (notification as NSNotification).userInfo! as! [String: AnyObject]
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
            mapView.setCenter(coordinates, animated: true)
        }
        
    }
    
    // MARK: Segue unwinds
    @IBAction func unwindFromViewReminder(_ segue: UIStoryboardSegue) {
        if segue.identifier == "CompleteBtnUnwindSegue" {
            if let reminderViewController = segue.source as? ViewReminderViewController {
                // Remove reminder if complete selected
                if reminderViewController.completeReminder  {
                    removeMinder(reminderViewController.reminderIdentifier)
                }
                
            }
        }
    }
    
    @IBAction func unwindFromProfileView(_ segue: UIStoryboardSegue) {
        if segue.identifier == "LogoutUnwindSegue" {
            // Check for valid user
            if FIRAuth.auth()?.currentUser == nil {
                showLogin()
                reminderKeys.removeAll(keepingCapacity: false)
                totalMindersLbl.text = "0"
                
                // Cancel the notifications
                UIApplication.shared.cancelAllLocalNotifications()
            }
        }
    }
    
    @IBAction func unwindFromReminderListView(_ segue: UIStoryboardSegue) {
        
        let listController = segue.source as! ListRemindersViewController
        
        if segue.identifier == "ListViewUnwindSegue" {
            
            let data = listController.selectedReminder
            var latitude = 0.0
            var longitude = 0.0
            
            if let lat = data?["latitude"] {
                latitude = lat
            }
            if let long = data?["longitude"] {
                longitude = long
            }
            
            let coordinates = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            
            // Center map on new minder
            mapView.setCenter(coordinates, animated: true)
            
        }
        
    }
    
    // MARK: Get reminders
    func getReminders() {
        
        // Cancel the notifications then add from firebase
        UIApplication.shared.cancelAllLocalNotifications()
        
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
    func updateReminders(_ type: String) {
        
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
                UIApplication.shared.scheduleLocalNotification(ln)
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
                    UIApplication.shared.scheduleLocalNotification(ln)
                }
            }
            
        }
        
        // Insert keys to defaults
        userDefaults.set(Array(reminderKeys), forKey: "reminderKeys")
        
        // Update total
        totalMindersLbl.text = String(reminderKeys.count)
        
        // Hide activity
        stopActivity()
    }
    
    // MARK: Remove reminders
    func removeMinder(_ key: String) {
        for annotation in self.mapView.annotations {
            if let minderAnnotation = annotation as? Annotation {
                if minderAnnotation.key == key {
                    
                    var removeRef = ref.child("minders").child((FIRAuth.auth()?.currentUser?.uid)!).child("private").child(key)
                    
                    // If shared minder
                    if minderAnnotation.type == "shared" {
                        removeRef = ref.child("shared-minders").child(key)
                    }
                    
                    removeRef.removeValue(completionBlock: { (error, Firebase) -> Void in
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
                    userDefaults.set(Array(reminderKeys), forKey: "reminderKeys")
                    
                    // Get/update the reminders
                    self.getReminders()
                    
                }
            }
        }
    }
    
    // MARK: Remove pin and overlay
    func removePinAndOverlay(_ minderAnnotation: Annotation) {
        // Remove the pin
        self.mapView.removeAnnotation(minderAnnotation)
        
        // Remove the region
        if let overlays = self.mapView?.overlays {
            for overlay in overlays {
                if let circleOverlay = overlay as? MKCircle {
                    let coord = circleOverlay.coordinate
                    if coord.latitude == minderAnnotation.coordinate.latitude && coord.longitude == minderAnnotation.coordinate.longitude {
                        self.mapView?.remove(circleOverlay)
                        break
                    }
                }
            }
        }
    }
    
    // MARK: Send complete notification
    func sendCompleteNotification(_ userMinder: Annotation) {
        
        if (FIRAuth.auth()?.currentUser?.uid)! as String != userMinder.setBy {
            
            let restReq = HTTPRequests()
            let setBy = userMinder.setBy
            let setFor = userMinder.setFor
            let content = userMinder.content
            var token: String = ""
            var senderName: String = "Someone"
            
            // Get sender profile data
            let setByRef = self.ref.child("users").child(setFor)
            setByRef.observeSingleEvent(of: .value, with: { (snapshot) -> Void in
                let first_name: String = (snapshot.value! as AnyObject).object(forKey: "first_name") as! String
                let last_name: String = (snapshot.value! as AnyObject).object(forKey: "last_name") as! String
                senderName = "\(first_name) \(last_name)"
                
                // Get reciever device token
                self.ref.child("devices").child(setBy).observe(.value, with: { (snapshot) in
                    if snapshot.value != nil {
                        token = (snapshot.value! as AnyObject).object(forKey: "token") as! String
                    }
                    
                    if token != "" {
                        let data: [String: AnyObject] = [
                            "to": token as AnyObject,
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
                            if status.contains("FAILURE") {
                                print(status)
                            }
                        }
                    }
                    
                })
                
            })
            
        }
    }
    
    // MARK: Regions & Overlays
    func regionWithMinder(_ annotation: Annotation) -> CLCircularRegion {
        
        var radius = 200.00
        if annotation.event == 1 {
            radius = 100.00
        }
        
        let region = CLCircularRegion(center: annotation.coordinate, radius: radius, identifier: annotation.key)
        region.notifyOnEntry = (annotation.event == 0)
        region.notifyOnExit = (annotation.event == 1)
        return region
    }
    
    func addRadiusOverlayForMinder(_ annotation: Annotation) {
        
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
            let circle = MKCircle(center: annotation.coordinate, radius: radius)
            mapView?.add(circle)
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
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedAlways || status == .authorizedWhenInUse {
            locationManager.startUpdatingLocation()
            mapView.setUserTrackingMode(.follow, animated: true)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        let alert = UIAlertController(title: "Location Error", message: "There was an error getting your location. MightyMinders needs your location to work correctly. Please adjust your location settings in the Settings app.", preferredStyle: UIAlertControllerStyle.alert)
        let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil)
        
        // Add the actions
        alert.addAction(okAction)
        self.present(alert, animated: true, completion: nil)
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        currentLocation = locationManager.location
        // Update the button if still tracking user
        if mapView.userTrackingMode.rawValue == 1 {
            let markImage = UIImage(named: "compass-on") as UIImage!
            locationMarkBtn.setImage(markImage, for: UIControlState())
        } else {
            let markImage = UIImage(named: "compass") as UIImage!
            locationMarkBtn.setImage(markImage, for: UIControlState())
        }
        // Set map region and add current location annotation
        mapView.showsUserLocation = true
    }
    
    // MARK: Button Actions
    func editButtonAction(_ sender: AnyObject) {
        performSegue(withIdentifier: "AddReminderSegue", sender: sender)
    }
    
    func viewButtonAction(_ sender: AnyObject) {
        performSegue(withIdentifier: "ViewReminderSegue", sender: sender)
        
    }
    
    @IBAction func locateMe(_ sender: UIButton) {
        if mapView.userTrackingMode.rawValue == 0 {
            mapView.setUserTrackingMode(.follow, animated: true)
        } else {
            mapView.setUserTrackingMode(.none, animated: false)
        }
        
    }
    
    // MARK: Required methods for mapview
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if let annotation = annotation as? Annotation {
            // Draw map view and setup the annotation buttons and handler
            let reuseId = "pin"
        
            var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId)
            
            pinView = MKAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.canShowCallout = true
            
            pinView!.image = annotation.pinImage()
            pinView!.centerOffset = CGPoint(x: 0, y: -8)
            
            // This is for pin view - requires different object type
            // pinView!.pinColor = annotation.pinColor()
            
            if annotation.setFor != (FIRAuth.auth()?.currentUser?.uid)! || annotation.type == "private" {
                let completeIcon = UIImage(named: "edit-notepad.png")
                let completeButton: UIButton = UIButton(type: UIButtonType.custom)
                completeButton.frame = CGRect(x: 32, y: 32, width: 32, height: 32)
                completeButton.setImage(completeIcon, for: UIControlState())
                completeButton.addTarget(self, action: #selector(editButtonAction), for: UIControlEvents.touchUpInside)
                pinView!.leftCalloutAccessoryView = completeButton as UIView
            }
            
            let viewIcon = UIImage(named: "info.png")
            let viewButton: UIButton = UIButton(type: UIButtonType.custom)
            viewButton.frame = CGRect(x: 32, y: 32, width: 32, height: 32)
            viewButton.setImage(viewIcon, for: UIControlState())
            viewButton.addTarget(self, action: #selector(viewButtonAction), for: UIControlEvents.touchUpInside)
            pinView!.rightCalloutAccessoryView = viewButton as UIView
            
            return pinView
        }
        return nil
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        
        let circleRenderer = MKCircleRenderer(overlay: overlay)
        circleRenderer.lineWidth = 1.0
        circleRenderer.strokeColor = UIColor.gray
        circleRenderer.fillColor = UIColor.gray.withAlphaComponent(0.25)
        return circleRenderer
        
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
}

