//
//  FroopDataController.swift
//  FroopProof
//
//  Created by David Reed on 3/25/23.
//

import Foundation
import FirebaseFirestoreSwift
import CoreLocation
import Firebase
import Combine
import SwiftUI
import UIKit
import FirebaseFirestore
import MessageUI
import FirebaseAuth
import MapKit

class FroopDataController: NSObject, ObservableObject, MFMessageComposeViewControllerDelegate {
    
    static let shared = FroopDataController()
    
    var db = FirebaseServices.shared.db
    @ObservedObject var myData = MyData.shared
    @ObservedObject var froopManager = FroopManager.shared
    @ObservedObject var notificationsManager = NotificationsManager.shared
    
    @Published var myInvitesList: [Froop] = []
    @Published var myConfirmedList: [Froop] = []
    @Published var myDeclinedList: [Froop] = []
    @Published var myArchivedList: [Froop] = []
    @Published var isLoading: Bool = false
    @Published var collectedFroops: [Froop] = []
    
    
    let timeZoneManager = TimeZoneManager()
    
    enum FroopListStatus {
        case invites, confirmed, declined, archived
    }
    
    private override init () {}
    
    var appStateManager: AppStateManager {
        return AppStateManager.shared
    }
    
    var printControl: PrintControl {
        return PrintControl.shared
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
    
    var locationManager: LocationManager {
        return LocationManager.shared
    }
    
    // The function is used to handle the result of sending SMS message
    func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
        PrintControl.shared.printFroopDataController("-function messageComposeViewController firing")
        
        switch result {
            case .cancelled:
                printControl.printErrorMessages("SMS message was cancelled")
            case .failed:
                printControl.printErrorMessages("SMS message failed")
            case .sent:
                printControl.printImage("SMS message was sent")
            @unknown default:
                printControl.printErrorMessages("Unknown error occurred while sending SMS message")
        }
        
        controller.dismiss(animated: true, completion: nil)
    }
    
    
    func deleteFroop(froopId: String, froopHost: String, completion: @escaping (String) -> Void) {
        guard !froopId.isEmpty, !froopHost.isEmpty else {
            PrintControl.shared.printFroopDataController("Error: Function: deleteFroop: Froop ID or Froop Host cannot be empty")
            return
        }
        PrintControl.shared.printFroopDataController("-function deleteFroop firing")
        PrintControl.shared.printFroopDataController("Deleting froop...")
        
        let hostFroopDocRef = db.collection("users").document(froopHost).collection("myFroops").document(froopId)
        
        hostFroopDocRef.getDocument { (documentSnapshot, error) in
            PrintControl.shared.printFroopDataController("Checking for host froop document...")
            if let error = error {
                PrintControl.shared.printFroopDataController("Error getting host froop document: \(error)")
                return
            }
            
            guard let document = documentSnapshot, document.exists else {
                PrintControl.shared.printFroopDataController("Host froop document does not exist.")
                return
            }
            
            self.getGuestDeleteList(hostFroopDocRef: hostFroopDocRef, froopId: froopId, froopHost: froopHost)
        }
    }
    
