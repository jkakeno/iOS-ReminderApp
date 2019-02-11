//
//  ViewController.swift
//  ReminderApp
//
//  Created by Jun Kakeno on 2/7/19.
//  Copyright © 2019 Jun Kakeno. All rights reserved.
//

import UIKit
import CoreData
import CoreLocation
import UserNotifications

class ListViewController: UITableViewController {
    
    let context = CoreDataStack().managedObjectContext
    
    lazy var data: [Reminder] = {
        let request: NSFetchRequest<Reminder> = Reminder.fetchRequest()
        var result:[Reminder] = []
        do {
            result = try context.fetch(request)
            print("There's currently \(result.count) entries in core data.")
        } catch {
            print("Failed")
        }
        return result
    }()

    @IBOutlet var reminderTableView: UITableView!
    
    var notificationManager = NotificationManager()
    let locationManager = CLLocationManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        reminderTableView.dataSource = self
        reminderTableView.delegate = self
        
        locationManager.delegate = self
        
        checkAuthorizationStatus()
        UNUserNotificationCenter.current().delegate = self
        
        updateTableView()
    }
    
    func checkAuthorizationStatus() {
        
        switch (CLLocationManager.authorizationStatus()) {
            
        case .notDetermined:
            locationManager.requestAlwaysAuthorization()
            print("not determined")
            
        case .denied:
            print("no location!")
            
        case .authorizedAlways:
            locationManager.startUpdatingLocation()
            
        case .authorizedWhenInUse:
            locationManager.requestAlwaysAuthorization()
            
        default:
            print("nothing")
            
        }
    }
    
    func updateTableView(){
        let request: NSFetchRequest<Reminder> = Reminder.fetchRequest()
        do {
            data = try context.fetch(request)
            
            print("Monitored regions: \(locationManager.monitoredRegions)")
            print("Core Data size: \(data.count)")
            
            if reminderTableView != nil {
                print("Reload table view data...")
                reminderTableView.reloadData()
            }
        } catch {
            print("Failed to get data from core data.")
        }
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Cell.reuseIdentifier, for: indexPath) as! Cell
        
        let reminder = data[indexPath.row]
        cell.reminderTitle.text = reminder.text
        return cell
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        let reminder = data[indexPath.row]
        if editingStyle == .delete {
            delete(reminder)
            //Remove cell from table
            tableView.deleteRows(at: [indexPath], with: .fade)
            //Reload table with data
            tableView.reloadData()
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let detailVC = storyboard?.instantiateViewController(withIdentifier: "DetailViewController") as? DetailViewController else { return }
        
        let reminder = data[indexPath.row]
        
        detailVC.context = context
        detailVC.reminder = reminder
        detailVC.saveProtocol = self
        navigationController?.pushViewController(detailVC, animated: true)
    }
    
    func delete(_ reminder: Reminder){
        stopMonitoring(reminder)
        notificationManager.currentNotificationCenter.removePendingNotificationRequests(withIdentifiers: [reminder.id])
        
        let request: NSFetchRequest<Reminder> = Reminder.fetchRequest()
        do {
            print("Delete reminder id: \(reminder.id)")
            context.delete(reminder)
            context.saveChanges()

            //Update data with new core data context
            data = try context.fetch(request)
    
        } catch {
            print("Failed to delete data from core data.")
        }
    }
    
    // removes geofences from monitored regions array
    
    func stopMonitoring(_ reminder: Reminder) {
        for region in locationManager.monitoredRegions {
            if reminder.id == region.identifier {
                locationManager.stopMonitoring(for: region)
                print("Stop monitoring reminder id: \(reminder.id)")
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
            if segue.identifier == "Add" {
            if let detailVC = segue.destination as? DetailViewController {
                detailVC.context = context
                detailVC.saveProtocol = self
            }
        }
    }
}

extension ListViewController:SavePressProtocol{
    func didPressSave() {
        updateTableView()
    }
}

extension ListViewController:CLLocationManagerDelegate{
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        print("Did exit region")
        if region is CLCircularRegion {
            
            handleEvent(forRegion: region)
            
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        print("Did enter region")
        if region is CLCircularRegion {
            
            handleEvent(forRegion: region)
            
        }
    }
    
    // This method triggers the local notification when the user enters/exits a given reminder
    
    func handleEvent(forRegion region: CLRegion) {
        
        let content = UNMutableNotificationContent()
        
        for reminder in data {
            
            if reminder.id == region.identifier {
                
                content.title = reminder.text
                
                content.sound = UNNotificationSound.default
                
                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
                
                let identifier = region.identifier
                
                let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
                
                UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
                
            }
        }
    }
}

//allows for the local notifcaiton to be displayed while in the app itself

extension ListViewController: UNUserNotificationCenterDelegate {

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {

        completionHandler([.alert, .sound])
    }
}
