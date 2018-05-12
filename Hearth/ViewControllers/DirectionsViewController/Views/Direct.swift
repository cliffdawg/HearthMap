//
//  block.swift
//  HERO
//
//  Created by Clifford Yin on 5/16/17.
//  Copyright © 2017 Clifford Yin. All rights reserved.
//

import UIKit

/* Code for a singular direction */
class Direct: UITableViewCell {
    

    @IBOutlet weak var direct: UILabel!
   
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    func configure(directed: String) {
        self.direct.text = directed
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
}
