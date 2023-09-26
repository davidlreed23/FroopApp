//
//  ProfileView.swift
//  FroopProof
//
//  Created by David Reed on 8/9/23.
//

import SwiftUI
import Kingfisher
import UIKit
import Combine

struct ProfileView: View {
    @ObservedObject var appStateManager = AppStateManager.shared
    @ObservedObject var dataController = DataController.shared
    @ObservedObject var froopDataListener = FroopDataListener.shared
    @ObservedObject var timeZoneManager: TimeZoneManager = TimeZoneManager()
    @ObservedObject var froopManager = FroopManager.shared
    @ObservedObject var friendStore = FriendStore()
    @ObservedObject var mediaManager = MediaManager()
    @ObservedObject var invitationList: InvitationList = InvitationList(uid: FirebaseServices.shared.uid)
    @ObservedObject var photoData = PhotoData()

    @State var locationSearchViewModel = LocationSearchViewModel()
    @State var areThereFriendRequests: Bool = false
    @State var profileTab: Int = 0
    
    init() {
        UISegmentedControl.appearance().selectedSegmentTintColor = .white
        UISegmentedControl.appearance().setTitleTextAttributes([.foregroundColor: UIColor.black], for: .selected)
        UISegmentedControl.appearance().setTitleTextAttributes([.foregroundColor: UIColor.gray], for: .normal)
    }
    
    var body: some View {
        VStack{
            ZStack (alignment: .top) {
                //                Color.offWhite
                Rectangle()
                    .foregroundColor(.black)
                    .opacity(0.75)
                    .offset(y: 0)
                    .frame(height: 160)
                    .ignoresSafeArea()
                    .onAppear {
                        TimerServices.shared.shouldCallupdateUserLocationInFirestore = false
                        TimerServices.shared.shouldCallAppStateTransition = false
                    }

                Picker("", selection: $profileTab) {
                    Text("My Profile").tag(0)
                    Text("My Friends").tag(1)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.top, 35)
                .padding(.leading, 25)
                .padding(.trailing, 25)
                .frame(height: 50)
                .onChange(of: profileTab) { newValue in
                    if profileTab == 0 {
                        withAnimation {
                            appStateManager.profileToggle = true
                            print(appStateManager.profileToggle)
                        }
                    } else {
                        withAnimation {
                            appStateManager.profileToggle = false
                            print(appStateManager.profileToggle)
                            
                        }
                    }
                }
                if profileTab == 0 {
                    ProfileListView(photoData: photoData)
                        .padding(.top, 160)
                        .ignoresSafeArea()
                } else {
                    MainFriendView(areThereFriendRequests: $areThereFriendRequests, friendInviteData: FriendInviteData(dictionary: [:]), friendStore: friendStore, timestamp: Date())
                        .padding(.top, 160)
                        .ignoresSafeArea()
                }
                
            }

            //            ZStack () {
            //                if appStateManager.profileToggle == true {
            //                  //  ProfileListView(photoData: photoData)
           
            //                } else {
            //                    MainFriendView(areThereFriendRequests: $areThereFriendRequests, friendInviteData: FriendInviteData(dictionary: [:]), friendStore: friendStore, timestamp: Date())
            //                    //                                .environmentObject(locationSearchViewModel)
            //                    //                                .environmentObject(MyData.shared)
            //                    //                                .environmentObject(AppStateManager.shared)
            //                    //                                .environmentObject(FirebaseServices.shared)
            //                    //                                .environmentObject(LocationServices.shared)
            //                    //                                .environmentObject(LocationManager.shared)
            //                    //                                .environmentObject(PrintControl.shared)
            //                    //                                .environmentObject(FroopDataController.shared)
            //                    //                                .environmentObject(timeZoneManager)
            //                    //                                .environmentObject(mediaManager)
            //                    //                                .environmentObject(invitationList)
            //                }
            //
            //            }
            //            }
            
            .navigationTitle(profileTab == 0 ? "Profile" : "Friends")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.black, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        Spacer()
    }
}
