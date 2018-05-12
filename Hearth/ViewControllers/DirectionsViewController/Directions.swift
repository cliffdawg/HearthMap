//
//  Directions.swift
//  Hearth
//
//  Created by Clifford Yin on 9/8/17.
//  Copyright © 2017 Clifford Yin. All rights reserved.
//

import UIKit
import MapKit
import CoreData
import CoreLocation
import Firebase
import FirebaseDatabase
import ChameleonFramework

/* Code visually displays the directions while navigating */
class Directions: UITableViewController {

    var directions = [String]()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return directions.count
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "direction", for: indexPath) as? Direct
        cell?.configure(directed: directions[indexPath.row])
        
        return cell!
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
    {
        return 50.0;
    }
}