    func getGuestDeleteList(hostFroopDocRef: DocumentReference, froopId: String, froopHost: String) {
        var guestDelete: [String] = []
        PrintControl.shared.printFroopDataController("Getting guest delete list...")
        
        let hostInviteFriendsRef = hostFroopDocRef.collection("invitedFriends")
        let hostConfirmedListRef = hostInviteFriendsRef.document("confirmedList")
        let hostDeclinedListRef = hostInviteFriendsRef.document("declinedList")
        let hostInviteListRef = hostInviteFriendsRef.document("inviteList")
        
        hostInviteFriendsRef.getDocuments { (querySnapshot, error) in
            PrintControl.shared.printFroopDataController("Checking for invite friends documents...")
            if let error = error {
                PrintControl.shared.printFroopDataController("Error getting invite friends documents: \(error)")
                return
            }
            
            guard let documents = querySnapshot?.documents else {
                PrintControl.shared.printFroopDataController("Invite friends documents do not exist.")
                return
            }
            
            for document in documents {
                if let uidArray = document.data()["uid"] as? [String] {
                    guestDelete += uidArray
                }
            }
            
            // Get uid arrays from confirmed, declined, and invite lists
            let listRefs = [hostConfirmedListRef, hostDeclinedListRef, hostInviteListRef]
            let listNames = ["confirmed list", "declined list", "invite list"]
            
            for (index, listRef) in listRefs.enumerated() {
                listRef.getDocument { (documentSnapshot, error) in
                    PrintControl.shared.printFroopDataController("Checking for \(listNames[index]) document...")
                    if let error = error {
                        PrintControl.shared.printFroopDataController("Error getting \(listNames[index]) document: \(error)")
                        return
                    }
                    
                    if let uidArray = documentSnapshot?.data()?["uid"] as? [String] {
                        guestDelete += uidArray
                    }
                    
                    // If this is the last list, proceed to delete documents in guests' froopLists collections
                    if index == listRefs.count - 1 {
                        self.deleteDocumentsInGuestsFroopLists(guestDelete: guestDelete, froopId: froopId, froopHost: froopHost)
                    }
                }
            }
        }
    }
    
    func deleteDocumentsInGuestsFroopLists(guestDelete: [String], froopId: String, froopHost: String) {
        for uid in guestDelete {
            let guestRef = self.db.collection("users").document(uid).collection("froopDecisions").document("froopLists")
            
            deleteDocumentsInCollection(collectionRef: guestRef.collection("myInvitesList"), froopId: froopId, collectionName: "myInvitesList")
            deleteDocumentsInCollection(collectionRef: guestRef.collection("myConfirmedList"), froopId: froopId, collectionName: "myConfirmedList")
            deleteDocumentsInCollection(collectionRef: guestRef.collection("myDeclinedList"), froopId: froopId, collectionName: "myDeclinedList")
            deleteDocumentsInCollection(collectionRef: guestRef.collection("myArchivedList"), froopId: froopId, collectionName: "myArchivedList")
        }
        
        deleteFroopIdFromHostUserLists(froopId: froopId, froopHost: froopHost)
    }

    func deleteDocumentsInCollection(collectionRef: CollectionReference, froopId: String, collectionName: String) {
        collectionRef.whereField("froopId", isEqualTo: froopId).getDocuments { (querySnapshot, error) in
            PrintControl.shared.printFroopDataController("Deleting \(collectionName) document...")
            if let error = error {
                PrintControl.shared.printFroopDataController("Error deleting \(collectionName) document: \(error)")
                return
            }
            
            guard let documents = querySnapshot?.documents else {
                PrintControl.shared.printFroopDataController("\(collectionName) documents do not exist.")
                return
            }
            
            for document in documents {
                document.reference.delete()
            }
        }
    }

    func deleteFroopIdFromHostUserLists(froopId: String, froopHost: String) {
        let froopListsRef = self.db.collection("users").document(froopHost).collection("froopDecisions").document("froopLists")
        
        deleteFroopIdFromCollection(collectionRef: froopListsRef.collection("myConfirmedList"), froopId: froopId, collectionName: "myConfirmedList")
        deleteFroopIdFromCollection(collectionRef: froopListsRef.collection("myInvitesList"), froopId: froopId, collectionName: "myInvitesList")
        deleteFroopIdFromCollection(collectionRef: froopListsRef.collection("myDeclinedList"), froopId: froopId, collectionName: "myDeclinedList")
        deleteFroopIdFromCollection(collectionRef: froopListsRef.collection("myArchivedList"), froopId: froopId, collectionName: "myArchivedList")
        
        deleteHostFroopDocument(froopId: froopId, froopHost: froopHost)
    }

