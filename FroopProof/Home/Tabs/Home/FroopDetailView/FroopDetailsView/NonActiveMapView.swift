//
//  NonActiveMapView.swift
//  FroopProof
//
//  Created by David Reed on 8/16/23.
//

import Combine
import SwiftUI
import MapKit
import FirebaseFirestore
import Kingfisher
import CoreLocation
import SwiftUIBlurView



struct NonActiveMapView: View {
    
    @EnvironmentObject var locationSearchViewModel: LocationSearchViewModel
    @EnvironmentObject var homeViewModel: HomeViewModel
    
    @ObservedObject var appStateManager = AppStateManager.shared
    @ObservedObject var printControl = PrintControl.shared
    @ObservedObject var locationServices = LocationServices.shared
    @ObservedObject var froopDataListener = FroopDataListener.shared
    @ObservedObject var locationManager = LocationManager.shared
    @ObservedObject var froopManager = FroopManager.shared
    
    @Binding var mapState: MapViewState
    @Binding var selectedFroop: Froop
    @Binding var selectedFroopUUID: String
    @Binding var froopMapOpen: Bool
    
    var body: some View {
        ZStack {
            DetailsMapViewRepresentable(mapState: $mapState, selectedFroop: $froopManager.selectedFroop, selectedFroopUUID: $froopManager.selectedFroopUUID, froopMapOpen: $froopManager.froopMapOpen)
            
            HStack {
                Spacer()
                VStack (alignment: .trailing, spacing: 15) {

                        Button(action: {
                            let latitude: Double = selectedFroop.froopLocationCoordinate?.latitude ?? 0.0
                            let longitude: Double = selectedFroop.froopLocationCoordinate?.longitude ?? 0.0
                            
                            // Check if Waze is installed
                            if UIApplication.shared.canOpenURL(URL(string: "waze://")!) {
                                // Waze is installed. Launch Waze and start navigation
                                let urlStr = String(format: "waze://?ll=%f,%f&navigate=yes", latitude, longitude)
                                UIApplication.shared.open(URL(string: urlStr)!)
                            } else {
                                // Waze is not installed. Launch AppStore to install Waze app
                                UIApplication.shared.open(URL(string: "http://itunes.apple.com/us/app/id323229106")!)
                            }
                        }) {
                            Image("wazeLogo")
                                .resizable()
                                .scaledToFit()
                                .frame(minWidth: 60, maxWidth:60)
                                .padding(.bottom, 15)
                        }
                        .padding(.trailing, 15)
                        .padding(.top, 15)
                    
                    Spacer()
                }
               
            }
        }
    }
}
