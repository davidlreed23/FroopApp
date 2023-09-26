//
//  AppStateManager.swift
//  FroopProof
//
//  Created by David Reed on 4/17/23.
//

import SwiftUI
import UIKit
import Combine
import FirebaseFirestore
import FirebaseAuth
import Foundation
import MapKit

enum AppState {
    case passive
    case active
}

enum FroopTabState {
    case selected
    case notSelected
}

enum Stage {
    case starting
    case running
    case ending
    case none
}

class AppStateManager: ObservableObject {
    static let shared = AppStateManager()
    
    @Published var mediaTimeStamp: [Date] = []
    var onUpdateMapView: (() -> Void)?
    var db = FirebaseServices.shared.db
    @Published var froopIsEditing: Bool = false
    @Published var appState: AppState = .passive
    @Published var activeFroopId: String?
    @Published var activeFroop: Froop = Froop(dictionary: [:])
    @Published var fetchedFroops: [Froop] = []
    @Published var activeFroops: [Froop] = []
    @Published var inProgressFroop: Froop = Froop.emptyFroop()
    @Published var changeLocation: CLLocationCoordinate2D = CLLocationCoordinate2D()
    private var uid = FirebaseServices.shared.uid
    private var cancellables = Set<AnyCancellable>()
    let myConfirmedListCollection: CollectionReference?
    @Published var froopTabSelected: FroopTabState = .notSelected
    @Published var activeFroopPins: [ApexAnnotationPin] = []
    @Published var activeHostData: UserData = UserData()
    @Published var activeInvitedFriends: [UserData] = []
    @Published var isDarkStyle: Bool = false
    @Published var activeInvitedUids: [String] = [""]
    @Published var shouldPresentFroopSelection = false
    @Published var froopTypes: [Int: String] = [:]
    @Published var stateTransitionTimerOn: Bool = false
    @Published var isMessageViewPresented = false
    @Published var guestPhoneNumber = ""
    @Published var isAnnotationMade = false
    @Published var isFroopTabUp = true
    @Published var showChatView = false
    @Published var chatViewId: String?
    @Published var chatWith: UserData = UserData()
    @Published var selectedTab = 1
    @Published var visualEffectViewOpacity: Double = 0.0
    @Published var parentViewOpacity: Double = 0.0
    @Published var visualEffectViewPresented: Bool = false
    @Published var parentViewPresented: Bool = false
    @Published var hVTimer = Timer.publish(every: 15, on: .main, in: .common).autoconnect()
    @Published var selectedTabTwo: Int = 0
    @Published var profileToggle: Bool = true
    var timerCancellable: Cancellable?
    var now = Date()
    var timer: DispatchSourceTimer?
    var removalTimer: DispatchSourceTimer?
    var froopEndTimers: [String: Timer] = [:]

    
    
    @Published var centerCoordinate: CLLocationCoordinate2D?
    var selectedUserCoordinateCancellable: AnyCancellable?
    
    @Published var inProgressFroops: [Froop] = [] {
        didSet {
            checkForStateTransition() {
                print("--AppStateManager State Changed: \(self.appState)")
            }
        }
    }
    
    var updateTimer: Timer?
    
    var currentStage: Stage {
        let now = Date()
        if now < inProgressFroop.froopStartTime {
            return .starting
        } else if now < inProgressFroop.froopEndTime {
            return .running
        } else if now < inProgressFroop.froopEndTime.addingTimeInterval(2*60) {
            return .ending
        } else {
            return .none
        }
    }
    
    private var stateTransitionTimer: Timer?
    
