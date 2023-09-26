//
//  FroopMessagesView.swift
//  FroopProof
//
//  Created by David Reed on 5/8/23.
//

import SwiftUI
import Photos
import FirebaseStorage
import Firebase
import FirebaseAuth
import FirebaseFirestore
import Kingfisher
import SwiftUIBlurView

struct FroopMessagesView: View {
    @ObservedObject var appStateManager = AppStateManager.shared
    @ObservedObject var printControl = PrintControl.shared
    @ObservedObject var locationServices = LocationServices.shared
    @ObservedObject var froopDataListener = FroopDataListener.shared
    @ObservedObject var locationManager = LocationManager.shared

    var body: some View {
        VStack {
            List(locationManager.locations, id: \.count) { location in
                HStack {
                    Text("\(location.count)")
                    Text("\(location.latitude)")
                    Text("\(location.longitude)")
                }
            }
            Rectangle()
                .foregroundColor(.clear)
                .background(.ultraThinMaterial)
                .ignoresSafeArea()
                .onTapGesture {
                    locationManager.startUpdating()
                }
        }
//        .onReceive(locationManager.$userLocation) { newLocation in
//            guard let newLocation = newLocation else { return }
//            locationManager.locationCount += 1
//            locationManager.locations.append((count: locationManager.locationCount, latitude: newLocation.coordinate.latitude, longitude: newLocation.coordinate.longitude))
//        }
    }
}
