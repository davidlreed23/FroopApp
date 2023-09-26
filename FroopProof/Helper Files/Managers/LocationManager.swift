//
//  LocationManager.swift
//  FroopProof
//
//  Created by David Reed on 1/19/23.
//

import CoreLocation
import MapKit
import Foundation
import FirebaseAuth
import FirebaseFirestore
import FirebaseAuth
import UIKit
import SwiftUI


final class LocationManager: NSObject, ObservableObject {
    static let shared = LocationManager()
    private let locationManager = CLLocationManager()
    @Published var locationCount = 0
    @Published var locations: [(count: Int, latitude: Double, longitude: Double)] = []
    @Published var user2DLocation: CLLocationCoordinate2D?
    @Published var userLocation: CLLocation?
    @Published var userLocationAddress: String?
    
    @Published var resolution: Double = 100
    
    private var isUpdating = false
    var locationUpdateTimer: Timer?
    var froopDataArray: [FroopData] = []
    @Published var isUserInsideGeofence: Bool = false
    @Published var guestArrived: Bool = false
    @Published var guestLeft: Bool = false
    @Published var locationUpdateTimerOn: Bool = false
    
    var currentLocation: CLLocation?
    
    var geofenceRegion: CLCircularRegion? {
        didSet {
            if let region = geofenceRegion {
                locationManager.startMonitoring(for: region)
            } else {
                if let oldRegion = oldValue {
                    locationManager.stopMonitoring(for: oldRegion)
                }
            }
        }
    }
    
    var froopData = FroopData(dictionary: [:]) {
        didSet {
            let center = froopData?.froopLocationCoordinate
            let radius = 100.0 // Adjust this value according to your requirements
            let identifier = "Froop Geofence"
            geofenceRegion = CLCircularRegion(center: center ?? CLLocationCoordinate2D(), radius: radius, identifier: identifier)
        }
    }
    