    init() {

        // Initialize your properties
        self.chatViewId = ""
        self.chatWith = UserData()
        
        let uid = FirebaseServices.shared.uid
        myConfirmedListCollection = db.collection("users").document(uid).collection("froopDecisions").document("froopLists").collection("myConfirmedList")
        setupListener { userData in
            // Handle the fetched user data here
            if userData != nil {
                // Do something with userData
            } else {
                // Handle the case where no user data was fetched
            }
        }
        fetchAllFroopTypes()
        guard !FirebaseServices.shared.uid.isEmpty else {
            PrintControl.shared.printErrorMessages("Error: no user is currently signed in.")
            return
        }
        fetchActiveHostData(uid: uid) { userData in
            // Handle the fetched user data here
        }
        setupCountdownTimer()
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
    var locationManager: LocationManager {
        return LocationManager.shared
    }
    var confirmedFroops: ConfirmedFroopsList {
        return ConfirmedFroopsList(activeFroops: self.activeFroops)
    }
    
    func scheduleNextActivationCheck() {
        timer?.cancel() // Cancel any previous timer
        
        guard let nextFroop = fetchedFroops.sorted(by: { $0.froopStartTime < $1.froopStartTime }).first else {
            return
        }

        let activationTime = nextFroop.froopStartTime.addingTimeInterval(-30 * 60) // 30 minutes before start time
        let timeUntilNextActivation = activationTime.timeIntervalSinceNow
        
        if timeUntilNextActivation <= 0 {
            // The froop's activation time has passed, reschedule the next check
            scheduleNextActivationCheck()
            return
        }
        
        timer = DispatchSource.makeTimerSource(queue: DispatchQueue.main)
        timer?.schedule(deadline: .now() + timeUntilNextActivation)
        timer?.setEventHandler {
            self.handleActiveFroop(fetchedFroops: self.fetchedFroops) { userData in
                // Use userData if needed...
                
                self.checkForStateTransition {
                    self.scheduleNextActivationCheck() // Schedule the check for the next Froop after this one
                }
            }
        }
        timer?.resume()
    }
    
    func handleActiveFroop(fetchedFroops: [Froop], completion: @escaping (UserData?) -> Void) {
        let now = Date()
        let activeFroops = fetchedFroops.filter { froop in
            let preGameWindowStart = froop.froopStartTime.addingTimeInterval(-30 * 60)
            let postGameWindowEnd = froop.froopEndTime.addingTimeInterval(30 * 60)
            return now >= preGameWindowStart && now <= postGameWindowEnd
        }
        
        PrintControl.shared.printAppState("<>Checking activeFroop count: \(activeFroops.count)")
        if activeFroops.count >= 1 {
            PrintControl.shared.printAppState("<>---SetupListener Active Froops: \(activeFroops.count.description)")
            self.appState = .active
        }
        self.confirmedFroops.activeFroops = activeFroops
        self.stateTransitionTimer?.invalidate()
        self.stateTransitionTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
            self.checkForStateTransition() {
                PrintControl.shared.printAppState("<>--self.checkForStateTransition() completed")
            }
        }
        
        // Determine the Froop with the closest postGameWindowEnd to now.
        if let closestFroop = activeFroops.min(by: { a, b in
            let postGameWindowEndA = a.froopEndTime.addingTimeInterval(30 * 60)
            let postGameWindowEndB = b.froopEndTime.addingTimeInterval(30 * 60)
            return abs(postGameWindowEndA.timeIntervalSince(now)) < abs(postGameWindowEndB.timeIntervalSince(now))
        }) {
            let closestPostGameWindowEnd = closestFroop.froopEndTime.addingTimeInterval(30 * 60)
            let timeInterval = closestPostGameWindowEnd.timeIntervalSince(now) + 5  // Add 5 seconds.
            if timeInterval > 0 {
                Timer.scheduledTimer(withTimeInterval: timeInterval, repeats: false) { _ in
                    self.setupListener() { _ in } // Empty completion closure
                }
            }
        }
        
        let froopEndTime = self.inProgressFroop.froopEndTime
        let fireDate = froopEndTime.addingTimeInterval(30 * 60)
        let timeInterval = fireDate.timeIntervalSince(Date())
        if timeInterval > 0 {
            let timer = Timer.scheduledTimer(withTimeInterval: timeInterval, repeats: false) { [weak self] _ in
                self?.removeFroop(withId: self?.inProgressFroop.froopId ?? "")
            }
            self.froopEndTimers[self.inProgressFroop.froopId] = timer
        }
        
        // Update the inProgressFroop and fetch active host data if there is an active froop
        if let activeFroop = activeFroops.first {
            self.fetchActiveHostData(uid: activeFroop.froopHost) { userData in
                completion(userData)
            }
            
            // Other logic to handle active Froop...
            
            // Truncated for brevity...
        }
    }
    
