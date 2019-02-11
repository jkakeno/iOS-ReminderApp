//
//  DetailViewController.swift
//  ReminderApp
//
//  Created by Jun Kakeno on 2/7/19.
//  Copyright © 2019 Jun Kakeno. All rights reserved.
//

import Foundation
import UIKit
import CoreData
import MapKit


/*Business search: https://stackoverflow.com/questions/30992213/swift-mapkit-automatic-business-search*/


protocol SavePressProtocol {
    func didPressSave()->Void
}

class DetailViewController: UIViewController{
    
    var context: NSManagedObjectContext?
    var reminder: Reminder?
    
    @IBOutlet weak var reminderText: UITextField!
    @IBOutlet weak var segControl: UISegmentedControl!
    @IBOutlet weak var locationSearchBar: UISearchBar!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var searchResultTable: UITableView!
    
    let locationManager = CLLocationManager()
    var coordinate: CLLocationCoordinate2D?
    var mapItems: [MKMapItem] = []
    
//    var notificationManager = NotificationManager()
    
    var searchBarText: String?
    var saveProtocol: SavePressProtocol?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self
        locationSearchBar.delegate = self
        
        //Configure Location
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        
        searchResultTable.delegate = self
        searchResultTable.dataSource = self
        
        reminderText.delegate = self
        
        configureView()
    }
    
    func configureView() {
        searchResultTable.isHidden = true
        if let reminder = reminder {
            reminderText.text = reminder.text
            segControl.selectedSegmentIndex = reminder.onEntry ? 0 : 1
            addCircle(toCoordinate: CLLocationCoordinate2D(latitude: reminder.lat, longitude: reminder.lng))
            
            print("Selected reminder: \(reminder.id), \(reminder.text), \(reminder.lat), \(reminder.lng)")
        }
    }
    
    @IBAction func saveReminder(_ sender: UIBarButtonItem) {
        guard let context = context, let text = reminderText.text, !text.isEmpty, let coordinate = self.coordinate else {
            alertWith(title: "Alert", message: "Please fill all fields")
            return
        }

        let onEntry = segControl.selectedSegmentIndex == 0
        
        if let reminder = reminder {
            reminderText.text = reminder.text
            
            if reminder.onEntry {
                segControl.selectedSegmentIndex = 0
            }else{
                segControl.selectedSegmentIndex = 1
            }
            
            let coordinate = CLLocationCoordinate2DMake(reminder.lat, reminder.lng)
            addCircle(toCoordinate: coordinate)
            
            let reminder = Reminder.update(reminder, text: text, date: Date(), lat: coordinate.latitude, lng: coordinate.longitude, onEntry: onEntry, in: context)
//            notificationManager.scheduleNotification(withReminder: reminder)
            
            regionMonitoring(reminder)
            
            print("Modified reminder -> \(reminder.id), \(reminder.text), \(reminder.lat), \(reminder.lng)")
        }else{
            let reminder = Reminder.create(text, date: Date(), lat: coordinate.latitude, lng: coordinate.longitude, onEntry: onEntry, in: context)
//            notificationManager.scheduleNotification(withReminder: reminder)
            
            regionMonitoring(reminder)
            
            print("New reminder -> \(reminder.id), \(reminder.text), \(reminder.lat), \(reminder.lng)")
        }
        
        context.saveChanges()
        navigationController?.popViewController(animated: true)
        dismiss(animated: true, completion: nil)

        //Notify DiaryListController that save button was pressed
        saveProtocol?.didPressSave()
    }
    
    // Function that enables monitoring of geofences
    
    func regionMonitoring(_ reminder: Reminder) {
        
        let geofenceRegionCenter = CLLocationCoordinate2DMake(reminder.lat, reminder.lng)
        let geofenceRegion: CLCircularRegion = CLCircularRegion(center: geofenceRegionCenter, radius: 30, identifier: reminder.id)
        
        if reminder.onEntry {
            geofenceRegion.notifyOnEntry = true
            geofenceRegion.notifyOnExit = false
        } else {
            geofenceRegion.notifyOnExit = true
            geofenceRegion.notifyOnEntry = false
        }
        locationManager.startMonitoring(for: geofenceRegion)
//        print("Monitored regions: \(locationManager.monitoredRegions)")
        
    }
    
    func alertWith(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "Close", style: UIAlertAction.Style.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    func addCircle(toCoordinate coordinate: CLLocationCoordinate2D) {
        let annotation = MKPointAnnotation()
        annotation.title = "Place"
        annotation.coordinate = coordinate
        mapView.addAnnotation(annotation)
        
        let span = MKCoordinateSpan(latitudeDelta: 0.002, longitudeDelta: 0.002)
        let region = MKCoordinateRegion(center: coordinate, span: span)
        mapView.setRegion(region, animated: true)
        
        let circle = MKCircle(center: coordinate, radius: 30 as CLLocationDistance)
        mapView.addOverlay(circle)
    }
}

extension DetailViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let circle = MKCircleRenderer(overlay: overlay)
        circle.strokeColor = UIColor.red
        circle.fillColor = UIColor.red.withAlphaComponent(0.1)
        circle.lineWidth = 1
        return circle
    }
}

//Allows DONE button to exit the keyboard
extension DetailViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return false
    }
}

extension DetailViewController:UISearchBarDelegate{
    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        locationSearchBar = searchBar
        return true
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        print(searchBar.text as Any)
        locationSearchBar = searchBar
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {

        //Search bussiness
        searchBarText = searchBar.text
        guard let searchBarText = searchBarText else { return }
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchBarText
        request.region = mapView.region
        let search = MKLocalSearch(request: request)
        search.start { response, _ in
            guard let response = response else {return}
            self.mapItems = response.mapItems
            self.searchResultTable.reloadData()
        }
        
        //Dismiss the keyboard
        self.view.endEditing(true)
        
        if searchResultTable.isHidden{
            searchResultTable.isHidden = false
        }
    }
}

extension DetailViewController: UITableViewDelegate{
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let place = mapItems[indexPath.row].placemark
        tableView.isHidden = true
        addCircle(toCoordinate: place.coordinate)
        coordinate = place.coordinate
    }
}

extension DetailViewController: UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return mapItems.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "LocationCell", for: indexPath)
        let place = mapItems[indexPath.row].placemark
        let address = parseAddress(place)
        
        if let itemName = place.name {
            cell.textLabel?.text = itemName
        }

        cell.detailTextLabel?.text = address

        return cell
    }
    
    // This method parses and formats location names/address for search queries
    
    func parseAddress(_ selectedItem: MKPlacemark) -> String {
        // space
        let firstSpace = (selectedItem.subThoroughfare != nil && selectedItem.thoroughfare != nil) ? " " : ""
        // comma between street and city
        let comma = (selectedItem.subThoroughfare != nil || selectedItem.thoroughfare != nil) && (selectedItem.subAdministrativeArea != nil || selectedItem.administrativeArea != nil) ? ", " : ""
        // space
        let secondSpace = (selectedItem.subAdministrativeArea != nil && selectedItem.administrativeArea != nil) ? " " : ""
        
        let addressLine = String(
            
            format:"%@%@%@%@%@%@%@",
            selectedItem.subThoroughfare ?? "",firstSpace, selectedItem.thoroughfare ?? "", comma, selectedItem.locality ?? "", secondSpace, selectedItem.administrativeArea ?? ""
        )
        return addressLine
    }
}

extension DetailViewController : CLLocationManagerDelegate {

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse {
            locationManager.requestLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first {
            print("Current Location: \(location.coordinate.latitude), \(location.coordinate.longitude)")
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Error: \(error.localizedDescription)")
    }
}


