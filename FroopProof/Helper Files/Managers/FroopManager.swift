//
//  FroopManager.swift
//  FroopProof
//
//  Created by David Reed on 4/15/23.
//

import Foundation
import Firebase
import FirebaseAuth
import FirebaseStorage
import FirebaseFirestore
import SwiftUI
import UIKit
import Combine
import MapKit
import Kingfisher

class FroopManager: ObservableObject {
    static let shared = FroopManager()
    
    @ObservedObject var printControl = PrintControl.shared
    @ObservedObject var froopDataListener = FroopDataListener.shared
    @Published var comeFrom = false
    @Published var selectedFroopUUID: String = ""
    @Published var selectedHost: UserData = UserData()
    @Published var invitedFriends: [UserData] = []
    @Published var confirmedFriends: [UserData] = []
    @Published var declinedFriends: [UserData] = []
    @Published var selectedFroop: Froop = Froop(dictionary: [:]) {
        didSet {
            let froop = selectedFroop
            startListeningForFroopUpdates(froopId: froop.froopId, froopHost: froop.froopHost)
        }
    }
    @Published var froopsAndHosts: [FroopAndHost] = []
    @Published var froopDropPins: [FroopDropPin] = []
    @Published var froopHistory: [FroopHistory] = []
    @Published var froopHistoryCollection: [FroopHistory] = []
    @Published var isFroopFetchingComplete = false
    @Published var froopFeed: [FroopHostAndFriends] = []
    @Published var myFroopFeed: [FroopHostAndFriends] = []
    @Published var myData = MyData.shared
    @Published var activeFroops: [Froop] = []
    @Published var userFriends: [UserData] = []
    @Published var froopMapOpen: Bool = false
    @Published var froopDetailOpen: Bool = false
    @Published var addFriendsOpen: Bool = false
    @Published var friendDetailOpen: Bool = false
    @Published var inviteExternalFriendsOpen: Bool = false
    @Published var froopHistoryFroop: Froop = Froop(dictionary: [:])
    @Published var froopHistoryHost: UserData = UserData()
    @Published var showData = false
    @Published var showChatView = false
    @Published var froopTemplates: [Froop] = []
    @Published var myUserData: UserData = UserData()
    @Published var areAllCardsExpanded: Bool = true
    @Published var hostedFroopCount: Int = 0
    
    
    var getHostedFroopCount: [FroopHistory] {
        return froopHistory.filter { $0.froop.froopHost == uid }
    }
    
    var invitedListener: ListenerRegistration?
    var confirmedListener: ListenerRegistration?
    var declinedListener: ListenerRegistration?
    var froopListener: ListenerRegistration?
    var templateStoreListener: ListenerRegistration?
    
    var db = FirebaseServices.shared.db
    let uid = FirebaseServices.shared.uid
    private let notificationCenter = FroopNotificationCenter()
    
    init() {
       
        fetchUserData(for: uid) { result in
            switch result {
            case .success(let myUserData):
                self.myUserData = myUserData
                    print("-------> Self.myUserData:  \(self.myUserData.firstName)")
                    print("-------> myUserData:  \(myUserData.firstName)")

            case .failure(let error):
                print("Error fetching user data: \(error.localizedDescription)")
            }
        }
        setupTemplateStoreListener()
        getHostedFroopCountTotal()
    }
    
    func getHostedFroopCountTotal() {
        let filteredFroops = froopHistory.filter { $0.froop.froopHost == uid }
        hostedFroopCount = filteredFroops.count
    }
    
    func fetchFroopData(fuid: String) {
        fetchAttendedFroops(for: fuid) { result in
            switch result {
            case .success(let fetchedFroops):
                self.combineFroopAndHostWithFriends(froopAndHostArray: fetchedFroops) { combinedResult in
                    DispatchQueue.main.async {
                        switch combinedResult {
                            case .success(let froopHostAndFriendsArray):
                                self.froopFeed = froopHostAndFriendsArray
                                self.preloadImages()
                                self.isFroopFetchingComplete = true
                            case .failure(let error):
                                print("Failed to combine Froop and Host with Friends: \(error)")
                                // Handle error accordingly
                        }
                    }
                }
            case .failure(let error):
                print("Failed to fetch attended Froops: \(error)")
            }
        }
    }
    