    func deleteFroopIdFromCollection(collectionRef: CollectionReference, froopId: String, collectionName: String) {
        collectionRef.whereField("froopId", isEqualTo: froopId).getDocuments { (querySnapshot, error) in
            PrintControl.shared.printFroopDataController("Deleting froopId from host user's \(collectionName)...")
            if let error = error {
                PrintControl.shared.printFroopDataController("Error deleting froopId from host user's \(collectionName): \(error)")
                return
            }
            
            guard let documents = querySnapshot?.documents else {
                PrintControl.shared.printFroopDataController("Documents in host user's \(collectionName) do not exist.")
                return
            }
            
            for document in documents {
                document.reference.delete()
            }
        }
    }

    func deleteHostFroopDocument(froopId: String, froopHost: String) {
        let hostFroopDocRef = db.collection("users").document(froopHost).collection("myFroops").document(froopId)
        
        hostFroopDocRef.collection("invitedFriends").document("confirmedList").delete { error in
            if let error = error {
                PrintControl.shared.printFroopDataController("Error deleting confirmedList document: \(error)")
                return
            }
            
            PrintControl.shared.printFroopDataController("Deleted confirmedList document.")
            
            hostFroopDocRef.collection("invitedFriends").document("declinedList").delete { error in
                if let error = error {
                    PrintControl.shared.printFroopDataController("Error deleting declinedList document: \(error)")
                    return
                }
                
                PrintControl.shared.printFroopDataController("Deleted declinedList document.")
                
                hostFroopDocRef.collection("invitedFriends").document("inviteList").delete { error in
                    if let error = error {
                        PrintControl.shared.printFroopDataController("Error deleting inviteList document: \(error)")
                        return
                    }
                    
                    PrintControl.shared.printFroopDataController("Deleted inviteList document.")
                    
                    hostFroopDocRef.delete { error in
                        if let error = error {
                            PrintControl.shared.printFroopDataController("Error deleting host froop document: \(error)")
                            return
                        }
                        
                        PrintControl.shared.printFroopDataController("Deleted host froop document.")
                    }
                }
            }
        }
    }
    
    func moveFroopInvitation(uid: String, froopId: String, froopHost: String, decision: String) {
        guard !uid.isEmpty, !froopId.isEmpty, !froopHost.isEmpty else {
            PrintControl.shared.printFroopDataController("Error: Function: moveFroopInvitation: UID, Froop ID, or Froop Host cannot be empty")
            return
        }
        PrintControl.shared.printFroopDataController("-function moveFroopInvitation firing")
        PrintControl.shared.printFroopDataController("UID: \(uid), Froop ID: \(froopId), Froop Host: \(froopHost), Decision: \(decision)")
        
        
        // References
        let userDocRef = db.collection("users").document(uid).collection("froopDecisions").document("froopLists")
        let froopCollectionRef = db.collection("users").document(froopHost).collection("myFroops").document(froopId)
        
        // Move the document in the myInvitesList to the correct location
        let sourceCollection: String
        let destinationCollection: String
        
        switch decision {
            case "accept":
                sourceCollection = "myInvitesList"
                destinationCollection = "myConfirmedList"
//                if let makeCount = notificationsManager.badgeCounts[.make], makeCount > 0 {
//                    notificationsManager.badgeCounts[.make] = makeCount - 1
//                }
            case "decline":
                sourceCollection = "myInvitesList"
                destinationCollection = "myDeclinedList"
//                if let makeCount = notificationsManager.badgeCounts[.make], makeCount > 0 {
//                    notificationsManager.badgeCounts[.make] = makeCount - 1
//                }
            default:
                print("Invalid decision")
                return
        }

        
        // Find the document in the source collection
        userDocRef.collection(sourceCollection).whereField("froopId", isEqualTo: froopId).getDocuments { (querySnapshot, error) in
            if let error = error {
                PrintControl.shared.printFroopDataController("Error getting documents: \(error)")
            } else if let document = querySnapshot?.documents.first {
                let sourceDocRef = userDocRef.collection(sourceCollection).document(document.documentID)
                let destinationDocRef = userDocRef.collection(destinationCollection).document(froopId)
                
                // Run a batch operation to ensure atomicity
                let batch = self.db.batch()
                
                // Move the document from source to destination
                batch.deleteDocument(sourceDocRef)
                batch.setData([
                    "froopId": froopId,
                    "froopHost": froopHost
                ], forDocument: destinationDocRef)
                
                // Update the froop's inviteList
                let inviteListDocRef = froopCollectionRef.collection("invitedFriends").document("inviteList")
                let confirmedListDocRef = froopCollectionRef.collection("invitedFriends").document("confirmedList")
                let declinedListDocRef = froopCollectionRef.collection("invitedFriends").document("declinedList")
                
                batch.setData(["uid": FieldValue.arrayRemove([uid])], forDocument: inviteListDocRef, merge: true)
                
                if decision == "accept" {
                    batch.setData(["uid": FieldValue.arrayUnion([uid])], forDocument: confirmedListDocRef, merge: true)
                } else {
                    batch.setData(["uid": FieldValue.arrayUnion([uid])], forDocument: declinedListDocRef, merge: true)
                }
                
                // Commit the batch
                batch.commit { error in
                    if let error = error {
                        PrintControl.shared.printFroopDataController("Error updating froop invitation: \(error)")
                    } else {
                        PrintControl.shared.printFroopDataController("Froop invitation successfully updated")
                    }
                }
            }
        }
    }
    
