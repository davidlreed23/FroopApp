//
//  TripService.swift
//  FroopProof
//
//  Created by David Reed on 1/20/23.
//

//import Firebase
//import SwiftUI
//import UIKit
//
//typealias FirestoreCompletion = (((Error?) -> Void)?)
//
//struct TripService {
//    @ObservedObject var appStateManager = AppStateManager.shared
//    @ObservedObject var printControl = PrintControl.shared
//    @ObservedObject var locationServices = LocationServices.shared
//    @ObservedObject var froopDataListener = FroopDataListener.shared
//    // MARK: - Properties
//
//    var trip: Trip?
//    var user: User?
//
//    // MARK: - Helpers
//
//    private func updateTripState(_ trip: Trip, state: TripState, completion: FirestoreCompletion) {
//        print("-TripService: Function: updateTripState is firing!")
//
//        COLLECTION_RIDES.document(trip.tripId).updateData(["tripState": state.rawValue], completion: completion)
//    }
//
//    private func deleteTrip(completion: FirestoreCompletion) {
//        print("-TripService: Function: deleteTrip is firing!")
//        guard let trip = trip else { return }
//
//        COLLECTION_RIDES.document(trip.tripId).delete(completion: completion)
//    }
//}

// MARK: - Driver API

//extension TripService {
//    func addTripObserverForDriver(listener: @escaping (QuerySnapshot?, Error?) -> Void) {
//        guard let user = user, user.accountType == .driver, let uid = user.id else { return }
//        COLLECTION_RIDES.whereField("driverUid", isEqualTo: uid).addSnapshotListener(listener)
//    }

//    func acceptTrip(completion: FirestoreCompletion) {
//        guard let trip = trip else { return }
//        guard let user = user, user.accountType == .driver else { return }
//
//        COLLECTION_RIDES.document(trip.tripId) .updateData(["tripState": MapViewState.tripAccepted.rawValue], completion: completion)
//    }

//    func rejectTrip(completion: FirestoreCompletion) {
//        guard let trip = trip else { return }
//        updateTripState(trip, state: .rejectedByDriver, completion: completion)
//    }
//
//    func didArriveAtPickupLocation(completion: FirestoreCompletion) {
//        guard let trip = trip else { return }
//        updateTripState(trip, state: .driverArrived, completion: completion)
//    }
//
//    func didArriveAtDropffLocation(completion: FirestoreCompletion) {
//        guard let trip = trip else { return }
//        updateTripState(trip, state: .arrivedAtDestination, completion: completion)
//    }
//
//    func pickupPassenger(completion: FirestoreCompletion) {
//        guard let trip = trip else { return }
//        updateTripState(trip, state: .inProgress, completion: completion)
//    }
//
//    func dropoffPassenger(completion: FirestoreCompletion) {
//        guard let trip = trip else { return }
//        updateTripState(trip, state: .complete, completion: completion)
//    }
//}

// MARK: - Passenger API

//extension TripService {
//    //TODO: Refactor passenger api code from HomeViewModel to here
//}
