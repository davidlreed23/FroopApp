//
//  userData.swift
//  FroopProof
//
//  Created by David Reed on 1/18/23.
//
import Foundation
import FirebaseFirestoreSwift
import CoreLocation
import Firebase
import Combine
import SwiftUI
import UIKit
import FirebaseFirestore
import MapKit

class UserData: ObservableObject, Hashable {

    var db = FirebaseServices.shared.db
    @Published var data = [String: Any]()
    let id: UUID = UUID()
    @Published var froopUserID: String = ""
    @Published var timeZone: String = TimeZone.current.identifier
    @Published var firstName: String = ""
    @Published var lastName: String = ""
    @Published var phoneNumber: String = ""
    @Published var addressNumber: String = ""
    @Published var addressStreet: String = ""
    @Published var unitName: String = ""
    @Published var addressCity: String = ""
    @Published var addressState: String = ""
    @Published var addressZip: String = ""
    @Published var addressCountry: String = ""
    @Published var profileImageUrl: String = ""
    @Published var fcmToken: String = ""
    
    @Published var coordinate: CLLocationCoordinate2D = CLLocationCoordinate2D()
    var geoPoint: GeoPoint {
        get {
            return GeoPoint(latitude: coordinate.latitude, longitude: coordinate.longitude)
        }
        set {
            let newCoordinate = CLLocationCoordinate2D(latitude: newValue.latitude, longitude: newValue.longitude)
            if newCoordinate.latitude != coordinate.latitude || newCoordinate.longitude != coordinate.longitude {
                self.coordinate = newCoordinate
            }
        }
    }
    
    @Published var badgeCount = 0
    
    static func == (lhs: UserData, rhs: UserData) -> Bool {
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(froopUserID)
        hasher.combine(id)
        hasher.combine(firstName)
        hasher.combine(lastName)
        hasher.combine(phoneNumber)
        hasher.combine(addressNumber)
        hasher.combine(addressStreet)
        hasher.combine(unitName)
        hasher.combine(addressCity)
        hasher.combine(addressState)
        hasher.combine(addressZip)
        hasher.combine(addressCountry)
        hasher.combine(timeZone)
        hasher.combine(profileImageUrl)
        hasher.combine(fcmToken)
        hasher.combine(badgeCount)
        hasher.combine(geoPoint)
    }
    
    var dictionary: [String: Any] {
        let geoPoint = FirebaseServices.shared.convertToGeoPoint(coordinate: coordinate)
        return [
            "froopUserID": froopUserID,
            "firstName": firstName,
            "lastName": lastName,
            "phoneNumber": phoneNumber,
            "addressNumber": addressNumber,
            "addressStreet": addressStreet,
            "unitName": unitName,
            "addressCity": addressCity,
            "addressState": addressState,
            "addressZip": addressZip,
            "addressCountry": addressCountry,
            "timeZone": timeZone,
            "profileImageUrl": profileImageUrl,
            "fcmToken": fcmToken,
            "badgeCount" : badgeCount,
            "coordinate": geoPoint
        ]
    }
    
    init?(dictionary: [String: Any]) {
        updateProperties(with: dictionary)
        
        // Check if the required properties have been set
        guard !self.froopUserID.isEmpty else {
            return nil
        }
    }

    private var cancellable: ListenerRegistration?

    init() {
       
        guard !FirebaseServices.shared.uid.isEmpty else {
            PrintControl.shared.printErrorMessages("Error: no user is currently signed in.")
            return
            
        }
        let uid = FirebaseServices.shared.uid
            // handle the case when no user is signed in or UID is empty
           
     
        let docRef = db.collection("users").document(uid)
        
        let listener = docRef.addSnapshotListener { (document, error) in
            if let document = document, let data = document.data() {
                self.updateProperties(with: data)
                self.fcmToken = data["fcmToken"] as? String ?? ""
                if let geoPoint = data["coordinate"] as? GeoPoint {
                    self.coordinate = FirebaseServices.shared.convertToCoordinate(geoPoint: geoPoint)
                }
            }
        }
        FirebaseServices.shared.listeners[uid] = listener
    }

    deinit {
        FirebaseServices.shared.removeListener(identifier: FirebaseServices.shared.uid)
    }
    
    
    private func updateProperties(with data: [String: Any]) {
       
        PrintControl.shared.printUserData("-UserData: Function: updateProperties is firing!")
        self.data = data
        self.froopUserID = data["froopUserID"] as? String ?? ""
        self.timeZone = data["timeZone"] as? String ?? TimeZone.current.identifier
        self.firstName = data["firstName"] as? String ?? ""
        self.lastName = data["lastName"] as? String ?? ""
        self.phoneNumber = data["phoneNumber"] as? String ?? ""
        self.addressNumber = data["addressNumber"] as? String ?? ""
        self.addressStreet = data["addressStreet"] as? String ?? ""
        self.unitName = data["unitName"] as? String ?? ""
        self.addressCity = data["addressCity"] as? String ?? ""
        self.addressState = data["addressState"] as? String ?? ""
        self.addressZip = data["addressZip"] as? String ?? ""
        self.addressCountry = data["addressCountry"] as? String ?? ""
        self.profileImageUrl = data["profileImageUrl"] as? String ?? ""
        self.fcmToken = data["fcmToken"] as? String ?? ""
        self.badgeCount = data["badgeCount"] as? Int ?? 0
        if let geoPoint = data["coordinate"] as? GeoPoint {
            self.coordinate = CLLocationCoordinate2D(latitude: geoPoint.latitude, longitude: geoPoint.longitude)
        }
        PrintControl.shared.printUserData("--------retrieving User Data")
    }
}

struct SavedLocation: Codable {
    let title: String
    let address: String
    let latitude: Double
    let longitude: Double
}

enum AccountType: Int, Codable {
    case passenger
    case driver
}

struct Vehicle: Codable {
    let make: String
    let model: String
    let year: Int
    let color: VehicleColors
    let licensePlateNumber: String
    let type: RideType
}

enum VehicleColors: Int, CaseIterable, Identifiable, Codable {
    case black
    case white
    case red
    case yellow
    case gray
    case silver
    case blue
    case tan
    
    var id: Int { self.rawValue }
    
    var description: String {
        switch self {
        case .black: return "Black"
        case .white: return "White"
        case .red: return "Red"
        case .yellow: return "Yellow"
        case .gray: return "Gray"
        case .silver: return "Silver"
        case .blue: return "Blue"
        case .tan: return "Tan"
        }
    }
}
