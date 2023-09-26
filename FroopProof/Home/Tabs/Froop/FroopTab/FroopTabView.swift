//
//  FroopTabView.swift
//  FroopProof
//
//  Created by David Reed on 5/5/23.
//

import SwiftUI
import SwiftUIBlurView
import Kingfisher
import Firebase
import FirebaseAuth
import FirebaseFirestore
import Foundation
import MapKit
import EventKit

enum FroopTab: Int {
    case info = 1
    case map = 2
    case messages = 3
    case media = 4
}

struct FroopTabView: View {

    @ObservedObject var printControl = PrintControl.shared
    @ObservedObject var appStateManager = AppStateManager.shared
    @ObservedObject var froopDataListener = FroopDataListener.shared
    @ObservedObject var locationManager = LocationManager.shared
    @ObservedObject var notificationsManager = NotificationsManager.shared
    
    @ObservedObject var friendData: UserData
    @ObservedObject var myData = MyData.shared
    @ObservedObject private var viewModel: ImageGridViewModel
   
    @ObservedObject var froopManager = FroopManager.shared
    @Binding var uploadedImages: [ImageItem]
    @State private var showFroopInfoView = false
    @State private var showFroopMapView = false
    @State private var showFroopMessagesView = false
    @State private var showFroopMediaView = false
    @State private var showPhotoLibrary = false
    @State private var froopLocation: CLLocationCoordinate2D = CLLocationCoordinate2D()
    @State private var guestLocatinos: [GuestLocation] = []
    @State private var currentGuestLocations: [GuestLocation] = []
    @State var detailGuests: [UserData] = []
    @State var froopLatitude: Double = 0.0
    @State var froopLongitude: Double = 0.0
    @Binding var froopTabPosition: Int
    @State private var currentTab: FroopTab = .info
    
    @State private var internalRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 39.50, longitude: -98.35),
        span: MKCoordinateSpan(latitudeDelta: 0.2, longitudeDelta: 0.2)
    )
    
    
    
    var guestLocations: [GuestLocation] {
        return detailGuests.map { friendData in
            let userCoordinate = LocationManager.shared.userLocation?.coordinate ?? CLLocationCoordinate2D()
            
            
            return GuestLocation(
                location: userCoordinate,
                profileImageUrl: friendData.profileImageUrl,
                name: "\(friendData.firstName) \(friendData.lastName)",
                froopUserID: friendData.froopUserID,
                phoneNumber: friendData.phoneNumber,
                currentDistance: nil,
                etaToFroop: nil
            )
        }
    }
    
    private var thisFroop: Froop
    
    public init(friendData: UserData, viewModel: ImageGridViewModel, uploadedImages: Binding<[ImageItem]>, thisFroop: Froop, froopTabPosition: Binding <Int>) {
        self.friendData = friendData
        _viewModel = ObservedObject(wrappedValue: viewModel)
        _uploadedImages = uploadedImages
        self.thisFroop = thisFroop
        _froopTabPosition = froopTabPosition
    }
    //@State var showTypeImage: Bool = true
    
    
    var body: some View {
        NavigationView  {
            ZStack (alignment: .top){
                ZStack (alignment: .top) {
//                    FTVBackGroundComponent()
                    
                    ZStack {
                        switch LocationServices.shared.selectedFroopTab {
                            case .info:
                                FroopInfoView()
                            case .map:
                                ActiveOrPassiveView(friendData: friendData)
                            case .messages:
                                FroopMessagesView()
                            case .media:
                                FroopMediaShareView(uploadedImages: $uploadedImages)
                        }
                        
                        VStack {
                            Spacer()
                            ZStack {
                                RoundedRectangle(cornerRadius: 25)
                                    .foregroundColor(.black)
                                    .frame(height: AppStateManager.shared.appState == .active ? 50 : 0)
                                    .opacity(0.25)
                                    .ignoresSafeArea()
                                
                                HStack (spacing: 35){
                                    tabButton(title: "info.square.fill", tab: .info)
                                    tabButton(title: "map.fill", tab: .map)
                                    tabButton(title: "message.fill", tab: .messages)
                                    tabButton(title: "square.grid.2x2.fill", tab: .media)
                                }
                            }
                            .padding(.leading, 30)
                            .padding(.trailing, 30)
                            .offset(y: appStateManager.isFroopTabUp ? 0 : 175)
                            .animation(.easeInOut(duration: 0.3), value: appStateManager.isFroopTabUp)
                        }
                        .padding(.bottom, 65)
                    }
                }
            }
           
        }
    }
    
    
    @ViewBuilder
    private func tabButton(title: String, tab: FroopTab) -> some View {
        Button(action: {
            if AppStateManager.shared.appState != .passive {
                LocationServices.shared.selectedFroopTab = tab
            }
        }) {
            Image(systemName: title)
                .font(.system(size: 30))
                .foregroundColor(LocationServices.shared.selectedFroopTab == tab ? Color(red: 249/255, green: 0/255, blue: 95/255) : .white)
                .fontWeight(.semibold)
                .opacity(AppStateManager.shared.appState == .active ? 1.0 : 0.0)
        }
    }
}
