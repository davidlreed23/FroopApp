//
//  FroopDetailsView.swift
//  Design_Layouts
//
//  Created by David Reed on 6/20/23.
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
import FirebaseCrashlytics

struct FroopDetailsView2: View {
    
    @ObservedObject var dataController = DataController.shared
    @ObservedObject var appStateManager = AppStateManager.shared
    @ObservedObject var printControl = PrintControl.shared
    @ObservedObject var locationServices = LocationServices.shared
    @ObservedObject var froopDataListener = FroopDataListener.shared
    @ObservedObject var myData = MyData.shared
    @ObservedObject var froopManager = FroopManager.shared
    @ObservedObject var friendViewController = FriendViewController.shared
    @ObservedObject var timeZoneManager: TimeZoneManager = TimeZoneManager()
    @ObservedObject var froopData: FroopData = FroopData()
    @ObservedObject var friendData: UserData = UserData()

    
    @State var tasks: [FroopTask] = []
    @State var detailGuests: [UserData] = []
    @State private var mapState = MapViewState.locationSelected
    @State private var dataLoaded = false
    @State var messageEdit = false
    @State var taskOn = false
    @State var acceptFraction1 = 1
    @State var acceptFraction2 = 1
    @State private var templateMade: Bool = false
    @State private var friendDetailOpen: Bool = false
    @Binding var detailFroopData: Froop
    @Binding var froopAdded: Bool
    @Binding var invitedFriends: [UserData]
    
    var timestamp: Date = Date()
    
   
    
