//
//  DetailsMapViewRepresentable.swift
//  FroopProof
//
//  Created by David Reed on 1/19/23.
//

import SwiftUI
import MapKit
import CoreLocation

struct DetailsMapViewRepresentable: UIViewRepresentable {
    @EnvironmentObject var locationSearchViewModel: LocationSearchViewModel
    @EnvironmentObject var homeViewModel: HomeViewModel
    
    @ObservedObject var appStateManager = AppStateManager.shared
    @ObservedObject var printControl = PrintControl.shared
    @ObservedObject var locationServices = LocationServices.shared
    @ObservedObject var froopDataListener = FroopDataListener.shared
    @ObservedObject var locationManager = LocationManager.shared
    @ObservedObject var froopManager = FroopManager.shared
    
    let mapView = MKMapView()
    
    @Binding var mapState: MapViewState
    @Binding var selectedFroop: Froop
    @Binding var selectedFroopUUID: String
    @Binding var froopMapOpen: Bool
    
    func calculateDistance(to location: Froop) -> Double {
        PrintControl.shared.printLocationServices("-DetailsMapViewRepresentable: Function: calculateDistance is firing!")
        guard let userLocation = locationManager.userLocation else { return 0 }
        let froopLocation = CLLocation(latitude: location.froopLocationCoordinate?.latitude ?? 0.0, longitude: location.froopLocationCoordinate?.longitude ?? 0.0)
        return userLocation.distance(from: froopLocation)
    }
    
    func makeUIView(context: Context) -> some UIView {
        PrintControl.shared.printLocationServices("-FroopMapViewRepresentable: Function: makeUIView is firing!")
        
        let froopDescription = froopManager.selectedFroop.description
        PrintControl.shared.printLocationServices(froopDescription)
        
        let longPressGesture = UILongPressGestureRecognizer(target: context.coordinator, action: #selector(context.coordinator.addAnnotationOnLongPress))
            mapView.addGestureRecognizer(longPressGesture)
        
        mapView.delegate = context.coordinator
        mapView.isRotateEnabled = false
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .none

        if let froopLocation = froopManager.selectedFroop.froopLocationCoordinate {
            let region = MKCoordinateRegion(center: froopLocation, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
            mapView.setRegion(region, animated: false)
        }
        
        PrintControl.shared.printLocationServices("updating userLocation ELEVEN")
        return mapView
    }
    
    func updateUIView(_ uiView: UIViewType, context: Context) {
        PrintControl.shared.printLocationServices("-DetailsMapViewRepresentable: Function: updateUIView is firing!")
        
        if let froopLocation = froopManager.selectedFroop.froopLocationCoordinate {
            let region = MKCoordinateRegion(center: froopLocation, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
            mapView.setRegion(region, animated: true)
        }
        
        switch mapState {
            case .noInput:
                PrintControl.shared.printLocationServices("NO INPUT")
                context.coordinator.clearMapViewAndRecenterOnUserLocation()
                
                break
            case .searchingForLocation:
                PrintControl.shared.printLocationServices("SEARCHING FOR LOCATION")
                break
            case .locationSelected:
                PrintControl.shared.printLocationServices("LOCATION SELECTED")
                if let selectedCoordinate = froopManager.selectedFroop.froopLocationCoordinate {
                    print("Selected Coordinate: \(selectedCoordinate.latitude), \(selectedCoordinate.longitude)")
                    if CLLocationCoordinate2DIsValid(selectedCoordinate) {
                        PrintControl.shared.printLocationServices("DEBUG: Adding stuff to map..")
                        context.coordinator.addAndSelectAnnotation(withCoordinate: selectedCoordinate)
                        context.coordinator.configurePolyline(withDestinationCoordinate: selectedCoordinate)
                    } else {
                        print("Error: Selected coordinate is not valid.")
                    }
                } else {
                    print("Error: No selected coordinate available.")
                }
                break
            case .polylineAdded:
                PrintControl.shared.printMap("POLY LINE ADDED")
                break
            case .tripRequested:
                PrintControl.shared.printMap("TRIP REQUESTED")
                break
            case .tripAccepted:
                PrintControl.shared.printMap("TRIP ACCEPTED")
                break
            case .driverArrived:
                PrintControl.shared.printMap("DRIVER ARRIVED")
                break
            case .tripInProgress:
                PrintControl.shared.printMap("TRIP IN PROGRESS")
                break
            case .arrivedAtDestination:
                PrintControl.shared.printMap("ARRIVED AT DESTINATION")
                break
            case .tripCompleted:
                PrintControl.shared.printMap("TRIP COMPLETED")
                break
            case .tripCancelled:
                PrintControl.shared.printMap("TRIP CANCELLED")
                break
        }
    }
    
    func makeCoordinator() -> DetailsMapCoordinator {
        PrintControl.shared.printLocationServices("-DetailsMapViewRepresentable: Function: makeCoordinator is firing!")
        return DetailsMapCoordinator(parent: self, mapUpdateState: MapUpdateState(), froop: froopManager.selectedFroop, mapView: mapView)
    }
}




struct CustomAnnotation: Codable {
    let id: String
    let title: String
    let latitude: Double
    let longitude: Double
    let description: String
    let owner: String
    let ownerUid: String
    
    // Add any other properties you need
}
