//
//  NotificationManager.swift
//  ReminderApp
//
//  Created by Jun Kakeno on 2/9/19.
//  Copyright © 2019 Jun Kakeno. All rights reserved.
//

import Foundation
import UserNotifications
import CoreLocation

struct NotificationManager {
    
    let currentNotificationCenter = UNUserNotificationCenter.current()
    
    func scheduleNotification(withReminder reminder: Reminder) {
        let center = CLLocationCoordinate2D(latitude: reminder.lat, longitude: reminder.lng)
        print("Schedule's reminder's coordinates are -> Lat: \(reminder.lat) Lng: \(reminder.lng)")
        let region = CLCircularRegion(center: center, radius: 5 , identifier: reminder.text)
        
        if reminder.onEntry {
            region.notifyOnEntry = true
            region.notifyOnExit = false
        } else {
            region.notifyOnEntry = false
            region.notifyOnExit = true
        }
        
        //The trigger is the trigger to display the notification
        let trigger = UNLocationNotificationTrigger(region: region, repeats: false)
        
        //The content is the notification displayed
        let content = UNMutableNotificationContent()
        content.body = reminder.text
        content.sound = UNNotificationSound.default
        
        //NOTE: Notification doesn't display consistently
        //https://stackoverflow.com/questions/40628095/unlocationnotificationtrigger-not-working-in-simulator/41835750#41835750
        
        let request = UNNotificationRequest(identifier: reminder.text, content: content, trigger: trigger)
        currentNotificationCenter.add(request) { error in
            if let error = error {
                print(error)
            }
        }
    }
}