    func fetchUserData(for uid: String, completion: @escaping (Result<UserData, Error>) -> Void) {
        let usersRef = db.collection("users").document(uid)
        usersRef.getDocument { document, error in
            if let document = document, document.exists, let data = document.data() {
                if let user = UserData(dictionary: data) {
                    completion(.success(user))
                } else {
                    completion(.failure(NSError(domain: "FroopManager", code: 1001, userInfo: [NSLocalizedDescriptionKey: "Error initializing UserData from document data."])))
                }
            } else if let error = error {
                completion(.failure(error))
            }
        }
    }
    
    func fetchAttendedFroops(for uid: String, completion: @escaping (Result<[FroopAndHost], Error>) -> Void) {
        let archivedFroopsRef = db.collection("users").document(uid).collection("myDecisions").document("froopLists").collection("myArchivedList")
        
        var froopsAndHosts: [FroopAndHost] = []
        
        archivedFroopsRef.getDocuments() { (querySnapshot, err) in
            if let err = err {
                print("Error fetching archived Froops: \(err.localizedDescription)")
                completion(.failure(err))
                return
            }
            
            guard let documents = querySnapshot?.documents else {
                print("No documents found in archived Froops.")
                completion(.failure(NSError(domain: "FroopError", code: -1, userInfo: [NSLocalizedDescriptionKey: "No documents found in archived Froops."])))
                return
            }

            let dispatchGroup = DispatchGroup()
            
            for document in documents {
                let data = document.data()
                
                if let froopHostUid = data["froopHost"] as? String, let froopId = data["froopId"] as? String {
                    dispatchGroup.enter()
                    
                    self.fetchUserData(for: froopHostUid) { (userResult: Result<UserData, Error>) in
                        switch userResult {
                        case .success(let froopHost):
                            print("Successfully fetched user data for \(froopHostUid)")
                            
                            self.fetchFroopData(froopId: froopId, froopHost: froopHostUid) { (froop) in
                                if let froop = froop {
                                    print("Successfully fetched froop with ID \(froopId)")
                                    // Create FroopAndHost instance and append to an array
                                    let froopAndHost = FroopAndHost(froop: froop, host: froopHost)
                                    print("Created FroopAndHost object with froop ID: \(froopId) and host UID: \(froopHostUid)")
                                    froopsAndHosts.append(froopAndHost)
                                } else {
                                    print("Failed to fetch froop with ID \(froopId)")
                                }
                                dispatchGroup.leave()
                            }
                        case .failure(let error):
                            print("Error fetching user data for froopHost: \(error)")
                            dispatchGroup.leave()
                        }
                    }
                } else {
                    print("Data missing in document: \(document.documentID). Cannot fetch froopHost or froopId.")
                }
            }
            
            dispatchGroup.notify(queue: .main) {
                print("All async operations completed. Returning \(froopsAndHosts.count) FroopAndHost objects.")
                completion(.success(froopsAndHosts))
            }
        }
    }

    
    func checkAndUpdateTemplateStore(completion: @escaping (Error?) -> Void) {
        let userDocumentRef = db.collection("users").document(uid)
        let froopDocumentRef = userDocumentRef.collection("myFroops").document(selectedFroop.froopId)
        let templatesCollectionRef = userDocumentRef.collection("templates")
        let templateStoreRef = templatesCollectionRef.document("templateStore")
        
        templateStoreRef.getDocument { (document, error) in
            if let error = error {
                completion(error)
            } else {
                // Check if the document exists.
                if let document = document, document.exists {
                    // The document exists. Get the array and check if it contains the froopId.
                    var templateIds = document.data()?["templateId"] as? [String] ?? []
                    if !templateIds.contains(self.selectedFroop.froopId) {
                        // The froopId is not in the array, so add it.
                        templateIds.append(self.selectedFroop.froopId)
                        templateStoreRef.updateData(["templateId": templateIds]) { error in
                            if let error = error {
                                completion(error)
                            } else {
                                // Now update the 'template' property of the froop document.
                                froopDocumentRef.updateData(["template": true], completion: completion)
                            }
                        }
                    }
                } else {
                    // The document does not exist, so create it with the froopId in the array.
                    templateStoreRef.setData(["templateId": [self.selectedFroop.froopId]]) { error in
                        if let error = error {
                            completion(error)
                        } else {
                            // Now update the 'template' property of the froop document.
                            froopDocumentRef.updateData(["template": true], completion: completion)
                        }
                    }
                }
            }
        }
    }
    
