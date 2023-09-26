//
//  HomeViewModel.swift
//  FroopProof
//
//  Created by David Reed on 1/20/23.
//

import Foundation
import CoreLocation
import Firebase
import SwiftUI

class HomeViewModel: ObservableObject {
    @ObservedObject var appStateManager = AppStateManager.shared
    @ObservedObject var printControl = PrintControl.shared
    @ObservedObject var locationServices = LocationServices.shared
    @ObservedObject var froopDataListener = FroopDataListener.shared
    // MARK: - Properties
    
    @Published var drivers = [User]()
//    @Published var trip: Trip?
    @Published var mapState = MapViewState.noInput
    @Published var pickupTime: String?
    @Published var dropOffTime: String?
    @Published var user: User?
    
    
    var didExecuteFetchDrivers = false
    var userLocation: CLLocationCoordinate2D?
    var selectedLocation: FroopData = FroopData()
    
    private let radius: Double = 50 * 1000
    private var driverQueue = [User]()
//    private var tripService = TripService()
    private var ridePrice = 0.0
    private var listenersDictionary = [String: ListenerRegistration]()
    private var tripDistanceInMeters = 0.0
    private var selectedFroopType: RideType = .setFroopLocation
}
