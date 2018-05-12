//
//  TableViewController.swift
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

// Code manages the tableView of user-added pins
class TableViewController: UITableViewController {
    
    @IBOutlet var doen: UINavigationBar!
    var location: CLLocationCoordinate2D!
    var pins = [NSManagedObject]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let edgeInsets = UIEdgeInsetsMake(20, 0, 0, 0)
        self.tableView.contentInset = edgeInsets
        
        // Load pins from core data
        let appDelegate3 = UIApplication.shared.delegate as! AppDelegate
        let managedContext3 = appDelegate3.managedObjectContext
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Pin")
     
        do {
            let results = try managedContext3.fetch(fetchRequest)
            pins = results as! [NSManagedObject]
            
        } catch let error as NSError {
            print("Could not fetch \(error), \(error.userInfo)")
        }
        // Chameleon
        let colors:[UIColor] = [
            UIColor.flatSand(),
            UIColor.randomFlat()
        ]
        
        view.backgroundColor = GradientColor(gradientStyle: UIGradientStyle.topToBottom, frame: view.frame, colors: colors)
        
        if allPlaces.count == -1 {
            allPlaces.remove(at: 0)
                    }
        
        for object in pins{
            let lat = object.value(forKey: "lat")
            let latString = String(describing: lat)
            let long = object.value(forKey: "long")
            let longString = String(describing: long)
            let address = object.value(forKey: "address")!
            let addressString = String(describing: address)
            
            allPlaces.append(["address": addressString,"lat": latString,"long": longString])
        }

    }
    
   
    override func numberOfSections(in tableView: UITableView) -> Int {
        
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.pins.count
    }
    
    
    // Sets up each pin's information in a cell
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.textLabel?.text = self.pins[indexPath.row].value(forKey: "address") as? String
        return cell
    }
    
    /// Enables user to delete pins
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        let appDel:AppDelegate = UIApplication.shared.delegate as! AppDelegate
        let context:NSManagedObjectContext = appDel.managedObjectContext

        if editingStyle == UITableViewCellEditingStyle.delete {
            context.delete(pins.remove(at: indexPath.row))
            do {
                try context.save()
            }
            catch {
            }
            tableView.deleteRows(at: [indexPath as IndexPath], with: UITableViewRowAnimation.automatic)
        }
    }
    
    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
      
        let lat = self.pins[indexPath.row].value(forKey: "lat") as! Double
        let long = self.pins[indexPath.row].value(forKey: "long") as! Double
        self.location = CLLocationCoordinate2D(latitude: lat, longitude: long)
        
        return indexPath
    }
    
    override func viewWillAppear(_ animated: Bool) {
        tableView.reloadData()
    }
    
    // Code to snap Map View to this location
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if ((segue.identifier == "pressed")){
            let destVC =  segue.destination as! ViewController
            destVC.pinLocation = self.location
            destVC.pinning = true
            destVC.update()
        }
    }
    
    // Implements navigation
    func openMapsAppWithDirections(to coordinate: CLLocationCoordinate2D, destinationName name: String) {
        let options = [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving]
        let placemark = MKPlacemark(coordinate: coordinate, addressDictionary: nil)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = name
        mapItem.openInMaps(launchOptions: options)
    }
    
}
