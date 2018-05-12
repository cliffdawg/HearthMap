//
//  ViewController.swift
//  Hearth
//
//  Created by Clifford Yin on 3/25/17.
//  Copyright © 2017 Clifford Yin. All rights reserved.
//
//

import UIKit
import MapKit
import CoreData
import CoreLocation
import Firebase
import FirebaseDatabase
import ChameleonFramework

var id = UIDevice.current.identifierForVendor!.uuidString

//This global variable is a nested dictionary that is used throughout the project to store the hotspots with an address key.
// - Address:frequency:coordinates
var hotSpotDict = [String:[String:String]]()

// Stores all the pins
var allPlaces = [Dictionary<String,String>()]
var activePlace = -1
var annotationAddress = MKPointAnnotation()


/* Code that manages the ViewController class. It is the very first view controller that shows up and is the view that controls the Map View where all hotspots and pins are displayed. */
class ViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate, UIPopoverControllerDelegate, UIPopoverPresentationControllerDelegate {
    
    var addresses = [NSManagedObject]()
    // This variable is created for the hotspot overlay
    var circle:MKCircle!
    var circle2:MKCircle!
    var ref: FIRDatabaseReference!
    @IBOutlet var currLoc: UILabel!
    var newAddress: Bool!
    // This variable is a reference to the map interface on the storyboard
    @IBOutlet var mapView: MKMapView!
    var pinLocation: CLLocationCoordinate2D!
    var pinning = false
    var locationManager = CLLocationManager()
    var searching = [String]()
    var backgroundTaskIdentifier: UIBackgroundTaskIdentifier?
    var onlineHotspots = [OnlineHotspot]()
    var currentLocation: CLLocation!
    var yell = false
    var pins = [NSManagedObject]()
    var timer: Timer!
    var timer2: Timer!
    var directing = [String]()
    
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var detailsButton: UIButton!
    
    // MARK: ViewController overrides
    
