//
//  FroopData.swift
//  FroopProof
//
//  Created by David Reed on 1/19/23.
//

import SwiftUI
import Firebase
import MapKit
import UIKit
import FirebaseFirestore
import FirebaseFirestoreSwift
import CoreLocation
import Foundation

class FroopData: NSObject, ObservableObject, Decodable {
    
    
    @ObservedObject var printControl = PrintControl.shared
    @ObservedObject var froopDataListener = FroopDataListener.shared
    
    var db = FirebaseServices.shared.db
    let uid = FirebaseServices.shared.uid
    @Published var timeZoneManager = TimeZoneManager()
    @Published var data = [String: Any]()
    let id: UUID = UUID()
    @Published var froopId: String = ""
    @Published var froopName: String = ""
    @Published var froopType: Int = 0
    @Published var froopLocationid = 0
    @Published var froopLocationTimeZone = ""
    @Published var froopLocationtitle = ""
    @Published var froopLocationsubtitle = ""
    @Published var froopLocationlatitude: Double = 0.0
    @Published var froopLocationlongitude: Double = 0.0
    @Published var froopLocationCoordinate: CLLocationCoordinate2D = CLLocationCoordinate2D()
    var geoPoint: GeoPoint {
        get {
            return GeoPoint(latitude: froopLocationCoordinate.latitude, longitude: froopLocationCoordinate.longitude)
        }
        set {
            let newCoordinate = CLLocationCoordinate2D(latitude: newValue.latitude, longitude: newValue.longitude)
            if newCoordinate.latitude != froopLocationCoordinate.latitude || newCoordinate.longitude != froopLocationCoordinate.longitude {
                self.froopLocationCoordinate = newCoordinate
            }
        }
    }
    @Published var froopDate: Date = Date()
    @Published var froopStartTime: Date = Date()
    @Published var froopCreationTime: Date = Date()
    @Published var froopDuration: Int = 0
    @Published var froopInvitedFriends: [String] = []
    @Published var froopEndTime: Date = Date()
    @Published var froopImages: [String] = []
    @Published var froopDisplayImages: [String] = []
    @Published var froopThumbnailImages: [String] = []
    @Published var froopVideos: [String] = []
    @Published var froopHost: String = ""
    @Published var froopHostPic: String = ""
    @Published var froopTimeZone: String = ""
    @Published var froopMessage: String = ""
    @Published var froopList: [String] = []
    @Published var template: Bool = false
    
    
    
    
    
    required init(from decoder:Decoder) throws {
        super.init()
        let values = try decoder.container(keyedBy: CodingKeys.self)
        froopId = try values.decode(String.self, forKey: .froopId)
        froopName = try values.decode(String.self, forKey: .froopName)
        froopType = try values.decode(Int.self, forKey: .froopType)
        froopLocationid = try values.decode(Int.self, forKey: .froopLocationid)
        froopLocationTimeZone = try values.decode(String.self, forKey: .froopLocationTimeZone)
        froopLocationtitle = try values.decode(String.self, forKey: .froopLocationtitle)
        froopLocationsubtitle = try values.decode(String.self, forKey: .froopLocationsubtitle)
        froopLocationlatitude = try values.decode(Double.self, forKey: .froopLocationlatitude)
        froopLocationlongitude = try values.decode(Double.self, forKey: .froopLocationlongitude)
        froopDate = try values.decode(Date.self, forKey: .froopDate)
        froopStartTime = try values.decode(Date.self, forKey: .froopStartTime)
        froopCreationTime = try values.decode(Date.self, forKey: .froopCreationTime)
        froopDuration = try values.decode(Int.self, forKey: .froopDuration)
        froopInvitedFriends = try values.decode(Array.self, forKey: .froopInvitedFriends)
        froopEndTime = try values.decode(Date.self, forKey: .froopEndTime)
        froopImages = try values.decode(Array.self, forKey: .froopImages)
        froopDisplayImages = try values.decode(Array.self, forKey: .froopDisplayImages)
        froopThumbnailImages = try values.decode(Array.self, forKey: .froopThumbnailImages)
        froopVideos = try values.decode(Array.self, forKey: .froopVideos)
        froopHost = try values.decode(String.self, forKey: .froopHost)
        froopHostPic = try values.decode(String.self, forKey: .froopHostPic)
        froopTimeZone = try values.decode(String.self, forKey: .froopTimeZone)
        froopMessage = try values.decode(String.self, forKey: .froopMessage)
        froopList = try values.decode(Array.self, forKey: .froopList)
        template = try values.decode(Bool.self, forKey: .template)
        
    }
    
