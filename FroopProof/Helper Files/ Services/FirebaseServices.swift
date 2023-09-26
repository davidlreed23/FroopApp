//
//  FirebaseServices.swift
//  FroopProof
//
//  Created by David Reed on 5/16/23.
//

import Foundation
import Firebase
import FirebaseAuth
import FirebaseFirestore
import FirebaseCore
import FirebaseStorage
import FirebaseDatabase
import FirebaseSessions
import FirebaseAnalyticsSwift
import FirebaseCrashlytics
import FirebaseDatabaseSwift
import FirebaseSharedSwift
import FirebaseFirestoreSwift
import UserNotifications
import MapKit
import CoreLocation
import SwiftUI

class FirebaseServices: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    
    static let shared = FirebaseServices()
    
    @Published var userTasks: Int = 0
    @Published var userLocation: CLLocationCoordinate2D?
    
    
    
    var db: Firestore
    var uid: String
    var storage: Storage
    var database: Database
    
    var listener: ListenerRegistration?
    var temporaryListener: ListenerRegistration?
    var listeners: [String: ListenerRegistration] = [:]
    
    var tasks: [StorageUploadTask] = []
    
    private var authStateDidChangeListenerHandle: AuthStateDidChangeListenerHandle?
    
    var isAuthenticated: Bool {
        return !uid.isEmpty
    }
    
    private override init() {
        self.db = Firestore.firestore()
        self.uid = Auth.auth().currentUser?.uid ?? ""
        self.storage = Storage.storage()
        self.database = Database.database()
        
        super.init()

        authStateDidChangeListenerHandle = Auth.auth().addStateDidChangeListener { (auth, user) in
            if let user = user {
                self.uid = user.uid
            } else {
                self.uid = ""
                self.stopAllListeners()
                self.cancelAllTasks()
            }
        }
    }
    
    var myData: MyData {
        return MyData.shared
    }
    
    var timerServices: TimerServices {
        return TimerServices.shared
    }
    
    var printControl: PrintControl {
        return PrintControl.shared
    }
 
    var froopDataController: FroopDataController {
        return FroopDataController.shared
    }
    
    var locationServices: LocationServices {
        return LocationServices.shared
    }
    
    var locationManager: LocationManager {
        return LocationManager.shared
    }
    
    func getDownloadUrl(uid: String, completion: @escaping (URL?) -> Void) {
        let profilePicRef = storage.reference().child("ProfilePic/\(uid)")

        profilePicRef.downloadURL { url, error in
            if let error = error {
                print("Error getting download URL: \(error)")
                completion(nil)
            } else {
                completion(url)
            }
        }
    }
    
    func checkSMSInvitations () {
        guard !myData.phoneNumber.isEmpty else {
            print("Phone number is empty")
            return
        }
        
        let smsInvitationsRef = db.collection("smsInvitations")
        let invitationRef = smsInvitationsRef.document(myData.phoneNumber)
        print("myData.phoneNumber: \(myData.phoneNumber)")
        invitationRef.getDocument { document, error in
            if let error = error {
                print("Error getting document: \(error)")
            } else if let document = document, document.exists {
                // An invitation exists for this phone number
                print("An invitation exists for this phone number")
                
                // Extract senderUid from the document
                if let senderUid = document.get("senderUid") as? String {
                    print("Sender UID: \(senderUid)")
                    // Call acceptFriendRequest function with senderUid
                    FriendRequestManager.shared.acceptSMSInvitation(senderUid: senderUid, uid: self.uid){ (success) in
                        print("Triggering Friend Request Manager Accept Friend Request Function")
                        if success {
                            print("Friend request accepted successfully.")
                            invitationRef.delete { error in
                                if let error = error {
                                    print("Error removing document: \(error)")
                                } else {
                                    print("Document successfully removed!")
                                }
                            }
                        } else {
                            print("Failed to accept friend request.")
                        }
                    }
                } else {
                    print("Could not find senderUid in the document")
                }
            } else {
                // No invitation exists for this phone number
                print("No invitation exists for this phone number")
            }
        }
    }
    
    func checkDoc(userID: String, completion: @escaping (Bool) -> Void) {
        let db = Firestore.firestore()
        let docRef = db.collection("users").document(userID)

        docRef.getDocument { (document, error) in
            if let error = error {
                completion(false)
                print("Error getting document: \(error)")
            } else if let document = document, document.exists {
                completion(true)
                print("Found document")
            } else {
                completion(false)
            }
        }
    }
    
    static func requestBadgePermission(completion: @escaping (Bool) -> Void) {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.badge]) { (granted, error) in
            // You may want to handle errors in here too
            completion(granted)
        }
    }
    
    func saveUserFcmToken() {
        // Get the FCM token from user defaults
        guard let fcmToken = UserDefaults.standard.value(forKey: "fcmToken") else{
            return
        }
        let uid = FirebaseServices.shared.uid
        let userDocRef = Firestore.firestore().collection("users").document(uid)
        userDocRef.updateData(["fcmToken": fcmToken]) { error in
            if let error = error {
                print("Error updating user document with fcmToken: \(error)")
            } else {
                print(">> UPDATED FCM TOKEN: ", "USER: ", uid, "FCM TOKEN: ", fcmToken)
            }
        }
    }
    
    func listenToInvitesList(uid: String, update: @escaping ([Froop]) -> Void) {
        if let listener = FroopDataListener.shared.listenToInvitesList(uid: uid) {
            addListener(identifier: "InvitesList", listener: listener)
        }
    }
    
    func listenToConfirmedList(uid: String, update: @escaping ([Froop]) -> Void) {
        if let listener = FroopDataListener.shared.listenToConfirmedList(uid: uid) {
            addListener(identifier: "ConfirmedList", listener: listener)
        }
    }
    
    func listenToDeclinedList(uid: String, update: @escaping ([Froop]) -> Void) {
        if let listener = FroopDataListener.shared.listenToDeclinedList(uid: uid) {
            addListener(identifier: "DeclinedList", listener: listener)
        }
    }
    
    func addListener(identifier: String, listener: ListenerRegistration) {
        listeners[identifier] = listener
    }
    
    func removeListener(identifier: String) {
            listeners[identifier]?.remove()
            listeners.removeValue(forKey: identifier)
        }
    
    func stopAllListeners() {
        for (identifier, listener) in listeners {
            listener.remove()
        }
        listeners.removeAll()
    }
    
    func cancelAllTasks() {
        for task in tasks {
            task.cancel()
        }
        tasks.removeAll()
    }
    
    static func setBadgeCount(_ count: Int) {
        UIApplication.shared.applicationIconBadgeNumber = count
    }
    
    // Convert CLLocationCoordinate2D to GeoPoint
    func convertToGeoPoint(coordinate: CLLocationCoordinate2D) -> GeoPoint {
        return GeoPoint(latitude: coordinate.latitude, longitude: coordinate.longitude)
    }
    
    // Convert GeoPoint to CLLocationCoordinate2D
    func convertToCoordinate(geoPoint: GeoPoint) -> CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: geoPoint.latitude, longitude: geoPoint.longitude)
    }
    
    func listenToFroopData(uid: String, froopId: String, update: @escaping ([String: Any]) -> Void) -> ListenerRegistration? {
        guard !uid.isEmpty, !froopId.isEmpty else {
            PrintControl.shared.printFirebaseOperations(uid)
            PrintControl.shared.printFirebaseOperations(froopId)
            PrintControl.shared.printErrorMessages("Invalid uid or froopId")
            return nil
        }

        let docRef = db.collection("users").document(uid).collection("myFroops").document(froopId)
        let listener = docRef.addSnapshotListener { (document, error) in
            if let document = document {
                update(document.data() ?? [:])
            } else if let error = error {
                PrintControl.shared.printErrorMessages("Error listening for document updates: \(error)")
            }
        }
        return listener
    }

}