    func fetchFroopsFromIds(uid: String, templateStore: [String], completion: @escaping (Result<[Froop], Error>) -> Void) {
        let userFroopsCollectionRef = db.collection("users").document(uid).collection("myFroops")
        
        var froopsArray = [Froop]()
        let dispatchGroup = DispatchGroup()
        
        for froopId in templateStore {
            dispatchGroup.enter()
            
            userFroopsCollectionRef.document(froopId).getDocument { (document, error) in
                if let error = error {
                    completion(.failure(error))
                    return
                } else if let document = document, document.exists {
                    let data = document.data() ?? [:]
                    let froop = Froop(dictionary: data)
                    froopsArray.append(froop)
                }
                
                dispatchGroup.leave()
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            completion(.success(froopsArray))
        }
    }
    
    func setupTemplateStoreListener() {
        let userDocumentRef = db.collection("users").document(uid)
        let templatesCollectionRef = userDocumentRef.collection("templates")
        let templateStoreRef = templatesCollectionRef.document("templateStore")
        
        // Assigning the listener
        templateStoreListener = templateStoreRef.addSnapshotListener { documentSnapshot, error in
            guard let document = documentSnapshot else {
                print("Error fetching template store: \(error!)")
                return
            }
            
            // get the templateIds array from the document
            let templateIds = document.data()?["templateId"] as? [String] ?? []
            
            // Now fetch Froops for each of the ids
            self.fetchFroopsFromIds(uid: self.uid, templateStore: templateIds) { result in
                switch result {
                    case .success(let froops):
                        // Assign the fetched Froops to the froopTemplates array
                        DispatchQueue.main.async {
                            self.froopTemplates = froops
                        }
                    case .failure(let error):
                        print("Error fetching froops: \(error)")
                }
            }
        }
    }
    
    func preloadImages() {
        var urls: [URL] = []

        // Iterate through all FroopHostAndFriends objects
        for froopHostAndFriends in froopFeed {
            // Append all URLs in froop.froopImages to the urls array
            urls.append(contentsOf: froopHostAndFriends.FH.froop.froopImages.compactMap { URL(string: $0) })
            // Append all URLs in froop.froopDisplayImages to the urls array
            urls.append(contentsOf: froopHostAndFriends.FH.froop.froopDisplayImages.compactMap { URL(string: $0) })
            // Append all URLs in froop.froopThumbnailImages to the urls array
            urls.append(contentsOf: froopHostAndFriends.FH.froop.froopThumbnailImages.compactMap { URL(string: $0) })
        }

        // Create a ImagePrefetcher with the urls
        let prefetcher = ImagePrefetcher(urls: urls)

        // Start prefetching
        prefetcher.start()
    }
    
    func combineFroopAndHostWithFriends(froopAndHostArray: [FroopAndHost], completion: @escaping (Result<[FroopHostAndFriends], Error>) -> Void) {
        var froopHostAndFriendsArray: [FroopHostAndFriends] = []
        let dispatchGroup = DispatchGroup()
        
        for froopAndHost in froopAndHostArray {
            dispatchGroup.enter()
            fetchConfirmedFriendData(for: froopAndHost.froop) { result in
                switch result {
                    case .success(let friends):
                        let froopHostAndFriends = FroopHostAndFriends(FH: froopAndHost, friends: friends)
                        froopHostAndFriendsArray.append(froopHostAndFriends)
                    case .failure(let error):
                        print("Failed to fetch confirmed friend data: \(error)")
                }
                dispatchGroup.leave()
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            completion(.success(froopHostAndFriendsArray))
        }
    }
    
    func removeListeners() {
        print("removing frooplistener for \(selectedFroop.froopName)")
        froopListener?.remove()
        print("removing invitedList listener for \(selectedFroop.froopName)")
        invitedListener?.remove()
        print("removing confirmedList listener for \(selectedFroop.froopName)")
        confirmedListener?.remove()
        print("removing declinedList listener for \(selectedFroop.froopName)")
        declinedListener?.remove()
    }
    
    func initializeListenersForFroop(froopId: String) {
        self.startListeningForInvitedUpdates(froopId: froopId)
        print("initializing invitedList listener \(selectedFroop.froopName)")
        self.startListeningForConfirmedUpdates(froopId: froopId)
        print("initializing confirmedList listener \(selectedFroop.froopName)")
        self.startListeningForDeclinedUpdates(froopId: froopId)
        print("initializing declinedList listener \(selectedFroop.froopName)")
        self.startListeningForFroopUpdates(froopId: selectedFroop.froopId, froopHost: selectedFroop.froopHost)
        print("initializing selectedFroop listener \(selectedFroop.froopName)")
    }
    
    func startListeningForFroopUpdates(froopId: String, froopHost: String) {
        let db = Firestore.firestore()
        let froopDocumentRef = db.collection("users").document(froopHost).collection("myFroops").document(froopId)
        
        froopListener = froopDocumentRef.addSnapshotListener { documentSnapshot, error in
            guard let document = documentSnapshot else {
                print("Error fetching document: \(String(describing: error))")
                return
            }
            guard document.data() != nil else {
                print("Document data was empty.")
                return
            }
        }
        print("selectedFroop Listener \(selectedFroop.froopName) is listening")
    }
    
    func startListeningForInvitedUpdates(froopId: String) {
        let db = Firestore.firestore()
        let invitedDocumentRef = db.collection("users").document(selectedFroop.froopHost).collection("myFroops").document(froopId).collection("invitedFriends").document("inviteList")
        
        invitedListener = invitedDocumentRef.addSnapshotListener { [weak self] documentSnapshot, error in
            guard let document = documentSnapshot, document.exists, let self = self else {
                print("Error fetching invited document: \(String(describing: error))")
                return
            }
            
            let invitedFriendUIDs = document.data()?["uid"] as? [String] ?? []
            self.fetchUserDataFor(uids: invitedFriendUIDs, completion: { result in
                switch result {
                    case .success(let userData):
                        self.invitedFriends = userData
                    case .failure(let error):
                        print("Failed to fetch user data: \(error)")
                }
            })
        }
        print("inviteList Listener \(selectedFroop.froopName) is listening")
    }
    
    func startListeningForConfirmedUpdates(froopId: String) {
        let db = Firestore.firestore()
        let confirmedDocumentRef = db.collection("users").document(selectedFroop.froopHost).collection("myFroops").document(froopId).collection("invitedFriends").document("confirmedList")
        
        confirmedListener = confirmedDocumentRef.addSnapshotListener { [weak self] documentSnapshot, error in
            guard let document = documentSnapshot, document.exists, let self = self else {
                print("Error fetching confirmed document: \(String(describing: error))")
                return
            }
            
            let confirmedFriendUIDs = document.data()?["uid"] as? [String] ?? []
            self.fetchUserDataFor(uids: confirmedFriendUIDs, completion: { result in
                switch result {
                    case .success(let userData):
                        self.confirmedFriends = userData
                    case .failure(let error):
                        print("Failed to fetch user data: \(error)")
                }
            })
        }
        print("confirmedList Listener \(selectedFroop.froopName) is listening")
    }
    
    func startListeningForDeclinedUpdates(froopId: String) {
        let db = Firestore.firestore()
        let declinedDocumentRef = db.collection("users").document(selectedFroop.froopHost).collection("myFroops").document(froopId).collection("invitedFriends").document("declinedList")
        
        declinedListener = declinedDocumentRef.addSnapshotListener { [weak self] documentSnapshot, error in
            guard let document = documentSnapshot, document.exists, let self = self else {
                print("Error fetching declined document: \(String(describing: error))")
                return
            }
            
            let declinedFriendUIDs = document.data()?["uid"] as? [String] ?? []
            self.fetchUserDataFor(uids: declinedFriendUIDs, completion: { result in
                switch result {
                    case .success(let userData):
                        self.declinedFriends = userData
                    case .failure(let error):
                        print("Failed to fetch user data: \(error)")
                }
            })
        }
        print("declinedList Listener \(selectedFroop.froopName) is listening")
    }
    
    private func fetchUserDataFor(uids: [String], completion: @escaping (Result<[UserData], Error>) -> Void) {
        let dispatchGroup = DispatchGroup()
        var users: [UserData] = []
        
        for uid in uids {
            dispatchGroup.enter()
            AppStateManager.shared.getUserData(uid: uid) { result in
                switch result {
                    case .success(let userData):
                        users.append(userData)
                    case .failure(let error):
                        print("Failed to fetch user data: \(error)")
                }
                dispatchGroup.leave()
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            completion(.success(users))
        }
    }
    
    func printLocationData (froopLocation: CLLocationCoordinate2D, userLocation: CLLocationCoordinate2D) {
        print("Froop Location: \(String(describing: self.selectedFroop.froopLocationCoordinate))")
        print("User Location: \(String(describing: self.myData.coordinate))")
    }
    
    func fetchFroopData(froopId: String, froopHost: String, completion: @escaping (Froop?) -> Void) {
        
        let froopRef = db.collection("users").document(froopHost).collection("myFroops").document(froopId)
        
        froopRef.getDocument { (document, error) in
            if let error = error {
                print("Error fetching Froop data: \(error.localizedDescription)")
                completion(nil)
            } else {
                if let document = document, document.exists, let data = document.data() {
                    let froop = Froop(dictionary: data)
                    FroopManager.shared.selectedFroop = froop // Corrected line
                    completion(froop)
                } else {
                    print("Document does not exist 2")
                    completion(nil)
                }
            }
        }
    }
    
    func groupFroopHistoriesByMonth() -> [Month] {
        print("groupFroopHistoriesByMonth Function: Firing")
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM" // Month name format
        
        let groupedFroopHistories = Dictionary(grouping: froopHistoryCollection) { (froopHistory) -> String in
            return dateFormatter.string(from: froopHistory.froop.froopStartTime)
        }
        
        return groupedFroopHistories.map { (key, value) -> Month in
            let sortedFroopHistories = value.sorted { $0.froop.froopStartTime > $1.froop.froopStartTime }
            return Month(name: key, froopHistories: sortedFroopHistories)
        }.sorted { $0.name > $1.name }
    }
    
    func getUserFroops(uid: String, completion: @escaping (Result<[Froop], Error>) -> Void) {
        let froopsCollectionRef = db.collection("users").document(uid).collection("myFroops")
        
        froopsCollectionRef.getDocuments { (querySnapshot, error) in
            if let error = error {
                completion(.failure(error))
            } else if let querySnapshot = querySnapshot {
                var froopsArray = [Froop]()
                for document in querySnapshot.documents {
                    let data = document.data()
                    let froop = Froop(dictionary: data)
                    froopsArray.append(froop)
                }
                completion(.success(froopsArray))
            } else {
                let error = NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "No documents found in the collection"])
                completion(.failure(error))
            }
        }
    }
    
    func fetchFriendLists(uid: String, completion: @escaping ([String]) -> Void) {
        print("fetchFriendList: uid:  \(uid))")
        let friendsRef = db.collection("users").document(uid).collection("friends").document("friendList")
        
        friendsRef.getDocument { document, error in
            if let document = document, document.exists {
                var userFriendUIDs = document.data()?["friendUIDs"] as? [String] ?? []
                print("First Function: fetchFriendLists: \(userFriendUIDs.description)")
                
                // Append the current user's uid to the list
                let currentUserUID = FirebaseServices.shared.uid
                userFriendUIDs.append(currentUserUID)
                
                
                completion(userFriendUIDs)
            } else {
                completion([])
            }
        }
    }
    
    func createFroopHistory(completion: @escaping ([FroopHistory]) -> Void) {
        var froopHistoryCollection: [FroopHistory] = []

        // Combine items from myArchivedList, myInvitesList, and myConfirmedList
        let froops = FroopDataController.shared.myArchivedList + FroopDataController.shared.myInvitesList + FroopDataController.shared.myConfirmedList

        let dispatchGroup = DispatchGroup()

        for froop in froops {
            guard !froop.froopHost.isEmpty else {
                print("Skipping froop with empty host.")
                continue
            }

            dispatchGroup.enter()
            fetchConfirmedFriendData(for: froop) { result in
                switch result {
                    case .success(let friends):
                        AppStateManager.shared.getUserData(uid: froop.froopHost) { result in
                            switch result {
                                case .success(let hostData):
                                    let history = FroopHistory(froop: froop, host: hostData, friends: friends, images: froop.froopImages, videos: froop.froopVideos)
                                    froopHistoryCollection.append(history)
                                    // print("FroopHistory object created and added to the collection. Current count: \(froopHistoryCollection.count)")
                                case .failure(let error):
                                    print("Failed to fetch user data: \(error)")
                                    PrintControl.shared.printErrorMessages("Failed to fetch user data: \(error)")
                            }
                            dispatchGroup.leave()
                        }
                    case .failure(let error):
                        print("Failed to fetch confirmed friends: \(error)")
                        PrintControl.shared.printErrorMessages("Failed to fetch confirmed friends: \(error)")
                        dispatchGroup.leave()
                }
            }
        }

        dispatchGroup.notify(queue: .main) {
            self.froopHistoryCollection = froopHistoryCollection
            print("David asking: \(FroopManager.shared.froopHistoryCollection.count)")
            completion(froopHistoryCollection)
        }
    }
    
    func fetchConfirmedFriendData(for froop: Froop, completion: @escaping (Result<[UserData], Error>) -> Void) {
        fetchConfirmedFriends(for: froop) { result in
            switch result {
                case .success(let friendUIDs):
                    let dispatchGroup = DispatchGroup()
                    var friends: [UserData] = []
                    
                    for uid in friendUIDs {
                        dispatchGroup.enter()
                        AppStateManager.shared.getUserData(uid: uid) { result in
                            switch result {
                                case .success(let userData):
                                    friends.append(userData)
                                case .failure(let error):
                                    print("Failed to fetch user data: \(error)")
                            }
                            dispatchGroup.leave()
                        }
                    }
                    
                    dispatchGroup.notify(queue: .main) {
                        completion(.success(friends))
                    }
                    
                case .failure(let error):
                    completion(.failure(error))
            }
        }
    }
    
    func fetchConfirmedFriends(for froop: Froop, completion: @escaping (Result<[String], Error>) -> Void) {
        guard !froop.froopHost.isEmpty, !froop.froopId.isEmpty, !froop.froopHost.contains("/"), !froop.froopId.contains("/") else {
            
            return
        }
        
        let confirmedFriendsRef = db.collection("users").document(froop.froopHost).collection("myFroops").document(froop.froopId).collection("invitedFriends").document("confirmedList")
        
        confirmedFriendsRef.getDocument { document, error in
            if let document = document, document.exists {
                let confirmedFriendUIDs = document.data()?["uid"] as? [String] ?? []
                completion(.success(confirmedFriendUIDs))
            } else if let error = error {
                completion(.failure(error))
            } else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Confirmed friends document does not exist"])))
            }
        }
    }
    
