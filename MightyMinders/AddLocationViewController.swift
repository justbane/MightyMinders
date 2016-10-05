//
//  AddLocationViewController.swift
//  MightyMinders
//
//  Created by Justin Bane on 5/11/15.
//  Copyright (c) 2015 Justin Bane. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

class AddLocationViewController: MMCustomViewController, MKMapViewDelegate, CLLocationManagerDelegate {
    
    let ref = FIRDatabase.database().reference()
    var currentLocation: CLLocation!
    var selectedLocation = [String: AnyObject]()
    var matchingItems: [MKMapItem] = [MKMapItem]()

    let locationManager: CLLocationManager = CLLocationManager()
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var searchText: UITextField!
    @IBOutlet weak var sndItBack: UIButton!
    @IBOutlet weak var locationLbl: UILabel!
    @IBOutlet weak var useLocationCheckMark: UIImageView!
    @IBOutlet weak var closeBtn: UIButton!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        mapView.delegate = self
        
        // setup location manager
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestAlwaysAuthorization()
        
        // gesture setup for long press
        let lpgr = UILongPressGestureRecognizer(target: self, action: #selector(addPinAction))
        lpgr.minimumPressDuration = 2.0
        
        mapView.addGestureRecognizer(lpgr)
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        // check for valid user
        if FIRAuth.auth()?.currentUser == nil {
            super.showLogin()
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func doMapView() {
        
        // Set map region and add current location annotation
        if let location = CLLocationCoordinate2D(latitude: currentLocation.coordinate.latitude, longitude: currentLocation.coordinate.longitude) as CLLocationCoordinate2D? {
            
            let span = MKCoordinateSpanMake(0.04, 0.04)
            let region = MKCoordinateRegion(center: location, span: span)
            mapView.setRegion(region, animated: true)
            
            let annotation = MKPointAnnotation()
            annotation.coordinate = location
            annotation.title = "My current location"
            annotation.subtitle = "You are here :)"
            mapView.addAnnotation(annotation)
            
        }
        
    }
    
    // MARK: Segues
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        
        // check to see if segue should happen (have they selected a location?
        if identifier == "LocationUnwindSegue" {
            if selectedLocation.count < 1 {
                
                let notPermitted = UIAlertController(title: "Alert", message: "Please select a location from the map", preferredStyle: UIAlertControllerStyle.alert)
                let OKAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                notPermitted.addAction(OKAction)
                self.present(notPermitted, animated: true, completion: nil)
                
                return false
                
            }
        }
        
        return true
    }
    
    
    // MARK: Button Actions
    func addPinAction(_ sender: UIGestureRecognizer) {
        
        // Catch long touch and add pin/annotation
        if sender.state != UIGestureRecognizerState.began {
            return
        }
        
        let touchPoint: CGPoint = sender.location(in: mapView)
        let touchedCoordinate: CLLocationCoordinate2D = mapView.convert(touchPoint, toCoordinateFrom: mapView)
        
        let annotation = MKPointAnnotation()
        annotation.coordinate = touchedCoordinate
        annotation.title = "Dropped pin"
        self.mapView.addAnnotation(annotation)
        
    }
    
    func pinButtonAction(_ sender: AnyObject) {
        
        // When an annotation button is pressed - handle action ans set data
        if self.mapView.selectedAnnotations.count == 0 {
            //no annotation selected
            return;
        }
        // Set selected location info
        if let annotation = self.mapView?.selectedAnnotations[0] {
            
            let geoCoder = CLGeocoder()
            let selectedLocation = CLLocation(latitude: annotation.coordinate.latitude, longitude: annotation.coordinate.longitude)
            
            geoCoder.reverseGeocodeLocation(selectedLocation, completionHandler: { (placemarks, error) -> Void in
                let placeArray = placemarks! as [CLPlacemark]
                
                var placeMark: CLPlacemark
                placeMark = placeArray[0]
                
                if let title: String = annotation.title! {
                    self.locationLbl.text = title
                    self.locationLbl.textColor = UIColor.gray
                    self.selectedLocation["name"] = title as AnyObject?
                }
                
                if let address = placeMark.thoroughfare {
                    self.locationLbl.text = "\(self.locationLbl.text!) at \(address)"
                    self.selectedLocation["address"] = address as AnyObject?
                }
                
                self.useLocationCheckMark.isHidden = false
                
                self.selectedLocation["latitude"] = annotation.coordinate.latitude as AnyObject?
                self.selectedLocation["longitude"] = annotation.coordinate.longitude as AnyObject?
                
                
            })
            
        }
        
    }
    
    @IBAction func closeBtnAction(_ sender: AnyObject) {
        
        self.dismiss(animated: true, completion: nil)
        
    }
    
    
    // MARK: Search Functions
    @IBAction func searchFieldReturn(_ sender: AnyObject) {
        
        // Init search on map
        _ = sender.resignFirstResponder()
        mapView.removeAnnotations(mapView.annotations)
        self.performSearch()
        
    }
    
    func performSearch() {
        
        // Handle search and set results pins
        matchingItems.removeAll()
        let request = MKLocalSearchRequest()
        request.naturalLanguageQuery = searchText.text
        request.region = mapView.region
        
        let search = MKLocalSearch(request: request)
        
        search.start { (response, error) -> Void in
            
            if error != nil {
                let alert = UIAlertController(title: "Search Error", message: "There was an error with your search: \(error!.localizedDescription)", preferredStyle: UIAlertControllerStyle.alert)
                let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil)
                
                // Add the actions
                alert.addAction(okAction)
                self.present(alert, animated: true, completion: nil)
                
            } else if response!.mapItems.count == 0 {
                let alert = UIAlertController(title: "No Matches Found", message: "No matches found for your search", preferredStyle: UIAlertControllerStyle.alert)
                let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil)
                
                // Add the actions
                alert.addAction(okAction)
                self.present(alert, animated: true, completion: nil)
                
            } else {
                // print("Matches found")
                
                for item in response!.mapItems {
                    //print("Name = \(item.name)")
                    //print("Phone = \(item.phoneNumber)")
                    
                    self.matchingItems.append(item as MKMapItem)
                    //print("Matching items = \(self.matchingItems.count)")
                    
                    let annotation = MKPointAnnotation()
                    annotation.coordinate = item.placemark.coordinate
                    annotation.title = item.name
                    self.mapView.addAnnotation(annotation)
                    
                }
                
                let annotationOnMap = self.mapView.annotations
                self.mapView.showAnnotations(annotationOnMap, animated: true)
            }
        }
    }
    
    
    
    // MARK: Location Manager
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedAlways || status == .authorizedWhenInUse {
            locationManager.startUpdatingLocation()
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
        
        currentLocation = manager.location
        doMapView()
        
        locationManager.stopUpdatingLocation()
        
    }
    
    
    
    // MARK: Required Methods
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        // Draw map view and setup the annotation buttons and handler
        if annotation is MKUserLocation {
            // Return nil so map view draws "blue dot" for standard user location
            return nil
        }
        
        let reuseId = "pin"
        
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.canShowCallout = true
            pinView!.animatesDrop = true
            pinView!.pinTintColor = .green
            
            let pinIcon = UIImage(named: "sign-add.png")
            
            let pinButton: UIButton = UIButton(type: UIButtonType.custom)
            pinButton.frame = CGRect(x: 32, y: 32, width: 32, height: 32)
            pinButton.setImage(pinIcon, for: UIControlState())
            pinButton.addTarget(self, action: #selector(pinButtonAction), for: UIControlEvents.touchUpInside)
            
            pinView!.rightCalloutAccessoryView = pinButton as UIView
            
        }
        else {
            pinView!.annotation = annotation
        }
        
        return pinView
        
    }

}
