//
//  LocationSearchViewModel.swift
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


class LocationSearchViewModel: NSObject, ObservableObject {
    
    @ObservedObject var appStateManager = AppStateManager.shared
    @ObservedObject var printControl = PrintControl.shared
    @ObservedObject var locationServices = LocationServices.shared
    @ObservedObject var froopDataListener = FroopDataListener.shared
    //@ObservedObject var myData: MyData.shared
 
    
    // MARK: - Properties
    @Published var results = [MKLocalSearchCompletion]()
    @Published var selectedFroopLocation = CLLocationCoordinate2D(latitude: 0, longitude: 0)
    @Published var pickupTime: String?
    @Published var dropOffTime: String?
    //@ObservedObject var froopData: FroopData
    
    private let searchCompleter = MKLocalSearchCompleter()
    var queryFragment: String = "" {
        didSet {
            searchCompleter.queryFragment = queryFragment
        }
    }
 
    var userLocation: CLLocationCoordinate2D?
    
    // MARK: Lifecycle
    
    override init() { 
        //self.froopData = froopData
        super.init()
        searchCompleter.delegate = self
        searchCompleter.queryFragment = queryFragment
    }
    
    // MARK: - Helpers
    
    func selectLocation(_ localSearch: MKLocalSearchCompletion, froopData: FroopData) {
        PrintControl.shared.printLocationServices("LocationSearchViewModel: Function: selectLocation is firing!")
        locationSearch(forLocalSearchCompletion: localSearch) { response, error in
            if let error = error {
                PrintControl.shared.printErrorMessages("DEBUG: Location search failed with error \(error.localizedDescription)")
                return
            }

            guard let item = response?.mapItems.first else { return }
            froopData.froopLocationtitle = localSearch.title
            froopData.froopLocationsubtitle = localSearch.subtitle
            froopData.froopLocationCoordinate = item.placemark.coordinate

            PrintControl.shared.printLocationServices("DEBUG: Location Title \(froopData.froopLocationtitle)")
            PrintControl.shared.printLocationServices("DEBUG: Location Subtitle \(froopData.froopLocationsubtitle)")
            PrintControl.shared.printLocationServices("DEBUG: Location coordinates \(froopData.froopLocationCoordinate)")
            PrintControl.shared.printLocationServices("DEBUG: Location ID \(froopData.id)")
            PrintControl.shared.printLocationServices("froopData.id: \(froopData.id)")
        }
    }
    
    func locationSearch(forLocalSearchCompletion localSearch: MKLocalSearchCompletion,
                        completion: @escaping MKLocalSearch.CompletionHandler) {
        PrintControl.shared.printLocationServices("LocationSearchViewModel: Function: locationSearch is firing!")
        let searchRequest = MKLocalSearch.Request()
        searchRequest.naturalLanguageQuery = localSearch.title.appending(localSearch.subtitle)
        let search = MKLocalSearch(request: searchRequest)
        
        search.start(completionHandler: completion)
    }
    
//    func computeRidePrice(forType type: RideType) -> Double {
//            let destCoordinate = selectedFroopLocation.coordinate
//            guard let userCoordinate = self.userLocation else { return 0.0 }
//            print("updating userLocation SIX")
//            let userLocation = CLLocation(latitude: userCoordinate.latitude, longitude: userCoordinate.longitude)
//            let destination = CLLocation(latitude: destCoordinate.latitude, longitude: destCoordinate.longitude)
//        print("updating userLocation SEVEN")
//            let tripDistanceInMeters = userLocation.distance(from: destination)
//            return type.computePrice(for: tripDistanceInMeters)
//        }
    
    func getDestinationRoute(from userLocation: CLLocationCoordinate2D,
                             to destination: CLLocationCoordinate2D, completion: @escaping(MKRoute) -> Void) {
        PrintControl.shared.printLocationServices("LocationSearchViewModel: Function: getDestinationRoute is firing!")
        let userPlacemark = MKPlacemark(coordinate: userLocation)
        let destPlacemark = MKPlacemark(coordinate: destination)
        let request = MKDirections.Request()
        PrintControl.shared.printLocationServices("updating userLocation EIGHT")
        request.source = MKMapItem(placemark: userPlacemark)
        request.destination = MKMapItem(placemark: destPlacemark)
        PrintControl.shared.printLocationServices("updating userLocation NINE")
        let directions = MKDirections(request: request)
        PrintControl.shared.printLocationServices("updating userLocation TEN")
        directions.calculate { response, error in
            if let error = error {
                PrintControl.shared.printLocationServices("DEBUG: Failed to get directions with error \(error.localizedDescription)")
                return
            }
            
            guard let route = response?.routes.first else { return }
            self.configurePickupAndDropoffTimes(with: route.expectedTravelTime)
            completion(route)
        }
    }
    
    func configurePickupAndDropoffTimes(with expectedTravelTime: Double) {
        PrintControl.shared.printLocationServices("LocationSearchViewModel: Function: configurePickupAndDropoffTimes is firing!")
        let formatter = DateFormatter()
        formatter.dateFormat = "hh:mm a"
        
        pickupTime = formatter.string(from: Date())
        dropOffTime = formatter.string(from: Date() + expectedTravelTime)
    }
}

// MARK: - MKLocalSearchCompleterDelegate


