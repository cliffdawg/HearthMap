//
//  HotspotTableViewController.swift
//  Hearth
//
//  Created by Clifford Yin on 3/25/17.
//  Copyright © 2017 Clifford Yin. All rights reserved.
//
//

import UIKit
import MapKit
import ChameleonFramework
import CoreData
import CoreLocation
import Firebase

// Global variable represents an array of all the addresses from hotSpotDict
var hotspotArr = [String]()

/* Lists all the biggest hotspots around the user */
class HotspotTableViewController: UITableViewController {
    var addresses = [NSManagedObject]()
    var ref: FIRDatabaseReference!
    // Default constructor
    var location: CLLocationCoordinate2D!
    
    @IBOutlet weak var hotspotTable: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        ref = FIRDatabase.database().reference()
    
        let edgeInsets = UIEdgeInsetsMake(20, 0, 0, 0)
        self.tableView.contentInset = edgeInsets
        // Extract all the hotspot data from core data
        let appDelegate3 = UIApplication.shared.delegate as! AppDelegate
        let managedContext3 = appDelegate3.managedObjectContext
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Hotspot")
        let sortDescriptor = NSSortDescriptor(key: "frequency", ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptor]
    
        do {
            let results = try managedContext3.fetch(fetchRequest)
            self.addresses = results as! [NSManagedObject]
    
        } catch let error as NSError {
            print("Could not fetch \(error), \(error.userInfo)")
        }

        var n = 0
        for object in self.addresses{
            
            let freq = object.value(forKey: "frequency")
            let freqString = String(describing: freq)
            let lat = object.value(forKey: "lat")
            let latString = String(describing: lat)
            let long = object.value(forKey: "long")
            let longString = String(describing: long)
            let address = object.value(forKey: "address")!
            let addressString = String(describing: address)
            hotSpotDict["\(n)"] = ["address": addressString, "long": longString, "lat": latString, "freq": freqString]
            n += 1 // Assigned to progressive hotspot indexes in hotspotDict
        }
        
        // Implement Chameleon graphics
        let colors:[UIColor] = [
            UIColor.randomFlat(),
            UIColor.flatMint()
        ]
        
        view.backgroundColor = GradientColor(gradientStyle: UIGradientStyle.topToBottom, frame: view.frame, colors: colors)

    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        let heapList = PriorityQueue<[String:String]>()
        
        for (_, locationInfo) in hotSpotDict {
            heapList.push(((locationInfo["freq"]! as NSString).integerValue), item:locationInfo)
        }
        
        var x = 0
        
        hotspotArr.removeAll()
    
        let count = heapList.count
        while (x < count){
            
            var (_, loc)  = heapList.pop()
            let hotSpot = loc["address"]! as String
            hotspotArr.append(hotSpot)
            
            x += 1
            
        }
        
        return hotspotArr.count
    }
    
    // Loads hotspots into tableView
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.textLabel?.text = hotspotArr[indexPath.row]

        return cell
    }
    
    // Proceeds to navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if ((segue.identifier == "pressed2")){
            let destVC =  segue.destination as! ViewController
            destVC.pinLocation = self.location
            openMapsAppWithDirections(to: destVC.pinLocation, destinationName: destVC.title!)
        }
    }
    
    // In navigation, allows directions to location to be represented in Maps
    func openMapsAppWithDirections(to coordinate: CLLocationCoordinate2D, destinationName name: String) {
        let options = [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving]
        let placemark = MKPlacemark(coordinate: coordinate, addressDictionary: nil)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = name
        mapItem.openInMaps(launchOptions: options)
    }
    
    // Instantiates location for corresponding row
    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        let lat = addresses[indexPath.row].value(forKey: "lat") as! Double
        let long = addresses[indexPath.row].value(forKey: "long") as! Double
        self.location = CLLocationCoordinate2D(latitude: lat, longitude: long)
        
        return indexPath
    }
}