    func manageFroopEnd() {
        removalTimer?.cancel() // Cancel any previous end timer

        guard let endingFroop = fetchedFroops.sorted(by: { $0.froopEndTime < $1.froopEndTime }).first else {
            return
        }

        let removalTime = endingFroop.froopEndTime.addingTimeInterval(30 * 60) // 30 minutes after end time
        let timeUntilRemoval = removalTime.timeIntervalSinceNow

        if timeUntilRemoval <= 0 {
            // The froop's removal time has passed, remove it and reschedule
            if let index = activeFroops.firstIndex(where: { $0.froopEndTime == endingFroop.froopEndTime }) {
                activeFroops.remove(at: index)
            }
            manageFroopEnd()
            return
        }

        removalTimer = DispatchSource.makeTimerSource(queue: DispatchQueue.main)
        removalTimer?.schedule(deadline: .now() + timeUntilRemoval)
        removalTimer?.setEventHandler {
            if let index = self.activeFroops.firstIndex(where: { $0.froopEndTime == endingFroop.froopEndTime }) {
                self.activeFroops.remove(at: index)
            }
            self.manageFroopEnd() // Schedule the removal of the next Froop after this one
        }
        removalTimer?.resume()
    }
    
    func trackUserLocation(_ user: UserData) {
        // Cancel the previous subscription if it exists
        selectedUserCoordinateCancellable?.cancel()
        
        print("Sending coordinate \(user.coordinate)")
        centerCoordinate = user.coordinate
        
        // Create a new subscription for the user's coordinate
        selectedUserCoordinateCancellable = user.$coordinate.sink { [weak self] newCoordinate in
            self?.centerCoordinate = newCoordinate
        }
    }
    
    func fetchHostData(uid: String, completion: @escaping (Result<UserData, Error>) -> Void) {
        DispatchQueue.global().async { //
            PrintControl.shared.printAppState("Starting fetchHostData for uid: \(uid)")
            self.getUserData(uid: uid) { [weak self] result in
                switch result {
                    case .success(let userData):
                        DispatchQueue.main.async {
                            self?.activeHostData = userData
                            PrintControl.shared.printAppState("Successfully fetched host data for uid: \(uid)")
                            completion(.success(userData))
                        }
                    case .failure(let error):
                        DispatchQueue.main.async {
                            PrintControl.shared.printAppState("Failed to fetch host data for uid: \(uid). Error: \(error.localizedDescription)")
                            completion(.failure(error))
                        }
                }
            }
        }
    }
    
    func findFroopById(froopId: String, completion: @escaping (Bool) -> Void) {
        var found = false
        PrintControl.shared.printAppState("Starting findFroopById for froopId: \(froopId)")
        for froop in inProgressFroops {
            if froop.froopId == froopId {
                inProgressFroop = froop
                found = true
                print("FroopId found: \(froopId)")
                break
            }
        }
        if !found {
            PrintControl.shared.printAppState("FroopId not found: \(froopId)")
        }
        completion(found)
    }
    
    func fetchAllFroopTypes() {
        let froopTypesRef = db.collection("froopTypes")
        
        froopTypesRef.getDocuments { (querySnapshot, error) in
            if let error = error {
                PrintControl.shared.printErrorMessages("Error fetching froop types: \(error.localizedDescription)")
            } else if let querySnapshot = querySnapshot {
                let froopTypesArray = querySnapshot.documents.compactMap { document -> (Int, String)? in
                    if let typeName = document.get("name") as? String,
                       let typeId = Int(document.documentID) {
                        return (typeId, typeName)
                    } else {
                        return nil
                    }
                }
                self.froopTypes = Dictionary(uniqueKeysWithValues: froopTypesArray)
                //print(self.froopTypes.description)
            }
        }
    }
    
    func fetchActiveHostData(uid: String, completion: @escaping (UserData?) -> Void) {
        DispatchQueue.global().async {
            PrintControl.shared.printAppState("-AppStateManager: Function: fetchActiveHostData is Firing!")
            self.getUserData(uid: uid) { result in
                DispatchQueue.main.async {
                    switch result {
                        case .success(let userData):
                            PrintControl.shared.printAppState("--Function: fetchActiveHostData: We Retrieved Host Data: \(uid)")
                            completion(userData)
                        case .failure(let error):
                            PrintControl.shared.printAppState("--Function: fetchActiveHostData: Failed to fetch user data: \(error.localizedDescription)")
                            completion(nil)
                    }
                }
            }
        }
    }
    