    func loadFroopLists(forUserWithUID uid: String, completion: @escaping () -> Void) {
        guard !uid.isEmpty else {
            printControl.printErrorMessages("Function: loadFroopLists: UID cannot be empty")
            completion()
            return
        }
        printControl.printFroopDataController("-Function loadFroopLists firing for user with UID: \(uid)")
        
        let dispatchGroup = DispatchGroup()
        
        // Block to fetch froops based on the status
        let fetchFroops = { (status: FroopListStatus) in
            dispatchGroup.enter()
            self.getCollectedFroops(forUserWithUID: uid, status: status) { (froops, error) in
                if let error = error {
                    self.printControl.printErrorMessages("Error getting \(status) froops: \(error.localizedDescription)")
                } else {
                    switch status {
                    case .invites: self.myInvitesList = froops ?? []
                    case .confirmed: self.myConfirmedList = froops ?? []
                    case .declined: self.myDeclinedList = froops ?? []
                    case .archived: self.myArchivedList = froops ?? []
                    }
                }
                dispatchGroup.leave()
            }
        }
        
        // Load all the froop lists
        fetchFroops(.invites)
        fetchFroops(.confirmed)
        fetchFroops(.declined)
        fetchFroops(.archived)
        
        dispatchGroup.notify(queue: .main) {
            PrintControl.shared.printFroopDataController("Finished loading froop lists")
            PrintControl.shared.printFroopDataController("Number of Froops in myInvitesList: \(self.myInvitesList.count)")
            PrintControl.shared.printFroopDataController("Number of Froops in myConfirmedList: \(self.myConfirmedList.count)")
            PrintControl.shared.printFroopDataController("Number of Froops in myDeclinedList: \(self.myDeclinedList.count)")
            PrintControl.shared.printFroopDataController("Number of Froops in myArchivedList: \(self.myArchivedList.count)")
            completion()
        }
    }
    
