//
//  Reminder.swift
//  ReminderApp
//
//  Created by Jun Kakeno on 2/7/19.
//  Copyright © 2019 Jun Kakeno. All rights reserved.
//

import Foundation
import CoreData


/*NOTE: To prevent 'Ambiguise class' error
 1. Go to .xcdatamodelid
 2. Click on Entity
 3. Click on Model Inspector on right pane
 4. Module = Current Product Module and Codegen = Manual / None
 */

//Core data model
public class Reminder: NSManagedObject {
    
}

extension Reminder {
    //Method to read data from core data and return the data sorted
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Reminder> {
        let request = NSFetchRequest<Reminder>(entityName: "Reminder")
        let sortDescriptor = NSSortDescriptor(key: "date", ascending: true)
        request.sortDescriptors = [sortDescriptor]
        return request
    }
    
    //Object attributes
    @NSManaged public var id: String
    @NSManaged public var date: Date
    @NSManaged public var text: String
    @NSManaged public var lat: Double
    @NSManaged public var lng: Double
    @NSManaged public var onEntry: Bool
}

extension Reminder {
    //Computated property that returns the name of the class
    static var entityName: String {
        return String(describing: Reminder.self)
    }
    
    @nonobjc class func create(_ text: String, date: Date, lat: Double, lng: Double, onEntry: Bool, in context: NSManagedObjectContext) -> Reminder {
        let reminder = NSEntityDescription.insertNewObject(forEntityName: Reminder.entityName, into: context) as! Reminder
        
        reminder.id = UUID().description
        reminder.date = Date()
        reminder.lat = lat
        reminder.lng = lng
        reminder.text = text
        reminder.onEntry = onEntry
        
        return reminder
    }
    
    @nonobjc class func update(_ reminder: Reminder, text: String, date: Date, lat: Double, lng: Double, onEntry: Bool, in context: NSManagedObjectContext) -> Reminder {
        
        reminder.date = Date()
        reminder.lat = lat
        reminder.lng = lng
        reminder.text = text
        reminder.onEntry = onEntry
        
        return reminder
    }
}

