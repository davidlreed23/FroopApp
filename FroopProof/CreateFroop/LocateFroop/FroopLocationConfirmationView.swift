//
//  RideRequestView.swift
//  FroopProof
//
//  Created by David Reed on 1/19/23.
//

import SwiftUI
import MapKit

struct FroopLocationConfirmationView: View {
    
    
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject var printControl = PrintControl.shared
    @ObservedObject var locationManager = LocationManager.shared
    @ObservedObject var froopDataListener = FroopDataListener.shared
    @ObservedObject var appStateManager = AppStateManager.shared

    @ObservedObject var froopData: FroopData
    @ObservedObject var myData = MyData.shared
    @EnvironmentObject var viewModel: LocationSearchViewModel
    @State var selectedRideType: RideType = .setFroopLocation
    @ObservedObject var changeView: ChangeView

    
    var body: some View {
        
        VStack {
            Capsule()
                .foregroundColor(Color(.white))
                .frame(width: 48, height: 6)
                .padding(8)
            
            VStack {
                Button(action: {
                    PrintControl.shared.printLocationServices("froopData.id: \(froopData.id)")
                    PrintControl.shared.printLocationServices("self.froopData.id: \(self.froopData.id)")
                    PrintControl.shared.printLocationServices(froopData.froopLocationtitle)
                    PrintControl.shared.printLocationServices(froopData.froopLocationsubtitle)
                    PrintControl.shared.printLocationServices("Froop Location Coordinate - Latitude: \(froopData.froopLocationCoordinate.latitude), Longitude: \(froopData.froopLocationCoordinate.longitude)")
                    
                    PrintControl.shared.printLocationServices(froopData.froopName)
                    PrintControl.shared.printLocationServices(froopData.froopType.description)
                    if appStateManager.froopIsEditing {
                        changeView.pageNumber = 5
                    } else {
                        changeView.pageNumber += 1
                    }
                    
                }) {
                    Text("Confirm!")
                        .font(.system(size: 48, weight: .thin))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                }
                .frame(width: 250, height: 60)
                .border(Color.gray, width: 1)
                .padding(.top)
                .onAppear {
                    LocationManager.shared.stopUpdating()
                }
            }
            
            VStack(alignment: .leading, spacing: 24) {
                TripLocationsView(froopData: froopData)
                    .padding(.horizontal)
            }
            .padding(.top)
            
            VStack(alignment:.center) {
               
 
                Spacer()
            }
            Spacer()
        }
        
        .background(ColorTheme.mapOverlayColor)
        .opacity(1)
        .frame(height: 450)
    }
}