    //Use:  // Inside ChildView
    //    LocationManager.shared.froopData = self.froopData // Set the FroopData object
    //    LocationManager.shared.startUpdating() // Start updating the user's location
    
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = CLLocationDistance(resolution) // Set the minimum distance a device must move before an update is generated
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.showsBackgroundLocationIndicator = true
        locationManager.pausesLocationUpdatesAutomatically = false
    }
    
    var appStateManager: AppStateManager {
        return AppStateManager.shared
    }
    var printControl: PrintControl {
        return PrintControl.shared
    }
    var firebaseServices: FirebaseServices {
        return FirebaseServices.shared
    }
    var froopDataListener: FroopDataListener {
        return FroopDataListener.shared
    }
    var froopDataController: FroopDataController {
        return FroopDataController.shared
    }
    var locationServices: LocationServices {
        return LocationServices.shared
    }
    
    func startUpdating() {
        locationManager.startUpdatingLocation()
        isUpdating = true
    }
    
    func requestAlwaysAuthorization() {
        locationManager.requestAlwaysAuthorization()
    }
    
    func requestSingleUpdate () {
        locationManager.requestWhenInUseAuthorization()
        locationManager.requestLocation()
    }
    
    func updateUserLocationInFirestore() {
        guard firebaseServices.isAuthenticated else {
               return
           }
        let uid = FirebaseServices.shared.uid
        let db = FirebaseServices.shared.db
        let docRef = db.collection("users").document(uid)
            // Get the current location
            if let location = self.getLocation() {
                PrintControl.shared.printLocationServices("Location: \(location)")
                // Update the user document with the current location
                docRef.updateData([
                    "geoPoint": GeoPoint(latitude: location.latitude, longitude: location.longitude),
                    "coordinate": GeoPoint(latitude: location.latitude, longitude: location.longitude)
                ]) { error in
                    if let error = error {
                        PrintControl.shared.printErrorMessages("Error updating user document with location: \(error)")
                    } else {
                        PrintControl.shared.printLocationServices("User location updated successfully at:  \(Date())")
                        PrintControl.shared.printLocationServices("User Latitude \(location.latitude), Longitude: \(location.longitude)")
                    }
                }
            } else {
                PrintControl.shared.printErrorMessages("Failed to get user location.")
            }
    }
    
    func stopUpdating() {
        PrintControl.shared.printLocationServices("-LocationManager: Function: stopUpdating is firing!")
        guard isUpdating else { return }
        locationManager.stopUpdatingLocation()
        isUpdating = false
        TimerServices.shared.shouldCallupdateUserLocationInFirestore = false
    }
    
    func getLocation() -> CLLocationCoordinate2D? {
        return locationManager.location?.coordinate
    }
    
    func stopUpdatingUserLocationInFirestore() {
        locationUpdateTimer?.invalidate()
        locationUpdateTimer = nil
        locationUpdateTimerOn = false
    }
    
    func notifyBackendUserArrival(uid: String, froopId: String, completionHandler: @escaping (Result<Bool, Error>) -> Void) {
        PrintControl.shared.printLocationServices("-LocationManager: Function: notifyBackendUserArrival is firing!")
        // Replace this URL with the actual API endpoint for your backend
        let urlString = "https://yourbackend.com/api/user_arrival"
        
        guard let url = URL(string: urlString) else {
            completionHandler(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let parameters: [String: Any] = [
            "uid": uid,
            "froopId": froopId
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: parameters, options: [])
        } catch {
            completionHandler(.failure(error))
            return
        }
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completionHandler(.failure(error))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse, (200..<300).contains(httpResponse.statusCode) else {
                completionHandler(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid HTTP response"])))
                return
            }
            
            completionHandler(.success(true))
        }
        
        task.resume()
    }
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        if region.identifier == geofenceRegion?.identifier {
            PrintControl.shared.printLocationServices("-LocationManager: Function: locationManager is firing!")
            isUserInsideGeofence = true
            notifyBackendUserArrival(uid: FirebaseServices.shared.uid, froopId: self.froopData?.froopId ?? "") { result in
                switch result {
                case .success(let isArrivalNotified):
                    PrintControl.shared.printNotifications("Arrival notification sent successfully: \(isArrivalNotified)")
                case .failure(let error):
                    PrintControl.shared.printErrorMessages("Error sending arrival notification: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        if region.identifier == geofenceRegion?.identifier {
            PrintControl.shared.printLocationServices("-LocationManager: Function: locationManager is firing!")
            isUserInsideGeofence = false
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        PrintControl.shared.printLocationServices("-LocationManager: Function: notifyBackendUserArrival is firing!")
        switch status {
        case .denied, .restricted:
            stopUpdatingUserLocationInFirestore()
            stopUpdating()
            PrintControl.shared.printLocationServices("updating userLocation THREE")
        default:
            break
        }
    }
    
    func calculateTravelTime(from sourceCoordinate: CLLocationCoordinate2D, to destinationCoordinate: CLLocationCoordinate2D, completion: @escaping (TimeInterval?) -> Void) {
        PrintControl.shared.printLocationServices("-LocationManager: Function: calculateTravelTime is firing!")
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: sourceCoordinate))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: destinationCoordinate))
        request.transportType = .automobile
        
        let directions = MKDirections(request: request)
        directions.calculateETA { response, error in
            if let error = error {
                PrintControl.shared.printErrorMessages("Error calculating travel time: \(error.localizedDescription)")
                completion(nil)
                return
            }
            guard let etaResponse = response else {
                completion(nil)
                return
            }
            completion(etaResponse.expectedTravelTime)
        }
    }
    
    func rescheduleLocalNotification(for froopData: FroopData, travelTime: TimeInterval) {
        PrintControl.shared.printLocationServices("-LocationManager: Function: rescheduleLocalNotification is firing!")
        let notificationId = "\(froopData.froopId)_travel_time_notification"
        
        // Remove any existing notification with the same ID
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [notificationId])
        
        // Schedule a new notification
        let content = UNMutableNotificationContent()
        content.title = "Time to leave for your Froop"
        content.body = "It's time to head out for your Froop: \(froopData.froopName)."
        content.sound = .default
        
        let triggerTime = froopData.froopStartTime.addingTimeInterval(-travelTime)
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: triggerTime)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        let request = UNNotificationRequest(identifier: notificationId, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                PrintControl.shared.printErrorMessages("Error scheduling notification: \(error.localizedDescription)")
            } else {
                PrintControl.shared.printLocationServices("Notification scheduled for travel time.")
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        PrintControl.shared.printErrorMessages("Failed to get user's location: \(error)")
    }
    
}