    var body: some View {
        ZStack (){
            VStack (spacing: 0 ){
                
                DetailsHeaderView()
                   
                
                ScrollView {
                    VStack (spacing: 0){
                        
                        DetailsHostMessageView(messageEdit: $messageEdit)
                        
                        DetailsGuestView()
                        
                        DetailsCalendarView()
                        
                        DetailsMapView()
                        
                        DetailsTasksAndInformationView(taskOn: $taskOn)
                        
                        DetailsDeleteView(froopAdded: $froopAdded)
                            .padding(.bottom, 25)
                        
                        Spacer()
                    }
                }
                DetailsAddFriendsView(froopAdded: $froopAdded, invitedFriends: $invitedFriends)
            }
            
            //MARK: FRIEND DETAIL VIEW OPEN
            .fullScreenCover(isPresented: $friendDetailOpen) {
//                friendListViewOpen = false
            } content: {
                ZStack {
                    VStack {
                        Spacer()
                        UserDetailView2(selectedFriend: $dataController.selectedUser)
    //                        .ignoresSafeArea()
                    }
                    VStack {
                        HStack {
                            Spacer()
                            Image(systemName: "xmark")
                                .font(.system(size: 24))
                                .foregroundColor(.white)
                                .blendMode(.difference)
                                .padding(.trailing, 25)
                                .padding(.top, 20)
                                .onTapGesture {
                                    dataController.allSelected = 0
                                    self.friendDetailOpen = false
                                    print("CLEAR TAP MainFriendView 1")
                                }
                        }
                        .frame(alignment: .trailing)
                        Spacer()
                    }
                }
            }
            
            
            .blurredSheet(.init(.ultraThinMaterial), show: $froopManager.froopMapOpen) {
            } content: {
                ZStack {
                    VStack {
                        Spacer()
                        NonActiveMapView(mapState: $mapState, selectedFroop: $froopManager.selectedFroop, selectedFroopUUID: $froopManager.selectedFroopUUID, froopMapOpen: $froopManager.froopMapOpen)
                    }
                     
                                                  
                    VStack {
                        Rectangle()
                            .foregroundColor(.white)
                            .opacity(0.01)
                            .onTapGesture {
                                mapState = MapViewState.noInput
                                print(froopManager.selectedFroop.froopLocationCoordinate.debugDescription)
                                self.froopManager.froopMapOpen = false
                                print("CLEAR TAP Froop Details View")
                                
                            }
                            .onAppear {
                                mapState = MapViewState.locationSelected
                            }
                            .frame(maxWidth: .infinity, maxHeight: 100)
                            .ignoresSafeArea()
                        //.border(.pink)
                        Spacer()
                    }
                    VStack {
                        Text("tap to close")
                            .font(.system(size: 18))
                            .fontWeight(.light)
                            .foregroundColor(.black)
                            .padding(.top, 25)
                            .opacity(0.5)
                        Image(systemName: "chevron.down")
                            .font(.system(size: 24))
                            .foregroundColor(.black)
                        Spacer()
                    }
                    .frame(alignment: .top)
                }
                .presentationDetents([.large])
            }
            
            .blurredSheet(.init(.ultraThinMaterial), show: $froopManager.addFriendsOpen) {
            } content: {
                ZStack {
                    VStack {
                        Spacer()
                        
                        AddFriendsFroopView(friendData: friendData, friendDetailOpen: $froopManager.friendDetailOpen, invitedFriends: $invitedFriends, selectedFroopUUID: $froopManager.selectedFroopUUID, addFriendsOpen: $froopManager.addFriendsOpen, timestamp: timestamp, detailGuests: $detailGuests)
                    }
                    
                    
                    VStack {
                        Rectangle()
                            .foregroundColor(.white)
                            .opacity(0.01)
                            .onTapGesture {
                                self.froopManager.addFriendsOpen = false
                                print("CLEAR TAP Froop Details View")
                                
                            }
                            .frame(maxWidth: .infinity, maxHeight: 100)
                            .ignoresSafeArea()
                        //.border(.pink)
                        Spacer()
                    }
                    VStack {
                        Text("tap to close")
                            .font(.system(size: 18))
                            .fontWeight(.light)
                            .foregroundColor(.gray)
                            .padding(.top, 25)
                            .opacity(0.5)
                        Image(systemName: "chevron.down")
                            .font(.system(size: 24))
                            .foregroundColor(.gray)
                        Spacer()
                    }
                    .frame(alignment: .top)
                }
                .presentationDetents([.large])
            }
            
            if FirebaseServices.shared.uid == froopManager.selectedFroop.froopHost {
                ZStack {
                    VStack {
                        HStack {
                            Spacer()
                            if templateMade {
                                VStack {
                                    Text("Template")
                                        .font(.system(size: 14))
                                        .fontWeight(.light)
                                        .foregroundColor(.white)
                                    Text("Confirmed")
                                        .font(.system(size: 14))
                                        .fontWeight(.light)
                                        .foregroundColor(.white)
                                }
                                .padding(.top, 150)
                                .padding(.trailing, 25)
                                
                            } else {
                                
                                VStack {
                                    Text(froopManager.selectedFroop.template ? "" : "Create")
                                        .font(.system(size: 14))
                                        .fontWeight(.light)
                                        .foregroundColor(.white)
                                    Text(froopManager.selectedFroop.template ? "" : "Template")
                                        .font(.system(size: 14))
                                        .fontWeight(.light)
                                        .foregroundColor(.white)
                                }
                                .padding(.top, 150)
                                .padding(.trailing, 25)
                                
                            }
                            
                        }
                        Spacer()
                    }
                    .onTapGesture {
                        print("tapped")
                        templateMade = true
                        froopManager.checkAndUpdateTemplateStore { error in
                            if let error = error {
                                print("An error occurred: \(error)")
                            } else {
                                print("Template store updated successfully.")
                            }
                        }
                    }
                }
            } else {
                EmptyView()
            }
            
            FroopTasksView(tasks: tasks, taskOn: $taskOn)
                .opacity(taskOn ? 1.0 : 0.0)
                .animation(.linear(duration: 0.2), value: messageEdit)
            
            DetailsHostMessageEditView(messageEdit: $messageEdit)
                .opacity(messageEdit ? 1.0 : 0.0)
                .animation(.linear(duration: 0.2), value: messageEdit)
        }
        .ignoresSafeArea()
    }
    
    
    
}