    enum CodingKeys: String, CodingKey {
        case froopId
        case froopName
        case froopType
        case froopLocationid
        case froopLocationtitle
        case froopLocationsubtitle
        case froopLocationlatitude
        case froopLocationlongitude
        case froopLocationTimeZone
        case froopDate
        case froopStartTime
        case froopCreationTime
        case froopDuration
        case froopInvitedFriends
        case froopEndTime
        case froopImages
        case froopDisplayImages
        case froopThumbnailImages
        case froopVideos
        case froopHost
        case froopHostPic
        case froopTimeZone
        case froopMessage
        case froopList
        case template
    }
    
    
    
    override init() {
        super.init()
    }
    
    
    var dictionary: [String: Any] {
        let geoPoint = convertToGeoPoint(coordinate: froopLocationCoordinate)
        return [
            "froopId": id.description,
            "froopName": froopName,
            "froopType": froopType,
            "froopLocationid": froopLocationid,
            "froopLocationtitle": froopLocationtitle,
            "froopLocationsubtitle": froopLocationsubtitle,
            "froopLocationCoordinate": geoPoint,
            "froopDate": convertLocalDateToUTC(date: froopDate, froopTimeZone: timeZoneManager.froopTimeZone ?? TimeZone.current),
            "froopStartTime": froopStartTime,
            "froopCreationTime": froopCreationTime,
            "froopDuration": froopDuration,
            "froopInvitedFriends": froopInvitedFriends,
            "froopEndTime": froopEndTime,
            "froopImages": froopImages,
            "froopDisplayImages": froopDisplayImages,
            "froopThumbnailImages": froopThumbnailImages,
            "froopVideos": froopVideos,
            "froopHost": froopHost,
            "froopHostPic": froopHostPic,
            "froopTimeZone": froopTimeZone,
            "froopMessage": froopMessage,
            "froopList": froopList,
            "template": template,
        ]
    }
    
    init?(dictionary: [String: Any]) {
        PrintControl.shared.printFroopData("Attempting to create Froop object from dictionary: \(dictionary)")
        super.init()
        updateProperties(with: dictionary)
        PrintControl.shared.printFroopData("Froop object created successfully")
    }
    
    
    private var cancellable: ListenerRegistration?
    private var _coordinate = CLLocationCoordinate2D()
    var mkLocalSearchCompletion: MKLocalSearchCompletion?
    