    // This sets up the Map View and requests permission from the user
    override func viewDidLoad() {
        
        super.viewDidLoad()
        ref = FIRDatabase.database().reference()
        self.mapView.delegate = self
        
        cancelButton.isHidden = true
        detailsButton.isHidden = true
        cancelButton.isEnabled = false
        detailsButton.isEnabled = false
        
        self.ref.child("hotspots").child("demo").setValue(["frequency": Int(-1), "lat": Double(37.2400490280629), "long": Double(-119.503235535758)])
        
        backgroundTaskIdentifier = UIApplication.shared.beginBackgroundTask(expirationHandler: {
            UIApplication.shared.endBackgroundTask(self.backgroundTaskIdentifier!)
        })
        // Code creates a timer; it increments a location's frequency every 10800 seconds to reflect time spent there by people.
        
            timer = Timer.scheduledTimer(timeInterval: 10800, target: self, selector: #selector(ViewController.update), userInfo: nil, repeats: true)
            timer2 = Timer.scheduledTimer(timeInterval: 10800, target: self, selector: #selector(ViewController.update2), userInfo: nil, repeats: true)
        
            // Setting value that shows if app has been launched before
            UserDefaults.standard.set(true, forKey: "launchedBefore")
        
        // Initiate location manager
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        locationManager.startMonitoringSignificantLocationChanges()
        self.loadPins()
        self.load3()
        
        let when = DispatchTime.now() + 2
        DispatchQueue.main.asyncAfter(deadline: when) {
            self.loadRed()  // Handle red overlays
            self.onlineLoad() // Handle yellow overlays
        }
        
        
        // Code to check how many pins have been dropped by the user - if it is the user's first time opening the app it will request authorization to collect location data.
        if (activePlace == -1){
            
            locationManager.requestAlwaysAuthorization()
            update()
            
        } else{
            
            // Adds the pin to the allPlaces dictionary
            self.load3()
            
        }
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle:nil)
        // Handling of true/false for having launched this pap before
        let launchedBefore = UserDefaults.standard.string(forKey: "hearthLaunchedBefore")
        if (launchedBefore != nil) {
            print("Not first launch.")
        } else {
            let TutorialViewController = storyBoard.instantiateViewController(withIdentifier: "Tutorial") as! UIPageViewController
            self.present(TutorialViewController, animated: true, completion: nil)
            print("First launch, setting UserDefault.")
            UserDefaults.standard.set("yes", forKey: "hearthLaunchedBefore")
        }
    }
    
 
    // Controls when the timer will start collecting the data
    func update() {
        locationManager.startUpdatingLocation()
        
    }
    
    // Send updated data to Firebase
    func update2() {
        self.firebaseSearch()
        let when = DispatchTime.now() + 4
        DispatchQueue.main.asyncAfter(deadline: when) {
            self.firebaseUpdate()
        }
    }

    // Processes user attempt to open up in Maps
    @IBAction func details(_ sender: Any) {
        
        let popoverViewController = self.storyboard?.instantiateViewController(withIdentifier: "directions") as! Directions
        popoverViewController.modalPresentationStyle = .popover
        popoverViewController.preferredContentSize = CGSize(width:550, height:150)
        popoverViewController.directions = self.directing
        
        let popoverPresentationViewController = popoverViewController.popoverPresentationController
        popoverPresentationViewController?.permittedArrowDirections = UIPopoverArrowDirection.down
        popoverPresentationViewController?.delegate = self
        popoverPresentationViewController?.sourceView = self.detailsButton
        popoverPresentationViewController?.sourceRect = CGRect(x:0, y:0, width: detailsButton.bounds.width/2, height: 30)
        
        present(popoverViewController, animated: true, completion: nil)

    }
    

    // Asks for permission to track location. Code centers the map around the user's current location; can test this by changing the location in debugging tab.
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        // Stops the timer after n seconds
        locationManager.stopUpdatingLocation()
        
        let userLocation: CLLocation = locations[0]
        
        self.currentLocation = locations[0]
        
        let latitude = userLocation.coordinate.latitude as Double
        let longitude = userLocation.coordinate.longitude as Double
        let latDelta:CLLocationDegrees = 0.04
        let lonDelta:CLLocationDegrees = 0.04
        let span:MKCoordinateSpan = MKCoordinateSpanMake(latDelta, lonDelta)
        let location:CLLocationCoordinate2D = CLLocationCoordinate2DMake(latitude, longitude)
        let region:MKCoordinateRegion = MKCoordinateRegionMake(location, span)
        
        if (self.pinning == false){
            self.mapView.setRegion(region, animated: true)
        
        } else {
            let viewRegion:MKCoordinateRegion = MKCoordinateRegionMake(self.pinLocation, span)
            self.mapView.setRegion(viewRegion, animated: true)
            
        }

        mapView.showsUserLocation = true
        
        self.load()
        // Code is used to return address given latitude, longitude and location - if no address is returned it will instead display the time added
        CLGeocoder().reverseGeocodeLocation(userLocation, completionHandler: {(placemarks, error) -> Void in
            
            if (placemarks != nil){
                if placemarks!.count > 0 {
                    let pm = placemarks![0]
                    var addressOut: String!
                    let number: String! = pm.subThoroughfare
                    let road: String! = pm.thoroughfare
                    
                    if((number != nil) && (road != nil)){
                        self.newAddress = true
                        addressOut = number! + " " + road!
                        
                        for object in self.addresses{
                            if (object.value(forKey: "address") as! String == addressOut){
                                self.newAddress = false
                            }
                        }
                        
                        self.currLoc.text = addressOut
                        
                        // Adds the first instance of an address to the hotspot dictionary in core data/Firebase - if it is already entered, the frequency is increased
                        if (self.newAddress == true){
                            
                            let freq = -1
                            
                            self.addNew(address: addressOut, frequency: freq, lat: latitude, long: longitude)
                            
                        } else { //increment frequency
                            
                            for object in self.addresses{
                                if (object.value(forKey: "address") as! String == addressOut){
                                    let appDelegate3 = UIApplication.shared.delegate as! AppDelegate
                                    let managedContext = appDelegate3.managedObjectContext
                                    let location = object
                                    let freq1 = location.value(forKey: "frequency") as! Int
                                    
                                    do {
                                        try managedContext.save()
                                        location.setValue(freq1 - 1, forKey: "frequency") // Increment
                                        
                                    } catch let error as NSError  {
                                        print("Could not save \(error), \(error.userInfo)")
                                    }
                                }
                            }
                        }
                    }
                }
            }
            else {
                print("Problem with the data received from geocoder.")
                }
            })
        
        
        // Creates a gesture recognizer - when the user presses down for 0.35 seconds. the action function will be invoked.
        let longTouch = UILongPressGestureRecognizer(target: self, action: #selector(ViewController.action(_:)))
        longTouch.minimumPressDuration = 0.35
        mapView.addGestureRecognizer(longTouch)
    }
    
    // Handles red overlay
    func loadRed() {
        self.yell = false
        var n = 0
        // Code goes through the hotSpotArr of hotspot addresses and for each location renders a new circle with varying radius based on frequency
     
        while (n < self.addresses.count){
            let hotLat = self.addresses[n].value(forKey: "lat") as! Double
            let hotLong = self.addresses[n].value(forKey: "long") as! Double
            let hotLoc = CLLocationCoordinate2DMake(hotLat, hotLong)
            let radial = -(self.addresses[n].value(forKey: "frequency") as! Int)
            
            if (radial < 100) {
                var limit = 0
                var radialLimit = 0
                if (limit < 20 && radialLimit < radial) {
                    self.circle = MKCircle(center: hotLoc, radius: (Double(limit) * 100.00))
                    self.mapView.add(self.circle)
                    
                    limit += 1
                    radialLimit += 5
                }
            }
            if (radial > 100) {
                self.circle = MKCircle(center: hotLoc, radius: 1000)
                self.mapView.add(self.circle)
            }
            n += 1
        }
    }
    
    // Handles yellow overlay
    func onlineLoad(){
        self.yell = true
        var m = 0
        // Code goes through the list of online hotspot addresses and for each location renders a new circle with varying radius based on frequency
        while (m < self.onlineHotspots.count){
            let onlineLat = self.onlineHotspots[m].lat!
            let onlineLong = self.onlineHotspots[m].long!
            let onlineLoc = CLLocationCoordinate2DMake(onlineLat, onlineLong)
            let radial = -(self.onlineHotspots[m].frequency!)
            
            if (radial < 600) {
                var limit = 0
                var radialLimit = 0
                    while (limit < 20 && radialLimit < radial) {
                    
                    
                    self.circle2 = MKCircle(center: onlineLoc, radius: (Double(limit) * 100.00))
                    
                    
                    self.mapView.add(self.circle2)
                    
                    limit += 1
                    radialLimit += 30
                    }
            }
            if (radial > 600) {
                self.circle2 = MKCircle(center: onlineLoc, radius: 1000)
                self.mapView.add(self.circle2)
                
            }
            m += 1
        }
    }
    
    func firebaseSearch(){
        ref.child("hotspots").observe(.value, with: { (snapshot) -> Void in
            self.searching.removeAll()
            for item in snapshot.children {
                let childSnapshot = snapshot.childSnapshot(forPath: (item as AnyObject).key)
                self.searching.append(childSnapshot.key)
                }
            })
    }

    // Sends new data to Firebase
    func firebaseUpdate(){
        for hotspot in self.addresses {
            if (self.searching.contains(hotspot.value(forKey: "address") as! String)){
                
                    let name = hotspot.value(forKey: "address") as! String
                    let updateRef = FIRDatabase.database().reference().child("hotspots").child(name).child("frequency")
                            
                    updateRef.runTransactionBlock({ (frequency) -> FIRTransactionResult in
                        if let frequencyInitial = frequency.value as? Int{
                                    
                            frequency.value = frequencyInitial - 1
                            return FIRTransactionResult.success(withValue: frequency)
                                } else {
                                    return FIRTransactionResult.success(withValue: frequency)
                                }
                            }, andCompletionBlock: {(error,completion,snap) in
                                if !completion {
                                    print("Couldn't update")
                                }else{
                                    print("Completion")
                                }
                            })
                } else {
                        self.ref.child("hotspots").child(hotspot.value(forKey: "address") as! String).setValue(["frequency": Int(-1), "lat": hotspot.value(forKey: "lat") as! Double, "long": hotspot.value(forKey: "long") as! Double])
                
                }
            }
    }
    
    // Loads the pins stored in user's core data
    func loadPins() {
        let appDelegate3 = UIApplication.shared.delegate as! AppDelegate
        let managedContext3 = appDelegate3.managedObjectContext
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Hotspot")
        let fetchRequest2 = NSFetchRequest<NSFetchRequestResult>(entityName: "Pin")
        
        let sortDescriptor = NSSortDescriptor(key: "frequency", ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        do {
            let results = try managedContext3.fetch(fetchRequest)
            let results2 = try managedContext3.fetch(fetchRequest2)
            self.addresses = results as! [NSManagedObject]
            self.pins = results2 as! [NSManagedObject]
            
        } catch let error as NSError {
            print("Could not fetch \(error), \(error.userInfo)")
        }

    }

    // Load user hotspots/pins
    func load(){
        let appDelegate3 = UIApplication.shared.delegate as! AppDelegate
        let managedContext3 = appDelegate3.managedObjectContext
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Hotspot")
        let fetchRequest2 = NSFetchRequest<NSFetchRequestResult>(entityName: "Pin")
        let sortDescriptor = NSSortDescriptor(key: "frequency", ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptor]
            do {
                let results =
                try managedContext3.fetch(fetchRequest)
                let results2 = try managedContext3.fetch(fetchRequest2)
                self.addresses = results as! [NSManagedObject]
                self.pins = results2 as! [NSManagedObject]
        
                } catch let error as NSError {
                    print("Could not fetch \(error), \(error.userInfo)")
                    }
        
        // Extract the location info and frequency data
        ref.child("hotspots").queryOrdered(byChild: "frequency").observe(.value) { (snapshot: FIRDataSnapshot!) in
            self.onlineHotspots.removeAll()
            var count = 0
            for item in snapshot.children{
                let childSnapshot = snapshot.childSnapshot(forPath: (item as AnyObject).key)
                let freqValue = childSnapshot.value as! NSDictionary
                let freq = freqValue["frequency"] as! Int
                let latValue = childSnapshot.value as? NSDictionary
                let lat = latValue?["lat"] as! Double
                let longValue = childSnapshot.value as? NSDictionary
                let long = longValue?["long"] as! Double
                let name = childSnapshot.key
                let onlineLocate =  CLLocation(latitude: lat, longitude: long)
                let distance = self.currentLocation.distance(from: onlineLocate)
                
                if (distance < 64374) { // 64374 is max distance, 40 miles
                    if (count < 20) {
                        let adding = OnlineHotspot(add: name, freq: freq, lati: lat, longi: long)
                        self.onlineHotspots.append(adding)
                        count += 1
                    }
                }
            }
        }
    
    }
    
    
    // Function is used to render a red circle around every hotspot. The more a user stays in a location, the larger the circles will be rendered and the darker they will be
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if overlay.isKind(of: MKPolyline.self) {
            // Draw the track
            let polyLineRenderer = MKPolylineRenderer(overlay: overlay)
            polyLineRenderer.strokeColor = UIColor(red: 25/255, green: 136/255, blue: 227/255, alpha: 0.75)
            polyLineRenderer.lineWidth = 4.0
            return polyLineRenderer
        }
        
        let circleRenderer = MKCircleRenderer(overlay: overlay)
        if (self.yell == false) {
            circleRenderer.fillColor = UIColor.flatRed().withAlphaComponent(0.035)
            circleRenderer.lineWidth = 0.45
            return circleRenderer
        } else if (self.yell == true) { // Online hotspot
            circleRenderer.fillColor = UIColor.flatYellow().withAlphaComponent(0.035)
            circleRenderer.lineWidth = 0.45
            return circleRenderer
        }
        else {
            circleRenderer.strokeColor = UIColor.flatWhiteColorDark().withAlphaComponent(0.025)
            circleRenderer.lineWidth = 0.45
            return circleRenderer
        }
    }
    
    // Add a new hotspot
    func addNew(address:String, frequency:Int, lat:Double, long :Double) {
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let managedContext = appDelegate.managedObjectContext
        let entity =  NSEntityDescription.entity(forEntityName: "Hotspot", in: managedContext)
        let adding = NSManagedObject(entity: entity!, insertInto: managedContext)
        
        adding.setValue(address, forKey: "address")
        adding.setValue(frequency, forKey: "frequency")
        adding.setValue(lat, forKey: "lat")
        adding.setValue(long, forKey: "long")
        
        do {
            try managedContext.save()
            addresses.append(adding)
        } catch let error as NSError  {
            print("Could not save \(error), \(error.userInfo)")
        }
    }

    // Add new pin
    func addNew2(address:String, lat:Double, long :Double) {
       
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let managedContext = appDelegate.managedObjectContext
        let entity =  NSEntityDescription.entity(forEntityName: "Pin", in: managedContext)
        let adding = NSManagedObject(entity: entity!, insertInto: managedContext)
        
        adding.setValue(address, forKey: "address")
        adding.setValue(lat, forKey: "lat")
        adding.setValue(long, forKey: "long")
        
        do {
            try managedContext.save()
            self.pins.append(adding)
        } catch let error as NSError  {
            print("Could not save \(error), \(error.userInfo)")
        }
    }

    
    func load3(){
        
        for object in self.pins{
            let annotation = MKPointAnnotation()
            annotation.coordinate.latitude = object.value(forKey: "lat") as! Double
            annotation.coordinate.longitude = object.value(forKey: "long") as! Double
            annotation.title = object.value(forKey: "address") as? String
            annotationAddress = annotation
            
            let dropPin = CustomAnnotation.init(coordinate: annotation.coordinate, title: annotation.title!, subtitle: "Dropped Pin", detailURL: NSURL(string: "https://google.com")!, enableInfoButton: true)
            
            self.mapView.addAnnotation(dropPin)
        }
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if !(annotation is CustomAnnotation) {
            return nil
        }
        
        let customAnnotation = annotation as! CustomAnnotation
        var view = mapView.dequeueReusableAnnotationView(withIdentifier: "CustomAnnotation") as? MKPinAnnotationView
        if (view == nil) {
            view = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "CustomAnnotation")
            view?.isEnabled = true
            view?.canShowCallout = true
        }
        else {
            view?.annotation = annotation
            view?.isEnabled = true
            view?.canShowCallout = true
        }
        
        if(customAnnotation.enableInfoButton) {
            
            // Displays info button for navigation
            let customCoordinate = customAnnotation.coordinate
            let infoButton = UIButton(type: UIButtonType.infoLight)
            infoButton.frame.size.width = 35
            infoButton.frame.size.height = 35
            infoButton.backgroundColor = UIColor.white
            self.addGesture(button: infoButton, coord: customCoordinate)
            view!.rightCalloutAccessoryView = infoButton
        }
        
        return view
    }
    