    func getUserData(uid: String, completion: @escaping (Result<UserData, Error>) -> Void) {
        DispatchQueue.global().async { //
            guard !uid.isEmpty else {
                PrintControl.shared.printErrorMessages("Failed to get user ID.")
                return
            }
            PrintControl.shared.printAppState("-AppStateManager: Function: getUserData is Firing!")
            let userDocumentRef = self.db.collection("users").document(uid)
            
            userDocumentRef.getDocument { (snapshot, error) in
                if let error = error {
                    PrintControl.shared.printAppState("Error fetching user data: \(error.localizedDescription)")
                    completion(.failure(error))
                } else {
                    if let snapshot = snapshot, let data = snapshot.data(), let userData = UserData(dictionary: data) {
                        completion(.success(userData))
                    } else {
                        let error = NSError(domain: "UserDataError", code: -1, userInfo: [NSLocalizedDescriptionKey: "User document not found or failed to parse"])
                        completion(.failure(error))
                    }
                }
            }
        }
    }
    
    // Add the updateActiveFroop() function
    func updateActiveFroop(completion: @escaping () -> Void) {
        PrintControl.shared.printAppState("-AppStateManager: Function: updateActiveFroop is Firing!")
        if let firstFroop = confirmedFroops.activeFroops.first {
            activeFroop = firstFroop
            activeFroopId = firstFroop.froopId
            //            PrintControl.shared.printAppState("Dump firstFroop:")
            //            dump(PrintControl.shared.printAppState ? firstFroop: nil)
        } else {
            activeFroopId = nil
        }
        completion()
    }
    
    func checkForStateTransition(completion: @escaping () -> Void) {
        PrintControl.shared.printAppState("--Check For State Transition Function Firing!")
        let now = Date()
        PrintControl.shared.printAppState("--checkForStateTransition Date \(now)")
        if inProgressFroops.count >= 1 {
            PrintControl.shared.printAppState("InProgressFroops Count = \(inProgressFroops.count)")
            appState = .active
            locationManager.startUpdating()
            PrintControl.shared.printAppState("--->AppState is set to .active")
        }
        
        if inProgressFroops.count >= 1 {
            PrintControl.shared.printAppState("--checkForStateTransition activeFroops >= 1 is true")
            PrintControl.shared.printAppState("--checkForStateTransition() InProgress Froop Count = \(inProgressFroops.count.description)")
            PrintControl.shared.printAppState("--checkForStateTransition() Active Froop Count = \(activeFroops.count.description)")
            
            PrintControl.shared.printAppState("--checkForStateTransition activeFroops >= 1 is false")
            shouldPresentFroopSelection = inProgressFroops.count > 1
            
        } else {
            PrintControl.shared.printAppState("Count Not Seeing anything!")
            // If there are no active Froops, set the appState to .passive
            if appState != .passive {
                appState = .passive
                locationManager.stopUpdating()
                print("--->AppState is set to .passive")
                inProgressFroop = Froop.emptyFroop()
                activeFroopId = nil
                shouldPresentFroopSelection = false
            }
        }
        completion()
    }
    
    func setupListenersForGuests() {
        for guest in activeInvitedFriends {
            let guestDocRef = db.collection("users").document(guest.froopUserID)
            
            let listener = guestDocRef.addSnapshotListener { [weak self] documentSnapshot, error in
                if let error = error {
                    print("Error listening for guest updates: \(error)")
                    return
                }
                
                guard let self = self else { return }
                
                if let documentSnapshot = documentSnapshot, let data = documentSnapshot.data() {
                    let guestData = UserData(dictionary: data)
                    if let geoPoint = data["coordinate"] as? GeoPoint {
                        let updatedCoordinate = FirebaseServices.shared.convertToCoordinate(geoPoint: geoPoint)
                        guestData?.coordinate = updatedCoordinate
                    }
                    
                    if let index = self.activeInvitedFriends.firstIndex(where: { $0.froopUserID == guest.froopUserID }) {
                        // Update the existing UserData object
                        DispatchQueue.main.async {
                            self.activeInvitedFriends[index] = guestData ?? UserData()
                        }
                    }
                    
                    // Trigger an update to the map view
                    self.updateMapView()
                }
            }
            
            // Store the listener in a dictionary so it can be removed later, if needed
            FirebaseServices.shared.listeners[guest.froopUserID] = listener
        }
    }
    
    func updateMapView() {
        DispatchQueue.main.async { [weak self] in
            self?.onUpdateMapView?()
        }
    }
    
