//
//  TripLocationsView.swift
//  FroopProof
//
//  Created by David Reed on 1/20/23.
//

import SwiftUI
import CoreLocation
import MapKit

struct TripLocationsView: View {
    
    
    
    @ObservedObject var printControl = PrintControl.shared
    @ObservedObject var locationManager = LocationManager.shared
    @ObservedObject var froopDataListener = FroopDataListener.shared
    @ObservedObject var froopData: FroopData
    @EnvironmentObject var viewModel: LocationSearchViewModel
    
    
    var distance: Double {
        guard let userLocation = LocationManager.shared.userLocation else { return 0 }
        let userCoordinate = CLLocation(latitude: userLocation.coordinate.latitude, longitude: userLocation.coordinate.longitude)
        let location = CLLocation(latitude: froopData.froopLocationCoordinate.latitude, longitude: froopData.froopLocationCoordinate.longitude)
        let distanceInMeters = userCoordinate.distance(from: location)
        return distanceInMeters
    }
    var distanceInKm: Double {
        return distance / 1000
    }
    
    var body: some View {
        HStack(alignment: .center, spacing: 24) {
            VStack {
                
                Rectangle()
                   
                    .foregroundColor(.primary)
                    .frame(width: 8, height: 8)
//                    .blendMode(.difference)
                
                Rectangle()
//                    .blendMode(.difference)
                    .frame(width: 1, height: 125)
                    .foregroundColor(.primary)
                
                Circle()
//                    .blendMode(.difference)
                    .frame(width: 8, height: 8)
                    .foregroundColor(.primary)
                
            }
            
            .offset(y: -35)
            //.padding(.top, 10)
            
            VStack(alignment: .leading) {
                
                Text(froopData.froopLocationtitle)
                    .font(.system(size: 18, weight: .bold))
//                    .blendMode(.difference)
                    .foregroundColor(.primary)
                    .padding(.bottom, 2)
                
                Text(froopData.froopLocationsubtitle)
                    .font(.system(size: 18, weight: .light))
                    .foregroundColor(.primary)
//                    .blendMode(.difference)
                    .lineLimit(2, reservesSpace: true)
                    .padding(.bottom, 10)
                
                Text("Distance: \(String(format: "%.2f", calculateDistance() / 1609.34)) Miles from:")
                    .font(.system(size: 20, weight: .thin))
//                    .blendMode(.difference)
                    .foregroundColor(.primary)
                //.padding(.top, 15)
                
                HStack {
                    Text("Can Arrive at:")
                        .font(.system(size: 14, weight: .semibold))
//                        .blendMode(.difference)
                        .foregroundColor(.primary)
                        .padding(.trailing, 2)
                    
                    Text(viewModel.dropOffTime ?? "..." )
                        .font(.system(size: 14, weight: .semibold))
//                        .blendMode(.difference)
                        .foregroundColor(.primary)
                }
                
                Text("Current Location")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.primary)
//                    .blendMode(.difference)
                    .padding(.top, 15)
                    .padding(.bottom, 2)
                
                Text(LocationManager.shared.userLocationAddress ?? "...")
                    .font(.system(size: 18, weight: .light))
//                    .blendMode(.difference)
                    .foregroundColor(.primary)
                    .lineLimit(2, reservesSpace: true)
                
                
              
            }
        }
        .padding(.top, 16)
        .padding(.leading, 8)
    }
    func calculateDistance() -> Double {
        print("-TripLocationView: Function: calculateDistance is firing!")
        guard let userLocation = LocationManager.shared.userLocation, froopData.froopLocationCoordinate.latitude != 0, froopData.froopLocationCoordinate.longitude != 0 else { return 0 }
        let userCoordinate = CLLocation(latitude: userLocation.coordinate.latitude, longitude: userLocation.coordinate.longitude)
        let location = CLLocation(latitude: froopData.froopLocationCoordinate.latitude, longitude: froopData.froopLocationCoordinate.longitude)
        let distanceInMeters = userCoordinate.distance(from: location)
        return distanceInMeters
    }
}
