//
//  FroopLocationView.swift
//  FroopProof
//
//  Created by David Reed on 1/19/23.
//

import SwiftUI
import SwiftUIBlurView

struct FroopLocationView: View {
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject var printControl = PrintControl.shared
    @ObservedObject var froopDataListener = FroopDataListener.shared
    @ObservedObject var locationManager = LocationManager.shared
    @ObservedObject var locationServices = LocationServices.shared
    @ObservedObject var changeView: ChangeView
    @ObservedObject var froopData: FroopData
    
    @State private var showLocationSearchView = false
    @State private var mapState = MapViewState.searchingForLocation
    @EnvironmentObject var locationViewModel: LocationSearchViewModel
    @Binding var homeViewModel: HomeViewModel
    @ObservedObject var myData = MyData.shared
    @State var showRec = false
    
    
 
    
    var body: some View {
        
        ZStack(alignment: .bottom) {
            ZStack(alignment: .top) {
                FroopMapViewRepresentable(froopData: froopData, mapState: $mapState)
                    .blur(radius: mapState == .searchingForLocation ? 10 : 0)
                    .onAppear {
                        LocationManager.shared.startUpdating()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                           // LocationManager.shared.stopUpdating()
                        }
                    }
                Rectangle()
                    .fill(Color.black)
                    .opacity(showRec ? 0 : 0.6)
                    .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                    .onTapGesture {
                        UIApplication.shared.endEditing()
                    }
                if mapState == .searchingForLocation {
                    
//                    GlobalMapView()
                    LocationSearchView(mapState: $mapState, showLocationSearchView: $showLocationSearchView, showRec: $showRec, froopData: froopData)
            
                } else if mapState == .noInput {
                   Text("")
                        .padding(.top, 88)
                        .onTapGesture {
                            withAnimation(.spring()) {
                                mapState = .searchingForLocation
                                
                            }
                        }
                }
                
            }
            MapViewActionButton(mapState: $mapState)
                .offset(y: -800)
                .padding(.leading)
                .padding(.top, 4)
            
            if mapState == .locationSelected || mapState == .polylineAdded {
                BlurView(style: .light)
                    .frame(height: 450)
                    .edgesIgnoringSafeArea(.bottom)
                FroopLocationConfirmationView(froopData: froopData, changeView: changeView)
                    .transition(.move(edge: .bottom))
                   
            }
            
        }
        .background(mapState == .noInput ? Color.clear : Color("MapOverlay").opacity(1.0))
        .environmentObject(locationViewModel)
        .environmentObject(froopData)
        .environmentObject(homeViewModel)
        .edgesIgnoringSafeArea(.bottom)
        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
        
    }
    
}