    func getCollectedFroops(forUserWithUID uid: String, status: FroopListStatus, completion: @escaping ([Froop]?, Error?) -> Void) {
        guard !uid.isEmpty else {
            PrintControl.shared.printFroopDataController("Error: Function: getCollectedFroops: UID cannot be empty")
            PrintControl.shared.printFroopDataController("getCollectedFroops: UID = \(uid)")
            completion(nil, nil)
            return
        }
        PrintControl.shared.printFroopDataController("-function getCollectedFroops firing")
        let collectionName: String
        
        switch status {
            case .invites:
                collectionName = "myInvitesList"
            case .confirmed:
                collectionName = "myConfirmedList"
            case .declined:
                collectionName = "myDeclinedList"
            case .archived:
                collectionName = "myArchivedList"
        }
        
        let dispatchGroup = DispatchGroup()
        var collectedFroops: [Froop] = []
        
        db.collection("users").document(uid).collection("froopDecisions").document("froopLists").collection(collectionName).getDocuments { (querySnapshot, error) in
            if let error = error {
                completion([], error)
            } else {
                if let querySnapshot = querySnapshot {
                    for document in querySnapshot.documents {
                        if let froopId = document.get("froopId") as? String,
                           let froopHost = document.get("froopHost") as? String {
                            if froopId.isEmpty {
                                print("Document found with empty froopId property")
                                Crashlytics.crashlytics().record(error: NSError(domain: "FroopDataController", code: 1, userInfo: [NSLocalizedDescriptionKey: "Document found with empty froopId property"]))
                                continue
                            }
                            if froopHost.isEmpty {
                                print("Document found with empty froopHost property")
                                Crashlytics.crashlytics().record(error: NSError(domain: "FroopDataController", code: 2, userInfo: [NSLocalizedDescriptionKey: "Document found with empty froopHost property"]))
                                continue
                            }
                            dispatchGroup.enter()
                            self.db.collection("users").document(froopHost).collection("myFroops").document(froopId).getDocument { (froopDocument, error) in
                                if let froopDocument = froopDocument, let froopData = froopDocument.data() {
                                    let froop = Froop(dictionary: froopData)
                                    collectedFroops.append(froop)
                                }
                                dispatchGroup.leave()
                            }
                        } else {
                            PrintControl.shared.printFroopDataController("Skipping placeholder document")
                        }
                    }
                }
                
                dispatchGroup.notify(queue: .main) {
                    completion(collectedFroops, nil)
                }
            }
        }
    }
    
    func fetchUserDocumentNames(listType: String, completion: @escaping ([String]?, Error?) -> Void) {
        PrintControl.shared.printFroopDataController("-function fetchUserDocumentNames firing")
        let uid = FirebaseServices.shared.uid
        
        guard ["myInvitesList", "myConfirmedList", "myDeclinedList"].contains(listType) else {
            PrintControl.shared.printFroopDataController("Invalid list type")
            completion(nil, nil)
            return
        }
        
        db.collection("users").document(uid).collection("froopDecisions").document("froopLists").collection(listType).getDocuments { (querySnapshot, error) in
            if let error = error {
                PrintControl.shared.printFroopDataController("Error fetching documents: \(error)")
                completion(nil, error)
            } else {
                if let querySnapshot = querySnapshot {
                    let documentNames = querySnapshot.documents.map { $0.documentID }
                    PrintControl.shared.printFroopDataController("User document names: \(documentNames)")
                    completion(documentNames, nil)
                } else {
                    PrintControl.shared.printFroopDataController("Error: querySnapshot is nil")
                    completion(nil, nil)
                }
            }
        }
    }
    