    var coordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: froopLocationlatitude, longitude: froopLocationlongitude)
    }
    var coordinateString: String {
        return "\(coordinate.latitude), \(coordinate.longitude)"
    }
    static func == (lhs: FroopData, rhs: FroopData) -> Bool {
        return lhs.froopLocationid == rhs.froopLocationid
    }
    func updateLocation(title: String, subtitle: String, latitude: Double, longitude: Double) {
        PrintControl.shared.printFroopData("-FroopData: Function: updateLocation is firing!")
        self.froopLocationtitle = title
        self.froopLocationsubtitle = subtitle
        self.froopLocationlatitude = latitude
        self.froopLocationlongitude = longitude
    }
    
    func saveData() {
        
        PrintControl.shared.printFroopData("-FroopData: Function: saveData firing")
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        dateFormatter.timeZone = TimeZone(identifier: "America/Los_Angeles")
        
        dateFormatter.timeZone = TimeZone(identifier: "UTC")
        if let froopTimeZone = timeZoneManager.froopTimeZone {
            froopStartTime = convertLocalDateToUTC(date: froopStartTime, froopTimeZone: froopTimeZone)
        }
        self.froopList = [""]
        self.froopMessage = "The Host has not added a message yet, stay tuned!"
        let uid = FirebaseServices.shared.uid
        let froopId = id.uuidString
        let myFroopDocRef = db.collection("users").document(uid).collection("myFroops").document(froopId)
        myFroopDocRef.setData(self.dictionary) { err in
            if let err = err {
                print("Error writing document: \(err)")
            } else {
                print("Document successfully written!")
            }
        }
        
        // Add the 'froopId' to the "confirmedList" document in the "froopDecisions" collection
        let froopHost = FirebaseServices.shared.uid
        let froopConfirmedListCollectionRef = db.collection("users").document(froopHost).collection("froopDecisions").document("froopLists").collection("myConfirmedList")
        froopConfirmedListCollectionRef.addDocument(data: [
            "froopHost": froopHost,
            "froopId": froopId
        ]) { err in
            if let err = err {
                PrintControl.shared.printErrorMessages("Error adding froopId to confirmedList: \(err)")
            } else {
                PrintControl.shared.printFroopData("FroopId added to myConfirmedList")
            }
        }
        
        // Add the current user's UID to the 'confirmedList' document in the 'invitedFriends' collection
        let confirmedListDocRef = db.collection("users").document(uid).collection("myFroops").document(froopId).collection("invitedFriends").document("confirmedList")
        confirmedListDocRef.setData(["uid": [uid]], merge: true) { err in
            if let err = err {
                PrintControl.shared.printFroopData("Error adding current user's UID to confirmedList: \(err)")
            } else {
                PrintControl.shared.printFroopData("Current user's UID added to confirmedList")
            }
        }
        // Create the 'inviteList' and 'declinedList' documents each with an empty 'uid' array
        let lists = ["inviteList", "declinedList"]
        for list in lists {
            let listDocRef = db.collection("users").document(uid).collection("myFroops").document(froopId).collection("invitedFriends").document(list)
            listDocRef.setData(["uid": [String]()], merge: true) { err in
                if let err = err {
                    PrintControl.shared.printFroopData("Error creating \(list) document: \(err)")
                } else {
                    PrintControl.shared.printFroopData("\(list) document successfully created")
                }
            }
        }
        self.updateFroopIdAndStartListener(newFroopId: froopId)
    }
    
    func convertLocalDateToUTC(date: Date, froopTimeZone: TimeZone) -> Date {
        PrintControl.shared.printFroopData("-FroopData: Function: convertLocalDateToUTC in FroopData firing")
        let timezoneOffset = froopTimeZone.secondsFromGMT()
        return date.addingTimeInterval(TimeInterval(-timezoneOffset))
    }
    
    private func updateProperties(with data: [String: Any]) {
        PrintControl.shared.printFroopData("-FroopData: Function: updateProperties is firing!")
        self.data = data
        self.froopId = data["froopId"] as? String ?? ""
        self.froopName = data["froopName"] as? String ?? ""
        self.froopType = data["froopType"] as? Int ?? 0
        self.froopLocationid = data["froopLocationid"] as? Int ?? 0
        self.froopLocationTimeZone = data["froopLocationTimeZone"] as? String ?? ""
        self.froopLocationtitle = data["froopLocationtitle"] as? String ?? ""
        self.froopLocationsubtitle = data["froopLocationsubtitle"] as? String ?? ""
        if let geoPoint = data["froopLocationCoordinate"] as? GeoPoint {
            self.froopLocationCoordinate = CLLocationCoordinate2D(latitude: geoPoint.latitude, longitude: geoPoint.longitude)
        }
        self.froopDate = (data["froopDate"] as? Timestamp)?.dateValue() ?? Date()
        self.froopStartTime = (data["froopStartTime"] as? Timestamp).map(convertTimestampToUTCDate) ?? Date()
        self.froopCreationTime = (data["froopCreationTime"] as? Timestamp)?.dateValue() ?? Date()
        self.froopDuration = data["froopDuration"] as? Int ?? 0
        self.froopInvitedFriends = data["froopInvitedFriends"] as? [String] ?? []
        self.froopEndTime = data["froopEndTime"] as? Date ?? Date()
        self.froopImages = data["froopImages"] as? [String] ?? []
        self.froopDisplayImages = data["froopDisplayImages"] as? [String] ?? []
        self.froopThumbnailImages = data["froopThumbnailImages"] as? [String] ?? []
        self.froopVideos = data["froopVideos"] as? [String] ?? []
        self.froopHost = data["froopHost"] as? String ?? (FirebaseServices.shared.uid)
        self.froopHostPic = data["froopHostPic"] as? String ?? ""
        self.froopTimeZone = data["froopTimeZone"] as? String ?? ""
        self.template = data["template"] as? Bool ?? false
        PrintControl.shared.printFroopData("retrieving froopData Data")
    }
    
    private func convertTimestampToUTCDate(timestamp: Timestamp) -> Date {
        PrintControl.shared.printFroopData("-FroopData: Function: convertTimestampToUTCDate is firing!")
        let utcCalendar = Calendar.current
        let date = timestamp.dateValue()
        let components = utcCalendar.dateComponents(in: TimeZone(identifier: "UTC")!, from: date)
        return utcCalendar.date(from: components)!
    }
    
    func updateFroopIdAndStartListener(newFroopId: String) {
        self.froopId = newFroopId
        if let listener = self.startListener() {
            FirebaseServices.shared.addListener(identifier: froopId, listener: listener)
        }
    }
    
    func startListener() -> ListenerRegistration? {
        if !uid.isEmpty && !froopId.isEmpty && cancellable == nil {
            cancellable = FirebaseServices.shared.listenToFroopData(uid: uid, froopId: froopId) { [weak self] data in
                self?.updateProperties(with: data)
            }
        }
        return cancellable
    }
    
    func convertToGeoPoint(coordinate: CLLocationCoordinate2D) -> GeoPoint {
        return GeoPoint(latitude: coordinate.latitude, longitude: coordinate.longitude)
    }
    
}

struct FroopInviteDataModel {
    let froopId: String
    let froopHost: String
}
