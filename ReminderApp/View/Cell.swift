//
//  Cell.swift
//  ReminderApp
//
//  Created by Jun Kakeno on 2/7/19.
//  Copyright © 2019 Jun Kakeno. All rights reserved.
//

import UIKit

//This class represents a cell in table view
final class Cell: UITableViewCell {
    static let reuseIdentifier = String(describing: Cell.self)
    
    @IBOutlet weak var reminderTitle: UILabel!
    
    
    
}
