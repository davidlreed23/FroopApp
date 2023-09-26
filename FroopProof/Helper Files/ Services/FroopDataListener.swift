//
//  FroopDataListener.swift
//  FroopProof
//
//  Created by David Reed on 5/29/23.
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


class FroopDataListener: NSObject, ObservableObject {
    
    static let shared = FroopDataListener()
    
    @Published var myInvitesList: [Froop] = []
    @Published var myConfirmedList: [Froop] = []
    @Published var myDeclinedList: [Froop] = []
    @Published var myArchivedList: [Froop] = []
    @Published var friends: [UserData] = []
    
    @Published var froops: [String: Froop] = [:]
    @Published private var froopDatas: [String: FroopData] = [:]
    var listeners: [String: ListenerRegistration] = [:]
    
    override init() {
        super.init()
        startListeners()
    }
    
    deinit {
        stopListeners()
    }
    
    private func startListeners() {
        let uid = FirebaseServices.shared.uid
        
        // Start listeners for each list
        _ = listenToInvitesList(uid: uid)
        _ = listenToConfirmedList(uid: uid)
        _ = listenToDeclinedList(uid: uid)
        _ = listenToArchivedList(uid: uid)
    }
    
    private func stopListeners() {
        for listener in listeners.values {
            listener.remove()
        }
        listeners.removeAll()
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
    
    
    
    
    func getData(uid: String) {
        let friendListRef = db.collection("users").document(uid).collection("friends").document("friendList")
        
        friendListRef.getDocument { (document, error) in
            if let document = document, let friendUIDs = document["friendUIDs"] as? [String] {
                for friendUID in friendUIDs {
                    let friendRef = db.collection("users").document(friendUID)
                    friendRef.getDocument { (friendDocument, error) in
                        if let friendDocument = friendDocument, let data = friendDocument.data() {
                            DispatchQueue.main.async {
                                do {
                                    // Assuming you have an initializer or method to convert Firestore data to UserData
                                    let friendData = UserData(dictionary: data)
                                    self.friends.append(friendData ?? UserData())
                                }
                            }
                        }
                    }
                }
            } else {
                print("Error: Friend UIDs not found")
            }
        }
    }
    
    func addFroop(_ froop: Froop) {
        froops[froop.froopId] = froop
        addListener(for: froop.froopId)
    }
    
    func addFroopData(_ froopData: FroopData) {
        froopDatas[froopData.froopId] = froopData
        addListener(for: froopData.froopId)
    }
    
    func updateInvitesList(invitesList: [Froop]) {
        self.myInvitesList = invitesList
    }
    
    func updateConfirmedList(confirmedList: [Froop]) {
        self.myConfirmedList = confirmedList
    }
    
    func updateDeclinedList(declinedList: [Froop]) {
        self.myDeclinedList = declinedList
    }
    
    private func updateFroop(with data: [String: Any]) {
        guard let froopId = data["froopId"] as? String else {
            return
        }
        
        let updatedFroop = Froop(dictionary: data)
        froops[froopId] = updatedFroop
        // Update the lists
        DataController.shared.checkLists(uid: FirebaseServices.shared.uid) { (archivedList, confirmedList, declinedList, invitesList) in
            let invitesFroopList = invitesList.compactMap { self.froops[$0] }
            let confirmedFroopList = confirmedList.compactMap { self.froops[$0] }
            let declinedFroopList = declinedList.compactMap { self.froops[$0] }
            
            self.updateInvitesList(invitesList: invitesFroopList)
            self.updateConfirmedList(confirmedList: confirmedFroopList)
            self.updateDeclinedList(declinedList: declinedFroopList)
            dump(FroopDataListener.shared.myConfirmedList)
        }
    }
    
    
    private func addListener(for froopId: String) {
        if listeners[froopId] != nil {
            // Already listening for this froopId
            return
        }
        let listener = FirebaseServices.shared.listenToFroopData(uid: FirebaseServices.shared.uid, froopId: froopId) { [weak self] data in
            self?.updateFroop(with: data)
        }
        listeners[froopId] = listener
    }
    
    func listenToInvitesList(uid: String) -> ListenerRegistration? {
        let uid = FirebaseServices.shared.uid
        let docRef = db.collection("users").document(uid).collection("froopDecisions").document("froopLists").collection("myInvitesList")
        
        let listener = docRef.addSnapshotListener { (querySnapshot, error) in
            if let error = error {
                PrintControl.shared.printErrorMessages("Error listening for document updates: \(error)")
            } else {
                var invitesList: [Froop] = []
                let group = DispatchGroup()
                
                for document in querySnapshot!.documents {
                    let data = document.data()
                    
                    if data["placeholder"] as? String == "placeholder" {
                        continue
                    }
                    
                    guard let froopHost = data["froopHost"] as? String, let froopId = data["froopId"] as? String else {
                        PrintControl.shared.printErrorMessages("Invalid froopHost or froopId in data: \(data)")
                        continue
                    }
                    
                    let froopDocRef = db.collection("users").document(froopHost).collection("myFroops").document(froopId)
                    
                    group.enter()
                    froopDocRef.getDocument { (froopDocument, error) in
                        if let error = error {
                            PrintControl.shared.printErrorMessages("Error fetching Froop document: \(error)")
                        } else if let froopDocument = froopDocument, froopDocument.exists {
                            let froop = Froop(dictionary: froopDocument.data() ?? [:])
                            invitesList.append(froop)
                        } else {
                            PrintControl.shared.printErrorMessages("Froop document does not exist")
                        }
                        group.leave()
                    }
                }
                
                group.notify(queue: .main) {
                    FroopDataController.shared.myInvitesList = invitesList
                    print("myInvitesList Updated")
                    FroopManager.shared.createFroopHistory() { froopHistoryCollection in
                        DispatchQueue.main.async {
                            FroopManager.shared.froopHistory = froopHistoryCollection
                            print("FroopHistory collection updated. Total count: \(FroopManager.shared.froopHistory.count)")
                        }
                    }
                    FroopDataController.shared.processPastEvents()
                }
            }
        }
        return listener
    }
    
    func listenToConfirmedList(uid: String) -> ListenerRegistration? {
        let uid = FirebaseServices.shared.uid
        
        let docRef = db.collection("users").document(uid).collection("froopDecisions").document("froopLists").collection("myConfirmedList")
        let listener = docRef.addSnapshotListener { (querySnapshot, error) in
            if let error = error {
                PrintControl.shared.printErrorMessages("Error listening for document updates: \(error)")
            } else {
                var confirmedList: [Froop] = []
                let group = DispatchGroup()
                
                for document in querySnapshot!.documents {
                    let data = document.data()
                    
                    if data["placeholder"] as? String == "placeholder" {
                        continue
                    }
                    
                    guard let froopHost = data["froopHost"] as? String, let froopId = data["froopId"] as? String else {
                        PrintControl.shared.printErrorMessages("Invalid froopHost or froopId")
                        continue
                    }
                    
                    // Fetch the actual Froop data from the myFroops collection of the froopHost
                    let froopDocRef = db.collection("users").document(froopHost).collection("myFroops").document(froopId)
                    
                    group.enter()
                    froopDocRef.getDocument { (froopDocument, error) in
                        if let error = error {
                            PrintControl.shared.printErrorMessages("Error fetching Froop document: \(error)")
                        } else if let froopDocument = froopDocument, froopDocument.exists {
                            let froop = Froop(dictionary: froopDocument.data() ?? [:])
                            confirmedList.append(froop)
                        } else {
                            PrintControl.shared.printErrorMessages("Froop document does not exist")
                        }
                        group.leave()
                    }
                }
                
                group.notify(queue: .main) {
                    FroopDataController.shared.myConfirmedList = confirmedList
                    print("myConfirmedList Updated")
                    FroopManager.shared.createFroopHistory() { froopHistoryCollection in
                        DispatchQueue.main.async {
                            FroopManager.shared.froopHistory = froopHistoryCollection
                            print("FroopHistory collection updated. Total count: \(FroopManager.shared.froopHistory.count)")
                        }
                    }
                    FroopDataController.shared.processPastEvents()
<<<<<<< HEAD
                    
=======

>>>>>>> 170845f959ae66c5e6b49e018606b6ca8ef952cb
                }
            }
        }
        return listener
    }
    
    
    func listenToDeclinedList(uid: String) -> ListenerRegistration? {
        let uid = FirebaseServices.shared.uid
        
        let docRef = db.collection("users").document(uid).collection("froopDecisions").document("froopLists").collection("myDeclinedList")
        let listener = docRef.addSnapshotListener { (querySnapshot, error) in
            if let error = error {
                PrintControl.shared.printErrorMessages("Error listening for document updates: \(error)")
            } else {
                var declinedList: [Froop] = []
                let group = DispatchGroup()
                
                for document in querySnapshot!.documents {
                    let data = document.data()
                    
                    if data["placeholder"] as? String == "placeholder" {
                        continue
                    }
                    
                    guard let froopHost = data["froopHost"] as? String, let froopId = data["froopId"] as? String else {
                        PrintControl.shared.printErrorMessages("Invalid froopHost or froopId")
                        continue
                    }
                    
                    // Fetch the actual Froop data from the myFroops collection of the froopHost
                    let froopDocRef = db.collection("users").document(froopHost).collection("myFroops").document(froopId)
                    
                    group.enter()
                    froopDocRef.getDocument { (froopDocument, error) in
                        if let error = error {
                            PrintControl.shared.printErrorMessages("Error fetching Froop document: \(error)")
                        } else if let froopDocument = froopDocument, froopDocument.exists {
                            let froop = Froop(dictionary: froopDocument.data() ?? [:])
                            declinedList.append(froop)
                        } else {
                            PrintControl.shared.printErrorMessages("Froop document does not exist")
                        }
                        group.leave()
                    }
                }
                
                group.notify(queue: .main) {
                    FroopDataController.shared.myDeclinedList = declinedList
                    print("myDeclinedList Updated")
                    FroopManager.shared.createFroopHistory() { froopHistoryCollection in
                        DispatchQueue.main.async {
                            FroopManager.shared.froopHistory = froopHistoryCollection
                            print("FroopHistory collection updated. Total count: \(FroopManager.shared.froopHistory.count)")
                        }
                    }
                    FroopDataController.shared.processPastEvents()
<<<<<<< HEAD
                    
=======

>>>>>>> 170845f959ae66c5e6b49e018606b6ca8ef952cb
                }
            }
        }
        return listener
    }
    
    func listenToArchivedList(uid: String) -> ListenerRegistration? {
        let uid = FirebaseServices.shared.uid
        
        let docRef = db.collection("users").document(uid).collection("froopDecisions").document("froopLists").collection("myArchivedList")
        
        let listener = docRef.addSnapshotListener { (querySnapshot, error) in
            if let error = error {
                PrintControl.shared.printErrorMessages("Error listening for document updates: \(error)")
            } else {
                var archivedList: [Froop] = []
                let group = DispatchGroup()
                
                for document in querySnapshot!.documents {
                    let data = document.data()
                    
                    if data["placeholder"] as? String == "placeholder" {
                        continue
                    }
                    
                    guard let froopHost = data["froopHost"] as? String, let froopId = data["froopId"] as? String else {
                        PrintControl.shared.printErrorMessages("Invalid froopHost or froopId")
                        continue
                    }
                    
                    let froopDocRef = db.collection("users").document(froopHost).collection("myFroops").document(froopId)
                    
                    group.enter()
                    froopDocRef.getDocument { (froopDocument, error) in
                        if let error = error {
                            PrintControl.shared.printErrorMessages("Error fetching Froop document: \(error)")
                            group.leave() // make sure to leave the group if an error occurs
                        } else if let froopDocument = froopDocument, froopDocument.exists {
                            let froop = Froop(dictionary: froopDocument.data() ?? [:])
                            archivedList.append(froop)
                            group.leave()
                        } else {
                            PrintControl.shared.printErrorMessages("Froop document does not exist: \(data)")
                            
                            // Delete the document from myArchivedList if the corresponding Froop does not exist
                            docRef.document(document.documentID).delete { (error) in
                                if let error = error {
                                    PrintControl.shared.printErrorMessages("Error deleting document: \(error)")
                                } else {
                                    PrintControl.shared.printErrorMessages("Document deleted successfully.")
                                }
                            }
                            
                            group.leave()
                        }
                    }
                }
                
                group.notify(queue: .main) {
                    FroopDataController.shared.myArchivedList = archivedList
                    print("myArchivedList Updated")
                    FroopManager.shared.createFroopHistory() { froopHistoryCollection in
                        DispatchQueue.main.async {
                            FroopManager.shared.froopHistory = froopHistoryCollection
                            print("FroopHistory collection updated. Total count: \(FroopManager.shared.froopHistory.count)")
                        }
                    }
                    FroopDataController.shared.processPastEvents()
<<<<<<< HEAD
=======

>>>>>>> 170845f959ae66c5e6b49e018606b6ca8ef952cb
                }
            }
        }
        return listener
    }

}


