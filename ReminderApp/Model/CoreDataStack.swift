//
//  CoreStack.swift
//  ReminderApp
//
//  Created by Jun Kakeno on 2/7/19.
//  Copyright © 2019 Jun Kakeno. All rights reserved.
//

import Foundation
import CoreData

//Coredata tutorial: https://medium.com/xcblog/core-data-with-swift-4-for-beginners-1fc067cca707

//This class creates a context to store data in CoreData
class CoreDataStack {
    
    //Computed variable that returns a container to make a context
    private lazy var persistentContainer: NSPersistentContainer = {
        //Container argument refers to the coredata file name .xcdatamodel
        let container = NSPersistentContainer(name: "ReminderApp")
        container.loadPersistentStores() { storeDescription, error in
            if let error = error as NSError? {
                fatalError("Unresolved error: \(error), \(error.userInfo)")
            }
            
            storeDescription.shouldInferMappingModelAutomatically = true
            storeDescription.shouldMigrateStoreAutomatically = true
        }
        
        return container
    }()
    
    //Computed variable that returns a context to store data in core data
    lazy var managedObjectContext: NSManagedObjectContext = {
        let container = self.persistentContainer
        return container.viewContext
    }()
}

//Coredata context extension to save data to coredata if the data in the context has changed
extension NSManagedObjectContext {
    func saveChanges() {
        if self.hasChanges {
            do {
                try save()
            } catch {
                fatalError("Error: \(error.localizedDescription)")
            }
        }
    }
}