    func fetchInvitedFriendData(for froop: Froop, completion: @escaping (Result<[UserData], Error>) -> Void) {
        fetchInvitedFriends(for: froop) { result in
            switch result {
                case .success(let friendUIDs):
                    let dispatchGroup = DispatchGroup()
                    var friends: [UserData] = []
                    
                    for uid in friendUIDs {
                        dispatchGroup.enter()
                        AppStateManager.shared.getUserData(uid: uid) { result in
                            switch result {
                                case .success(let userData):
                                    friends.append(userData)
                                case .failure(let error):
                                    print("Failed to fetch user data: \(error)")
                            }
                            dispatchGroup.leave()
                        }
                    }
                    
                    dispatchGroup.notify(queue: .main) {
                        completion(.success(friends))
                    }
                    
                case .failure(let error):
                    completion(.failure(error))
            }
        }
    }
    
    func fetchInvitedFriends(for froop: Froop, completion: @escaping (Result<[String], Error>) -> Void) {
        guard !froop.froopHost.isEmpty, !froop.froopId.isEmpty, !froop.froopHost.contains("/"), !froop.froopId.contains("/") else {
            
            return
        }
        
        let invitedFriendsRef = db.collection("users").document(froop.froopHost).collection("myFroops").document(froop.froopId).collection("invitedFriends").document("inviteList")
        
        invitedFriendsRef.getDocument { document, error in
            if let document = document, document.exists {
                let invitedFriendUIDs = document.data()?["uid"] as? [String] ?? []
                completion(.success(invitedFriendUIDs))
            } else if let error = error {
                completion(.failure(error))
            } else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invited friends document does not exist"])))
            }
        }
    }
    
    func fetchDeclinedFriendData(for froop: Froop, completion: @escaping (Result<[UserData], Error>) -> Void) {
        fetchDeclinedFriends(for: froop) { result in
            switch result {
                case .success(let friendUIDs):
                    let dispatchGroup = DispatchGroup()
                    var friends: [UserData] = []
                    
                    for uid in friendUIDs {
                        dispatchGroup.enter()
                        AppStateManager.shared.getUserData(uid: uid) { result in
                            switch result {
                                case .success(let userData):
                                    friends.append(userData)
                                case .failure(let error):
                                    print("Failed to fetch user data: \(error)")
                            }
                            dispatchGroup.leave()
                        }
                    }
                    
                    dispatchGroup.notify(queue: .main) {
                        completion(.success(friends))
                    }
                    
                case .failure(let error):
                    completion(.failure(error))
            }
        }
    }
    
    func fetchDeclinedFriends(for froop: Froop, completion: @escaping (Result<[String], Error>) -> Void) {
        guard !froop.froopHost.isEmpty, !froop.froopId.isEmpty, !froop.froopHost.contains("/"), !froop.froopId.contains("/") else {
            
            return
        }
        
        let declinedFriendsRef = db.collection("users").document(froop.froopHost).collection("myFroops").document(froop.froopId).collection("invitedFriends").document("declinedList")
        
        declinedFriendsRef.getDocument { document, error in
            if let document = document, document.exists {
                let declinedFriendUIDs = document.data()?["uid"] as? [String] ?? []
                completion(.success(declinedFriendUIDs))
            } else if let error = error {
                completion(.failure(error))
            } else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Declined friends document does not exist"])))
            }
        }
    }

    func fetchFriendsData(from friendUIDs: [String], completion: @escaping ([UserData]) -> Void) {
        
        let usersRef = db.collection("users")
        var friends: [UserData] = []
        
        let group = DispatchGroup()
        
        for friendUID in friendUIDs {
            group.enter()
            
            usersRef.document(friendUID).getDocument { document, error in
                if let document = document, document.exists, let data = document.data() {
                    if let friend = UserData(dictionary: data) {
                        friends.append(friend)
                        //print("Second Function: fetchFriendsData: \(friends.description)")
                    } else {
                        PrintControl.shared.printFroopManager("Error initializing UserData from document data.")
                    }
                } else if let error = error {
                    PrintControl.shared.printErrorMessages("Error getting document: \(error)")
                }
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            self.userFriends = friends
            completion(friends)
        }
    }
    
    func fetchFroops(for userFriends: [UserData], completion: @escaping ([FroopAndHost]) -> Void) {
        var allFroops: [Froop] = []
        let dispatchGroup = DispatchGroup()
        
        for userFriend in userFriends {
            dispatchGroup.enter()
            let friendUID = userFriend.froopUserID
            let froopsRef = db.collection("users").document(friendUID).collection("myFroops")
            
            froopsRef.getDocuments() { (querySnapshot, err) in
                if let err = err {
                    PrintControl.shared.printErrorMessages("Error getting documents: \(err)")
                } else {
                    for document in querySnapshot!.documents {
                        let data = document.data()
                        let froop = Froop(dictionary: data)
                        allFroops.append(froop)
                    }
                }
                dispatchGroup.leave()
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            let froopsWithImages = self.filterFroopsWithoutImages(from: allFroops)
            let froopAndHostArray = self.createFroopAndHostArray(from: froopsWithImages, and: userFriends)
            completion(froopAndHostArray)
        }
    }
    
    func fetchUserArchivedFroops(for uid: String, completion: @escaping ([Froop]) -> Void) {
        var allFroops: [Froop] = []
        
        let archivedFroopsRef = db.collection("users").document(uid).collection("myDecisions").document("froopLists").collection("myArchivedList")
        
        archivedFroopsRef.getDocuments() { (querySnapshot, err) in
            if let err = err {
                PrintControl.shared.printErrorMessages("Error getting documents: \(err)")
                completion([]) // returning an empty array in case of error
            } else {
                for document in querySnapshot!.documents {
                    let data = document.data()
                    let froop = Froop(dictionary: data)
                    allFroops.append(froop)
                    
                }
                completion(allFroops)
            }
        }
    }
    func addMediaURLToDocument(froopHost: String, froopId: String, mediaURL: URL, isImage: Bool) {
        PrintControl.shared.printFroopManager("-FroopManager: Function: addMediaURLToDocument is firing!")
        
        let userRef = db.collection("users").document(froopHost)
        let froopsRef = userRef.collection("myFroops").document(froopId)
        
        let mediaField = isImage ? "froopImages" : "froopVideos"
        
        froopsRef.updateData([
            mediaField: FieldValue.arrayUnion([mediaURL.absoluteString])
        ]) { error in
            if let error = error {
                PrintControl.shared.printFroopManager("Error updating document: \(error)")
            } else {
                PrintControl.shared.printFroopManager("Document successfully updated")
            }
        }
    }
    
    func updateFroopState(_ state: FroopState, for froop: Froop) {
        PrintControl.shared.printFroopManager("-FroopManager: Function: updateFroopState is firing!")
        PrintControl.shared.printFroopManager("Froop State Change to \(state) for \(froop.froopId) with name: \(froop.froopName) starting at \(froop.froopStartTime)")
        
        switch state {
            case .froopPreGame:
                setActiveFroop(froop)
                notificationCenter.notifyStatusChanged(froop)
                // startMediaScanForActiveFroop()
            default:
                break
        }
    }
    
    func addMediaURLsToDocument(froopHost: String, froopId: String, fullsizeImageUrl: URL, displayImageUrl: URL, thumbnailImageUrl: URL, isImage: Bool) {
        let froopRef = db.collection("users").document(froopHost).collection("myFroops").document(froopId)
        
        froopRef.updateData([
            "froopImages": FieldValue.arrayUnion([fullsizeImageUrl.absoluteString]),
            "froopDisplayImages": FieldValue.arrayUnion([displayImageUrl.absoluteString]),
            "froopThumbNailImages": FieldValue.arrayUnion([thumbnailImageUrl.absoluteString])
        ]) { err in
            if let err = err {
                print("Error updating document: \(err)")
            } else {
                print("Document successfully updated")
            }
        }
    }
    
    func addActiveFroop(froop: Froop) {
        PrintControl.shared.printFroopManager("-FroopManager: Function: addActiveFroop firing")
        activeFroops.append(froop)
    }
    
    func removeActiveFroop(froopId: String) {
        PrintControl.shared.printFroopManager("-FroopManager: Function: removeActiveFroop firing")
        activeFroops.removeAll { $0.froopId == froopId }
    }
    
    func setActiveFroop(_ froop: Froop) {
        PrintControl.shared.printFroopManager("-FroopManager: Function: setActiveFroop firing")
        if let index = activeFroops.firstIndex(where: { $0.froopId == froop.froopId }) {
            activeFroops[index] = froop
        }
    }
    
    func subscribeToNotifications(_ delegate: FroopNotificationDelegate) {
        PrintControl.shared.printFroopManager("-FroopManager: Function: subscribeToNotifications firing")
        notificationCenter.delegate = delegate
    }
    
    func unsubscribeFromNotifications() {
        PrintControl.shared.printFroopManager("-FroopManager: Function: unauvaxeivwDeomNotifications firing")
        notificationCenter.delegate = nil
    }
    
    func filterFroopsWithoutImages(from froops: [Froop]) -> [Froop] {
        return froops.filter { !$0.froopImages.isEmpty }
    }
    
    func createFroopAndHostArray(from froops: [Froop], and hosts: [UserData]) -> [FroopAndHost] {
        var froopAndHostArray: [FroopAndHost] = []
        
        for froop in froops {
            if let host = hosts.first(where: { $0.froopUserID == froop.froopHost }) {
                let froopAndHost = FroopAndHost(froop: froop, host: host)
                froopAndHostArray.append(froopAndHost)
            }
        }
        
        return froopAndHostArray
    }
    
    func saveFroopDropPins(froopHost: String, froopId: String, completion: @escaping (Error?) -> Void) {
        let froopDocRef = db.collection("users").document(froopHost).collection("myFroops").document(froopId)
        let annotationCollectionRef = froopDocRef.collection("annotations")
        
        let dispatchGroup = DispatchGroup()
        
        for froopDropPin in froopDropPins {
            dispatchGroup.enter()
            let documentId = froopDropPin.id.uuidString
            annotationCollectionRef.document(documentId).getDocument { (document, error) in
                if let error = error {
                    completion(error)
                    dispatchGroup.leave()
                    return
                }
                
                if let document = document, document.exists {
                    // Document already exists, skipping
                    dispatchGroup.leave()
                } else {
                    // Document does not exist, create a new one
                    do {
                        let froopDropPinData = froopDropPin.dictionary
                        annotationCollectionRef.document(documentId).setData(froopDropPinData) { error in
                            if let error = error {
                                completion(error)
                            }
                            dispatchGroup.leave()
                        }
                    }
                }
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            completion(nil)
        }
    }
    
}




struct FroopAndHost: Identifiable, Equatable {
    let id = UUID() // This is a unique identifier for each FroopAndHost
    let froop: Froop
    let host: UserData
    
    static func == (lhs: FroopAndHost, rhs: FroopAndHost) -> Bool {
        return lhs.id == rhs.id
    }
}

struct FroopHostAndFriends : Identifiable, Equatable {
    let id = UUID()
    let FH: FroopAndHost
    let friends: [UserData]
    
    static func == (lhs: FroopHostAndFriends, rhs: FroopHostAndFriends) -> Bool {
        return lhs.id == rhs.id
    }
}

class FroopHistory: ObservableObject, Identifiable, Equatable, Hashable {
    
    enum FroopStatus: String {
        case invited = "invited"
        case confirmed = "confirmed"
        case archived = "archived"
        case none = "none"
    }
    
    let id = UUID() // This is a unique identifier for each FroopHistory
    var froop: Froop
    var host: UserData
    var friends: [UserData]
    var images: [String]
    var videos: [String]
    var froopStatus: FroopStatus = .none // This property is to store the froop status
    var statusText: String = ""
    
    init(froop: Froop, host: UserData, friends: [UserData], images: [String], videos: [String]) {
        self.froop = froop
        self.host = host
        self.friends = friends
        self.images = images
        self.videos = videos
        
        textForStatus()
        determineFroopStatus() 
    }
    
    static func == (lhs: FroopHistory, rhs: FroopHistory) -> Bool {
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
           hasher.combine(id)
       }
    
}