    func setupListener(completion: @escaping (UserData?) -> Void) {
        PrintControl.shared.printAppState("<>-AppStateManager: Function: setupListener firing")
        FirebaseServices.shared.listener = myConfirmedListCollection?.addSnapshotListener { [weak self] querySnapshot, error in
            
            if let error = error {
                PrintControl.shared.printAppState("<>Error listening for myConfirmedList updates: \(error)")
                return
            }
            
            guard let self = self else { return }
            
            let documents = querySnapshot?.documents ?? []
            let froopInvites = documents.compactMap { document -> FroopInviteDataModel? in
                let data = document.data()
                guard let froopId = data["froopId"] as? String,
                      let froopHost = data["froopHost"] as? String
                else { return nil }
                return FroopInviteDataModel(froopId: froopId, froopHost: froopHost)
            }
            
            let dispatchGroup = DispatchGroup()
            var fetchedFroops: [Froop] = []
            
            for invite in froopInvites {
                dispatchGroup.enter()
                let froopDocRef = self.db
                    .collection("users")
                    .document(invite.froopHost)
                    .collection("myFroops")
                    .document(invite.froopId)
                
                froopDocRef.getDocument { documentSnapshot, error in
                    defer { dispatchGroup.leave() } // This will ensure leave() is called at the end of this closure, no matter what
                    if let error = error {
                        PrintControl.shared.printAppStateSetupListener("Error fetching froop document: \(error)")
                        return
                    }
                    guard let documentSnapshot = documentSnapshot, let data = documentSnapshot.data() else {
                        PrintControl.shared.printAppStateSetupListener("Froop document does not exist")
                        return
                    }
                    var froop = Froop(dictionary: data)
                    PrintControl.shared.printAppState("<>Froop Retrieved \(froop.froopId) called \(froop.froopName)")
                    if let froopLocationCoordinate = data["froopLocationCoordinate"] as? GeoPoint {
                        let coordinate = CLLocationCoordinate2D(latitude: froopLocationCoordinate.latitude, longitude: froopLocationCoordinate.longitude)
                        froop.froopLocationCoordinate = coordinate
                    }
                    PrintControl.shared.printAppState("<>Appending Froop to fetchedFroops:  \(froop.froopId) which starts at \(froop.froopStartTime) and ends at \(froop.froopEndTime) vs. now: \(Date()) ")
                    fetchedFroops.append(froop)
                }
                print("App State Manager Fetched Froops:")
                for froop in fetchedFroops {
                    print(froop.froopName)
                }
            
                DispatchQueue.main.async {
                    self.fetchedFroops = fetchedFroops
                }
                self.scheduleNextActivationCheck()
                self.manageFroopEnd()
            }
            
            dispatchGroup.notify(queue: .main) {
                PrintControl.shared.printAppState("<>String describing fetchedFroops \(String(describing: fetchedFroops))")
                let now = Date()
                let activeFroops = fetchedFroops.filter { froop in
                    let preGameWindowStart = froop.froopStartTime.addingTimeInterval(-30 * 60)
                    let postGameWindowEnd = froop.froopEndTime.addingTimeInterval(30 * 60)
                    return now >= preGameWindowStart && now <= postGameWindowEnd
                }
                PrintControl.shared.printAppState("<>Checking activeFroop count: \(activeFroops.count)")
                if activeFroops.count >= 1 {
                    PrintControl.shared.printAppState("<>---SetupListener Active Froops: \(activeFroops.count.description)")
                    self.appState = .active
                }
                self.confirmedFroops.activeFroops = activeFroops
                self.stateTransitionTimer?.invalidate()
                self.stateTransitionTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
                    self.checkForStateTransition() {
                        PrintControl.shared.printAppState("<>--self.checkForStateTransition() completed")
                    }
                }
                
                // Determine the Froop with the closest postGameWindowEnd to now.
                if let closestFroop = activeFroops.min(by: { a, b in
                    let postGameWindowEndA = a.froopEndTime.addingTimeInterval(30 * 60)
                    let postGameWindowEndB = b.froopEndTime.addingTimeInterval(30 * 60)
                    return abs(postGameWindowEndA.timeIntervalSince(now)) < abs(postGameWindowEndB.timeIntervalSince(now))
                }) {
                    let closestPostGameWindowEnd = closestFroop.froopEndTime.addingTimeInterval(30 * 60)
                    let timeInterval = closestPostGameWindowEnd.timeIntervalSince(now) + 5  // Add 5 seconds.
                    if timeInterval > 0 {
                        Timer.scheduledTimer(withTimeInterval: timeInterval, repeats: false) { _ in
                            self.setupListener() { _ in } // Empty completion closure
                        }
                    }
                }
                
                let froopEndTime = self.inProgressFroop.froopEndTime
                let fireDate = froopEndTime.addingTimeInterval(30 * 60)
                let timeInterval = fireDate.timeIntervalSince(Date())
                if timeInterval > 0 {
                    let timer = Timer.scheduledTimer(withTimeInterval: timeInterval, repeats: false) { [weak self] _ in
                        self?.removeFroop(withId: self?.inProgressFroop.froopId ?? "")
                    }
                    self.froopEndTimers[self.inProgressFroop.froopId] = timer
                }
                
                
                // Update the inProgressFroop and fetch active host data if there is an active froop
                if let activeFroop = activeFroops.first {
                    self.fetchActiveHostData(uid: activeFroop.froopHost) { userData in
                        completion(userData)
                    }
                    PrintControl.shared.printAppState("<>Active Froop = \(activeFroop.froopId)")
                    self.inProgressFroop = activeFroop
                    PrintControl.shared.printAppState("<>self.inProgressFroop = \(self.inProgressFroop.froopId)")
                    self.inProgressFroops = activeFroops
                    PrintControl.shared.printAppState("<>self.inProgressFroops.count = \(self.inProgressFroops.count)")
                    self.fetchActiveHostData(uid: activeFroop.froopHost) { userData in
                        // Handle the fetched user data here
                        if userData != nil {
                            // Do something with userData
                        } else {
                            // Handle the case where no user data was fetched
                        }
                    }
                    
                    // Check that froopHost and froopId are not empty
                    if activeFroop.froopHost.isEmpty || activeFroop.froopId.isEmpty {
                        PrintControl.shared.printAppStateSetupListener("Error: froopHost or froopId is empty")
                        return
                    }
                    
                    PrintControl.shared.printAppState("<>Froop Host: \(activeFroop.froopHost)")
                    PrintControl.shared.printAppState("<>Froop Id: \(activeFroop.froopId)")
                    PrintControl.shared.printAppState("<>Froop Start Time: \(activeFroop.froopStartTime.description)")
                    PrintControl.shared.printAppState("<>Froop End Time: \(activeFroop.froopEndTime.description)")
                    //                    PrintControl.shared.printAppState("Froop Dump: \(dump(activeFroop))")
                    // 1. Populate activeInvitedUids array
                    
                    let froopDocRef = self.db.collection("users").document(activeFroop.froopHost).collection("myFroops").document(activeFroop.froopId)
                    let confirmedListDocRef = froopDocRef.collection("invitedFriends").document("confirmedList")
                    
                    confirmedListDocRef.getDocument { (documentSnapshot, error) in
                        if let error = error {
                            PrintControl.shared.printAppState("<>Error fetching confirmed friends list: \(error)")
                        } else if let documentSnapshot = documentSnapshot {
                            if documentSnapshot.exists {
                                if let data = documentSnapshot.data(),
                                   let uids = data["uid"] as? [String] {
                                    // Check that UIDs are not empty
                                    for uid in uids {
                                        if uid.isEmpty {
                                            PrintControl.shared.printAppState("<>Error: UID is empty")
                                            continue
                                        }
                                        // Use uid to fetch data from Firestore
                                    }
                                    PrintControl.shared.printAppState("<>DUMPING SELF.ACTIVEINVITEDUIDS\(self.activeInvitedUids)")
                                    PrintControl.shared.printAppState("<>DUMPING UIDS\(uids)")
                                    self.activeInvitedUids = uids
                                    
                                    // Call the fetchInvitedFriendsDataAndSetCoordinates() here, inside this closure
                                    self.fetchInvitedFriendsDataAndSetCoordinates(completion: {})
                                }
                            } else {
                                PrintControl.shared.printAppState("<>No confirmed friends yet.")
                                self.activeInvitedUids = []
                            }
                        }
                    }
                    
                }
                if let temporaryListener = FirebaseServices.shared.temporaryListener {
                    FirebaseServices.shared.listeners["myConfirmedListCollection"] = temporaryListener
                }
            }
            FirebaseServices.shared.listener = FirebaseServices.shared.temporaryListener
            AppStateManager.shared.checkForStateTransition() {
                PrintControl.shared.printAppState("--AppStateManager.shared.checkForStateTransition() completed")
            }
        }
    }
    
    func removeFroop(withId id: String) {
        // Find the index of the Froop in the activeFroops array
        if let index = activeFroops.firstIndex(where: { $0.froopId == id }) {
            // Remove the Froop from the array
            activeFroops.remove(at: index)
        }
        
        // Invalidate and remove the timer
        froopEndTimers[id]?.invalidate()
        froopEndTimers[id] = nil
    }
    
    func fetchUserCoordinate(for froopUserID: String, completion: @escaping (Result<CLLocationCoordinate2D, Error>) -> Void) {
        let db = FirebaseServices.shared.db
        let userDocumentRef = db.collection("users").document(froopUserID)
        
        userDocumentRef.getDocument { (document, error) in
            if let error = error {
                completion(.failure(error))
            } else {
                if let document = document, document.exists,
                   let data = document.data(),
                   let currentLocation = data["currentLocation"] as? [String: Any],
                   let latitude = currentLocation["latitude"] as? CLLocationDegrees,
                   let longitude = currentLocation["longitude"] as? CLLocationDegrees {
                    
                    let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                    completion(.success(coordinate))
                } else {
                    completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to parse user document or coordinate not found."])))
                }
            }
        }
    }
    
    
    func fetchInvitedFriendsDataAndSetCoordinates(completion: @escaping () -> Void) {
        PrintControl.shared.printAppState("========================1 AppStateManager: Function: fetchInvitedFriendsDataAndSetCoordinates is Firing!")
        for froopUserID in activeInvitedUids {
            if froopUserID.isEmpty {
                PrintControl.shared.printErrorMessages("Error: froopUserID is empty")
                continue
            }
            
            PrintControl.shared.printAppState("========================2 Fetching friend data for UID: \(froopUserID)")
            let userDocumentRef = db.collection("users").document(froopUserID)
            
            let listener = userDocumentRef.addSnapshotListener { [weak self] snapshot, error in
                if let error = error {
                    PrintControl.shared.printAppState("========================3 Error listening for user data updates: \(error)")
                } else {
                    if let snapshot = snapshot {
                        PrintControl.shared.printAppState("Snapshot: \(snapshot)") // Print the snapshot
                        if let data = snapshot.data() {
                            PrintControl.shared.printAppState("Data: \(data)") // Print the data
                            if let userData = UserData(dictionary: data) {
                                PrintControl.shared.printAppState("========================4 Successfully fetched user data for UID: \(froopUserID)")
                                
                                // Set the coordinate property
                                if let geoPoint = data["coordinate"] as? GeoPoint {
                                    let updatedCoordinate = FirebaseServices.shared.convertToCoordinate(geoPoint: geoPoint)
                                    PrintControl.shared.printAppState("========================5 Updated coordinate for UID \(froopUserID): \(updatedCoordinate)")
                                    
                                    userData.coordinate = updatedCoordinate
                                    if let index = self?.activeInvitedFriends.firstIndex(where: { $0.froopUserID == froopUserID }) {
                                        // Update the existing UserData object
                                        self?.activeInvitedFriends[index] = userData
                                        PrintControl.shared.printAppState("========================6 Updated activeInvitedFriends array with new coordinate for UID \(froopUserID)")
                                    } else {
                                        // Add the new UserData object to the array
                                        DispatchQueue.main.async {
                                            self?.activeInvitedFriends.append(userData)
                                        }
                                        PrintControl.shared.printAppState("========================6 Added new UserData object to activeInvitedFriends array for UID \(froopUserID)")
                                    }
                                } else {
                                    PrintControl.shared.printAppState("========================8 User document not found or failed to parse for UID: \(froopUserID)")
                                }
                            }
                        }
                    }
                }
            }
            
            // Store the listener in a dictionary so it can be removed later, if needed
            FirebaseServices.shared.listeners[froopUserID] = listener
        }
        completion()
        return
    }
    
    func getActiveFroop() -> Froop? {
        PrintControl.shared.printAppState("========================AppStateManager: Function: getActiveFroop is Firing!")
        if let firstFroop = confirmedFroops.activeFroops.first {
            activeFroop = firstFroop
            activeFroopId = firstFroop.froopId // Update the activeFroopId property
            PrintControl.shared.printAppState("========================Dump firstFroop:")
            //            dump(PrintControl.shared.printAppState ? firstFroop: nil)
            return firstFroop
        }
        return nil
    }
    
}


