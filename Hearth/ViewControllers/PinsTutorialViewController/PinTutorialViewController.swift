//
//  PinTutorialViewController.swift
//  Hearth
//
//  Created by Clifford Yin on 6/17/17.
//  Copyright © 2017 Clifford Yin. All rights reserved.
//

import UIKit

/* Sets up pin .gif */
class PinTutorialViewController: UIViewController {
    
    @IBOutlet weak var gifView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        gifView.loadGif(name: "pin")
        
    }
}
