//
//  UserDetailView.swift
//  FroopProof
//
//  Created by David Reed on 2/16/23.
//

import SwiftUI
import UserNotifications

struct UserDetailView: View {
    @ObservedObject var dataController = DataController.shared
    @ObservedObject var froopManager = FroopManager.shared
    @ObservedObject var appStateManager = AppStateManager.shared
    @ObservedObject var locationServices = LocationServices.shared
    @ObservedObject var froopListStatus = HomeView2ViewModel()

    @State var showInviteView = false
    @State var profileView: Bool = true
    @State var detailFroopData: Froop = Froop(dictionary: [:])
    @State var selectedFroopUUID = FroopManager.shared.selectedFroopUUID
    @State var froopDetailsOpen = FroopManager.shared.froopDetailOpen
    @State var invitedFriends: [UserData] = []

    @State var froopAdded = false
    
    var body: some View {
        ZStack {
            Color.white
            GeometryReader {
                let size = $0.size
                let safeArea = $0.safeAreaInsets
                
                MyFroopLandingView(size: size, safeArea: safeArea)
                    .ignoresSafeArea()
            }
        }
        .fullScreenCover(isPresented: $froopManager.froopDetailOpen) {
        } content: {
            ZStack (alignment: .top) {
                
                VStack {
                    Spacer()
                    switch froopListStatus.froopListStatus {
                        case .invites:
                            EmptyView()
                            
                        case .confirmed:
                            FroopDetailsView2(detailFroopData: $detailFroopData, froopAdded: $froopAdded, invitedFriends: $invitedFriends)
                            
                        case .declined:
                            FroopDetailsView2(detailFroopData: $detailFroopData, froopAdded: $froopAdded, invitedFriends: $invitedFriends)
                    }
                }
                .ignoresSafeArea()
                
                
                VStack {
                    Rectangle()
                        .foregroundColor(.white)
                        .opacity(0.01)
                        .onTapGesture {
                            self.froopManager.froopDetailOpen = false
                            froopAdded = true
                        }
                        .frame(maxWidth: .infinity, maxHeight: 90)
                        .ignoresSafeArea()
                }
                
                VStack {
                    Text("tap to close")
                        .font(.system(size: 18))
                        .fontWeight(.light)
                        .foregroundColor(.gray)
                        .padding(.top, -10)
                        .opacity(0.5)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 24))
                        .foregroundColor(.gray)
                    Spacer()
                }
                .onTapGesture {
                    if appStateManager.appState == .active && froopManager.comeFrom {
                        froopManager.froopDetailOpen = false
                        locationServices.selectedTab = .froop
                        locationServices.selectedFroopTab = .info
                        froopManager.comeFrom = false
                    } else {
                        froopManager.froopDetailOpen = false
                        froopManager.froopListener?.remove()
                    }
                    
                    
                }
                .frame(alignment: .center)
                .padding(.top, 10)
            }
            .presentationDetents([.large])
        }
    
        .padding(.top, 45)
    }
       
}