    func getFroopDataForDoc(listType: String, name: String, completion: @escaping ([String: Any]?, Error?) -> Void) {
        let uid = MyData.shared.froopUserID
        
        guard !uid.isEmpty, !name.isEmpty else {
            PrintControl.shared.printFroopDataController("Error: Function: getFroopDataForDoc:uid or name cannot be empty")
            completion(nil, nil)
            return
        }
        PrintControl.shared.printFroopDataController("-function getFroopDataForDoc firing")
        
        guard ["myInvitesList", "myConfirmedList", "myDeclinedList"].contains(listType) else {
            PrintControl.shared.printFroopDataController("Invalid list type")
            completion(nil, nil)
            return
        }
        
        let froopListsRef = db.collection("users").document(uid).collection("froopDecisions").document("froopLists")
        let collectionName = froopListsRef.collection(listType)
        
        collectionName.document(name).getDocument { (document, error) in
            if let error = error {
                PrintControl.shared.printFroopDataController("Error getting froop data: \(error.localizedDescription)")
                completion(nil, error)
            } else if let document = document, document.exists {
                let froopData = document.data()
                completion(froopData, nil)
            } else {
                completion(nil, nil)
            }
        }
    }
    
    
    func addInvitedFriendstoFroop(invitedFriends: [UserData], selectedFroopUUID: String, instanceFroop: Froop) async throws -> [UserData] {
        let uid = FirebaseServices.shared.uid
        
        let userRef = db.collection("users").document(uid)
        
        let invitedFriendsRef = userRef.collection("myFroops").document(selectedFroopUUID).collection("invitedFriends")
        
        let inviteListRef = invitedFriendsRef.document("inviteList")
        let confirmedListRef = invitedFriendsRef.document("confirmedList")
        let declinedListRef = invitedFriendsRef.document("declinedList")
        
//        let invitedListCollectionRef = froopListRef.collection("myInvitedList")
//        let confirmedListCollectionRef = froopListRef.collection("myConfirmedList")
//        let declinedListCollectionRef = froopListRef.collection("myDeclinedList")

        // Extract the UIDs from the invitedFriends array
        let invitedFriendUIDs = invitedFriends.map { $0.froopUserID }

        // Remove friends that are not in the invitedFriendUIDs list
        let modifiedInvitedFriends = invitedFriends.filter { invitedFriendUIDs.contains($0.froopUserID) }

        // Process each invited friend
        for invitedFriend in modifiedInvitedFriends {
            let invitedGuestRef = db.collection("users").document(invitedFriend.froopUserID).collection("froopDecisions").document("froopLists")

            // Check if the document with the given froopId name exists in any of the Guest's lists of myInvitesList, myConfirmedLists, or myDeclinedLists.
            let froopIdExistsInInvitesList = try await checkIfFroopIdExists(in: invitedGuestRef.collection("myInvitesList"), froopId: selectedFroopUUID)
                   let froopIdExistsInConfirmedList = try await checkIfFroopIdExists(in: invitedGuestRef.collection("myConfirmedList"), froopId: selectedFroopUUID)
                   let froopIdExistsInDeclinedList = try await checkIfFroopIdExists(in: invitedGuestRef.collection("myDeclinedList"), froopId: selectedFroopUUID)

                   if froopIdExistsInInvitesList {
                       // Make sure that user's UID is in the corresponding array inside the document under .collection("myFroops").document(froopId).collection("invitedFriends") in .document("inviteList").uid[]
                       try await confirmGuestUIDInList(in: inviteListRef, guestUID: invitedFriend.froopUserID)
                   } else if froopIdExistsInConfirmedList {
                       // Make sure that user's UID is in the corresponding array inside the document under .collection("myFroops").document(froopId).collection("invitedFriends") in .document("confirmedList").uid[]
                       try await confirmGuestUIDInList(in: confirmedListRef, guestUID: invitedFriend.froopUserID)
                   } else if froopIdExistsInDeclinedList {
                       // Make sure that user's UID is in the corresponding array inside the document under .collection("myFroops").document(froopId).collection("invitedFriends") in .document("declinedList").uid[]
                       try await confirmGuestUIDInList(in: declinedListRef, guestUID: invitedFriend.froopUserID)
                   } else {
                       // If the given froopId is not found in the guest's Lists, then...
                       // Add the invitation document to the guest's myInvitationsList
                       try await addFroopToInvitesList(in: invitedGuestRef.collection("myInvitesList"), froopHost: instanceFroop.froopHost, froopId: selectedFroopUUID)

                       // Add the guest's UID inside invitesList.
                       try await addInvitedGuestUIDToInviteList(in: inviteListRef, newInvitedFriendUIDs: [invitedFriend.froopUserID])
                   }
               }
        return modifiedInvitedFriends
    }

    private func checkIfFroopIdExists(in collectionRef: CollectionReference, froopId: String) async throws -> Bool {
        let querySnapshot = try await collectionRef.whereField("froopId", isEqualTo: froopId).getDocuments()
        return !querySnapshot.documents.isEmpty
    }

    private func addFroopToInvitesList(in collectionRef: CollectionReference, froopHost: String, froopId: String) async throws {
        let documentId = UUID().uuidString
        try await collectionRef.document(documentId).setData([
            "froopHost": froopHost,
            "froopId": froopId,
            "documentID": documentId
        ])
    }

