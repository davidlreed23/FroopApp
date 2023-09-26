//
//  ActiveOrPassiveView.swift
//  FroopProof
//
//  Created by David Reed on 5/18/23.
//

import SwiftUI
import Photos
import FirebaseStorage
import Firebase
import FirebaseAuth
import FirebaseFirestore
import Kingfisher
import SwiftUIBlurView
import MapKit
import Combine

struct ActiveOrPassiveView: View {

    @ObservedObject var appStateManager = AppStateManager.shared
    @ObservedObject var printControl = PrintControl.shared
    @ObservedObject var locationServices = LocationServices.shared
    @ObservedObject var froopDataListener = FroopDataListener.shared

    @ObservedObject var myData = MyData.shared
    @ObservedObject var friendData: UserData
    @ObservedObject var froopManager = FroopManager.shared
    @ObservedObject var hostData: UserData = UserData()
    @ObservedObject var timeZoneManager:TimeZoneManager = TimeZoneManager()
    @State private var now = Date()
    @State var showTypeImage: Bool = true
    @State private var isSheetPresented = false
    @State private var myUserData: UserData = UserData()

    var body: some View {
        ZStack {
            ZStack{
                if appStateManager.appState == .active {
                    FroopActiveMapView(froopLocation: AppStateManager.shared.inProgressFroop.froopLocationCoordinate ?? CLLocationCoordinate2D())
                        .onAppear {
                            print("number of active froops: \(AppStateManager.shared.inProgressFroops.count)")
                        }
                } else {
                    FroopPassiveView()
                }
            }
            if appStateManager.shouldPresentFroopSelection {
                VStack{
                    HStack{
                        Spacer()
                        Button(action: {
                            isSheetPresented = true
                        }) {
                            ZStack {
                                Image(systemName: "rectangle.stack.badge.person.crop.fill")
                                    .font(.system(size: 32))
                                    .symbolRenderingMode(.hierarchical)
                                    .foregroundColor(.black)
                                    .opacity(0.6)
                            }
                        }
                       
                        
                        .fullScreenCover(isPresented: $isSheetPresented) {
                            FroopSelectionView()
                        }
                        .padding(.top, 20)
                        .padding(.trailing, 20)
                    }
                    Spacer()
                }
            }
        }
       
    }
}


// A simple list view for selecting a Froop
struct FroopSelectionView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    @ObservedObject var froopDataController = FroopDataController.shared
    @ObservedObject var appStateManager = AppStateManager.shared
    
    var body: some View {
        Rectangle ()
            .background(.ultraThinMaterial)
            .ignoresSafeArea()
        onAppear {
            froopDataController.processPastEvents()
        }
        
        List(appStateManager.inProgressFroops, id: \.id) { froop in
            Button(action: {
                appStateManager.inProgressFroop = froop
                dismiss()
            }) {
                HStack {
                    KFImage(URL(string: appStateManager.inProgressFroop.froopHostPic))
                        .resizable()
                        .frame(width: 35, height: 35)
                        .scaledToFit()
                        .clipShape(Circle())
                    Text(froop.froopName)
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                    
                }
            }
        }
    }
}