    // Adds info capability to be clicked
    func addGesture(button: UIButton, coord: CLLocationCoordinate2D) {
        let expandGesture = UITapGestureRecognizer(target: self, action: #selector(self.infoClicked(_:)))
        button.addGestureRecognizer(expandGesture)
    }
    
    // Cancels info button
    @IBAction func cancelButton(_ sender: Any) {
        let overlays = self.mapView.overlays
        self.mapView.removeOverlays(overlays)
        self.cancelButton.isHidden = true
        self.detailsButton.isHidden = true
        cancelButton.isEnabled = false
        detailsButton.isEnabled = false
    }
    
    
    // Implements navigation
    func getDirections(to coordinate: CLLocationCoordinate2D) {
        let sourceLocation = locationManager.location?.coordinate
        let destinationLocation = coordinate
        let sourcePlacemark = MKPlacemark(coordinate: sourceLocation!, addressDictionary: nil)
        let destinationPlacemark = MKPlacemark(coordinate: destinationLocation, addressDictionary: nil)
        let sourceMapItem = MKMapItem(placemark: sourcePlacemark)
        let destinationMapItem = MKMapItem(placemark: destinationPlacemark)
        let directionRequest = MKDirectionsRequest()
        
        directionRequest.source = sourceMapItem
        directionRequest.destination = destinationMapItem
        directionRequest.transportType = .automobile
        directionRequest.requestsAlternateRoutes = false
        
        let directions = MKDirections(request: directionRequest)
        
        directions.calculate(completionHandler: {(response, error) in
            if error != nil {
                print("Error getting directions")
            } else {
                print("show route")
                self.showRoute(response!)
            }
        })
    }
    
    // Shows user's intended route
    func showRoute(_ response: MKDirectionsResponse) {
        
        for route in response.routes {
            self.mapView.add(route.polyline, level: .aboveRoads)
            self.directing.removeAll()
            for step in route.steps {
                directing.append(step.instructions)
            }
            
            let rect = route.polyline.boundingMapRect
            self.mapView.setRegion(MKCoordinateRegionForMapRect(rect), animated: true)
        }
    }
    

    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        let annotation = MKPointAnnotation()
        annotation.coordinate.latitude = view.annotation?.coordinate.latitude as! Double
        annotation.coordinate.longitude = view.annotation?.coordinate.longitude as! Double
        annotation.title = view.annotation?.title as? String
        annotationAddress = annotation
    }
    
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return .none
    }

  
    func infoClicked(_ sender: UITapGestureRecognizer) {
        getDirections(to: annotationAddress.coordinate)
        cancelButton.isHidden = false
        detailsButton.isHidden = false
        cancelButton.isEnabled = true
        detailsButton.isEnabled = true
    }
    
    // If user presses on Map View for 2 seconds+, it will drop a pin
    func action(_ gestureRecognizer: UIGestureRecognizer){
        
        if (gestureRecognizer.state == UIGestureRecognizerState.began) {
            
            let touchPoint = gestureRecognizer.location(in: self.mapView)
            let newCoordinate: CLLocationCoordinate2D = mapView.convert(touchPoint, toCoordinateFrom: self.mapView)
            let location = CLLocation(latitude: newCoordinate.latitude, longitude: newCoordinate.longitude)
            // Adds the address to the pin by using reverseGeocodeLocation
            CLGeocoder().reverseGeocodeLocation(location, completionHandler: {(placemarks, error) -> Void in
                
                var title = ""
                if (error == nil) {
                    if let p = placemarks?[0] {
                        var subThoroughfare:String = ""
                        var thoroughfare:String = ""
                        
                        if p.subThoroughfare != nil {
                            subThoroughfare = p.subThoroughfare!
                        }
                        
                        if p.thoroughfare != nil {
                            thoroughfare = p.thoroughfare!
                        }
                        
                        title = "\(subThoroughfare) \(thoroughfare)"
                        
                    }
                }
                
                if title.trimmingCharacters(in: CharacterSet.whitespaces) == "" {
                    title = "Added \(Date())"
                }
                
                // Adds the new address to the Dictioanry
                self.addNew2(address: title, lat: newCoordinate.latitude, long: newCoordinate.longitude)
                self.load3()
            })
    
        }
    }
    
}