    private func confirmGuestUIDInList(in documentRef: DocumentReference, guestUID: String) async throws {
        let documentSnapshot = try await documentRef.getDocument()
        if documentSnapshot.exists {
            if var uidArray = documentSnapshot.data()?["uid"] as? [String], !uidArray.contains(guestUID) {
                uidArray.append(guestUID)
                try await documentRef.updateData(["uid": uidArray])
            }
        } else {
            // Document doesn't exist, create it
            try await documentRef.setData(["uid": [guestUID]])
        }
    }

    private func addInvitedGuestUIDToInviteList(in documentRef: DocumentReference, newInvitedFriendUIDs: [String]) async throws {
        let documentSnapshot = try await documentRef.getDocument()
        if documentSnapshot.exists {
            try await documentRef.updateData([
                "uid": FieldValue.arrayUnion(newInvitedFriendUIDs)
            ])
        } else {
            // Document doesn't exist, create it
            try await documentRef.setData(["uid": newInvitedFriendUIDs])
        }
    }
    
    func processPastEvents() {
        
        
        PrintControl.shared.printFroopDataController("-function processPastEvents firing")
        
        
        let uid = FirebaseServices.shared.uid
        let userRef = db.collection("users").document(uid)
        let froopListRef = userRef.collection("froopDecisions").document("froopLists")
        let confirmedListCollectionRef = froopListRef.collection("myConfirmedList")
        let archivedListCollectionRef = froopListRef.collection("myArchivedList")
        let inviteListCollectionRef = froopListRef.collection("myInvitesList")
        
        let currentTime = Date()
        PrintControl.shared.printFroopDataController("CurrentTime in ProcessPastEvents \(currentTime)")
        let currentTimeUTC = timeZoneManager.convertDateToUTC(date: currentTime, oTZ: TimeZone.current)
        PrintControl.shared.printFroopDataController("CurrentTimeUTC in ProcessPastEvents \(currentTimeUTC)")
        PrintControl.shared.printFroopDataController("######## 0. Current Time (UTC): \(currentTime)")
        PrintControl.shared.printFroopDataController("######## 0.1 Current Time: \(currentTime)")
        
        //Process myConfirmedList
        PrintControl.shared.printFroopDataController("######## 1. Processing myConfirmedList")
        confirmedListCollectionRef.getDocuments { (querySnapshot, error) in
            guard let documents = querySnapshot?.documents else {
                PrintControl.shared.printFroopDataController("Error fetching documents: \(String(describing: error))")
                return
            }
            PrintControl.shared.printFroopDataController("########2. Fetched documents successfully: \(documents.count) documents found")
            for document in documents {
                //                print("######## 3. Looping through document: \(document.documentID)")
                let froopId = document.data()["froopId"] as? String ?? ""
                let froopHost = document.data()["froopHost"] as? String ?? ""
                
                if froopId.isEmpty || froopHost.isEmpty {
                    PrintControl.shared.printFroopDataController("Skipping empty froopId or froopHost in confirmedListCollection")
                    continue
                }
                
                PrintControl.shared.printFroopDataController("######## 4. Fetching froop document")
                self.db.collection("users").document(froopHost).collection("myFroops").document(froopId).getDocument { (froopDocument, error) in
                    if let error = error {
                        PrintControl.shared.printFroopDataController("Error fetching Froop data: \(error.localizedDescription)")
                    } else if let froopDocument = froopDocument, froopDocument.exists, let froopData = froopDocument.data() {
                        let froop = Froop(dictionary: froopData)
                        let endTimeUTC = froop.froopEndTime
                        
                        let endTime = endTimeUTC  // Updated line
                        PrintControl.shared.printFroopDataController("######## 4.1 Froop Start Time: \(String(describing: froop.froopStartTime))")
                        PrintControl.shared.printFroopDataController("######## 4.2 Froop End Time: \(String(describing: endTime))")
                        PrintControl.shared.printFroopDataController("######## 4.3 Froop Duration: \( String(describing: froop.froopDuration))") 
                        
                        
                        if endTime.addingTimeInterval(30 * 60) < currentTime {
                            PrintControl.shared.printFroopDataController("######## 5. Moving Froop \(froopId) to myArchivedList")
                            let sourceRef = confirmedListCollectionRef.document(document.documentID) // Use document.documentID instead of froopId
                            let destinationRef = archivedListCollectionRef.document(document.documentID)
                            self.moveDocument(sourceRef: sourceRef, destinationRef: destinationRef)
                        } else {
                            PrintControl.shared.printFroopDataController("######## 5.1 Froop \(froopId) is still active")
                        }
                        
                    }
                }
            }
        }
        
        PrintControl.shared.printFroopDataController("######## 6. Processing myInvitesList")
        inviteListCollectionRef.getDocuments { (querySnapshot, error) in
            guard let documents = querySnapshot?.documents else {
                PrintControl.shared.printFroopDataController("Error fetching documents: \(String(describing: error))")
                return
            }
            PrintControl.shared.printFroopDataController("######## 7. Fetched documents successfully: \(documents.count) documents found")
            for document in documents {
                PrintControl.shared.printFroopDataController("######## 8. Looping through document: \(document.documentID)")
                let froopId = document.data()["froopId"] as? String ?? ""
                let froopHost = document.data()["froopHost"] as? String ?? ""
                
                if document.documentID == "placeholder" {
                    PrintControl.shared.printFroopDataController("Skipping placeholder document in inviteListCollection")
                    continue
                }
                
                
                if froopId.isEmpty || froopHost.isEmpty {
                    PrintControl.shared.printFroopDataController("Skipping empty froopId or froopHost in inviteListCollection")
                    continue
                }
                
                PrintControl.shared.printFroopDataController("######## 9. Fetching froop document")
                self.db.collection("users").document(froopHost).collection("myFroops").document(froopId).getDocument { (froopDocument, error) in
                    if let error = error {
                        PrintControl.shared.printFroopDataController("Error fetching Froop data: \(error.localizedDescription)")
                    } else if let froopDocument = froopDocument, froopDocument.exists, let froopData = froopDocument.data() {
                        let froop = Froop(dictionary: froopData)
                        let endTimeUTC = froop.froopEndTime
                        let endTime = endTimeUTC
                        
                        if endTime < currentTime {
                            PrintControl.shared.printFroopDataController("######## 10. Deleting expired Froop (\(froopId)) from myInvitesList")
                            let sourceRef = inviteListCollectionRef.document(document.documentID) // Use document.documentID instead of froopId
                            let destinationRef = archivedListCollectionRef.document(document.documentID)
                            self.moveDocument(sourceRef: sourceRef, destinationRef: destinationRef)
                        } else {
                            PrintControl.shared.printFroopDataController("Froop (\(froopId)) in myInvitesList is still active")
                        }
                    } else {
                        PrintControl.shared.printFroopDataController("Froop document does not exist or has been deleted")
                    }
                }
            }
        }
    }
    
    func moveDocument(sourceRef: DocumentReference, destinationRef: DocumentReference) {
        PrintControl.shared.printFroopDataController("-function moveDocument firing")
        sourceRef.getDocument { (document, error) in
            if let error = error {
                // Log the error and prevent further operations.
                print("Error getting document: \(error)")
            } else if let document = document, document.exists, let data = document.data() {
                destinationRef.setData(data) { error in
                    if let error = error {
                        PrintControl.shared.printFroopDataController("Error writing document to destination collection: \(error.localizedDescription)")
                    } else {
                        sourceRef.delete() { error in
                            if let error = error {
                                PrintControl.shared.printFroopDataController("Error removing document from source collection: \(error.localizedDescription)")
                            } else {
                                PrintControl.shared.printFroopDataController("Document successfully moved from source to destination collection!")
                            }
                        }
                    }
                }
            } else {
                PrintControl.shared.printFroopDataController("Error fetching document: \(error?.localizedDescription ?? "Document does not exist")")
            }
        }
    }
}





