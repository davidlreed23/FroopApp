
//  ParentView.swift
//  FroopProof
//
//  Created by David Reed on 2/4/23.


import SwiftUI
import UIKit
import FirebaseFirestore
import FirebaseAuth
import Kingfisher
import MapKit
import Foundation


struct ParentView: View {
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var invitationList: InvitationList
    @ObservedObject var myData = MyData.shared
    @ObservedObject var firebaseServices = FirebaseServices.shared
    @ObservedObject var appStateManager = AppStateManager.shared
    @ObservedObject var printControl = PrintControl.shared
    @ObservedObject var locationServices = LocationServices.shared
    @ObservedObject var froopDataListener = FroopDataListener.shared
    @ObservedObject var froopManager = FroopManager.shared
    @ObservedObject var timeZoneManager:TimeZoneManager = TimeZoneManager()
    @ObservedObject var froopData = FroopData()
    @ObservedObject var notificationsManager = NotificationsManager.shared
    
    @State private var now = Date()
    
    @State private var refreshView: Bool = false
    @State var acceptFraction1 = 1
    @State var acceptFraction2 = 1
    @State var froopDetailOpen = false
    @State var showSheet = false
    @State var filteredFroopsCount: Int = 0
    @State var showNFWalkthroughScreen = false
    @State private var walkthroughScreen: NFWalkthroughScreen? = nil
    @State var froops: [Froop] = []
    @State var selectedFroopUUID = FroopManager.shared.selectedFroopUUID
    @State var detailFroopData: Froop
    @State var froopAdded = false
    @State var froopDetailsOpen = FroopManager.shared.froopDetailOpen
    @State var inviteExternalFriendsOpen = false
    @State var invitedFriends: [UserData] = []
    @State private var froopListStatus: FroopListStatus = .confirmed
    
    private let uNC = UserNotificationsController()
    
    let uid = FirebaseServices.shared.uid
    
    
    enum FroopListStatus {
        case invites, confirmed, declined
    }
    
    //let hVTimer = Timer.publish(every: 15, on: .main, in: .common).autoconnect()
    
    
    var timeUntilNextFroop: TimeInterval? {
        let nextFroops = FroopDataListener.shared.myConfirmedList.filter { $0.froopStartTime > now }
        guard let nextFroop = nextFroops.min(by: { $0.froopStartTime < $1.froopStartTime }) else {
            // There are no future Froops, so return nil
            return nil
        }
        return nextFroop.froopStartTime.timeIntervalSince(now)
    }
    
    var countdownText: String {
        if let timeUntilNextFroop = timeUntilNextFroop {
            // Use the formatDuration2 function from the timeZoneManager
            return "Next Froop in: \(timeZoneManager.formatDuration2(durationInMinutes: timeUntilNextFroop))"
        } else {
            if AppStateManager.shared.appState == .active {
                return "Froop In Progress!"
            }
            return "No Froops Scheduled"
        }
    }
    
    
    var walkthroughView: some View {
        walkthroughScreen
            .environmentObject(froopData)
    }
    
    
    
    var body: some View {
        
        
        let _ = Self._printChanges()
        
        NavigationView  {
            ZStack (alignment: .top){
                ZStack (alignment: .top) {
                    VStack{
                        VStack{
                            VStack{
                                Text("\(eveningText()) \(MyData.shared.firstName)")
                                    .font(.system(size: 16))
                                    .foregroundColor(colorScheme == .dark ? .white : .white)
                                    .fontWeight(.light)
                                    .padding(.top, 10)
                                    .padding(.bottom, 1)
                                Text(countdownText)
                                    .onReceive(appStateManager.hVTimer) { _ in
                                        now = Date()
                                        print("Timer fired and updated at \(now)")
                                    }
                                    .font(.system(size: 20))
                                    .foregroundColor(colorScheme == .dark ? .white : .white)
                                    .fontWeight(.medium)
                            }
                            .padding(.bottom, 20)
                            .onAppear {
                                notificationsManager.badgeCounts[.froop] = invitationList.myInvitesList.count
                                FirebaseServices.shared.listenToInvitesList(uid: FirebaseServices.shared.uid) { (invitesList) in
                                    FroopDataListener.shared.myInvitesList = invitesList
                                }
                                FirebaseServices.shared.listenToConfirmedList(uid: FirebaseServices.shared.uid) { (confirmedList) in
                                    FroopDataListener.shared.myConfirmedList = confirmedList
                                    
                                }
                                FirebaseServices.shared.listenToDeclinedList(uid: FirebaseServices.shared.uid) { (declinedList) in
                                    FroopDataListener.shared.myDeclinedList = declinedList
                                }
                                
                                FirebaseServices.requestBadgePermission { granted in
                                    if granted {
                                        print("Badge permission granted")
                                        // You can now update the app's badge number
                                    } else {
                                        print("Badge permission denied")
                                        // The user has denied badge permission, handle accordingly
                                    }
                                }
                                LocationManager.shared.updateUserLocationInFirestore()
                                LocationManager.shared.user2DLocation = LocationManager.shared.getLocation()
                                PrintControl.shared.printLocationServices("user2DLocation: \(String(describing: LocationManager.shared.user2DLocation))")
                                PrintControl.shared.printAppState("Active or Passive? \(AppStateManager.shared.appState)")
                                uNC.requestNotificationPermission()
                                FroopDataController.shared.processPastEvents()
                                let uid = FirebaseServices.shared.uid
                                
                                FroopDataController.shared.loadFroopLists(forUserWithUID: uid) {
                                    FroopDataListener.shared.myConfirmedList = FroopDataController.shared.myConfirmedList
                                    FroopDataListener.shared.myInvitesList = FroopDataController.shared.myInvitesList
                                    FroopDataListener.shared.myDeclinedList = FroopDataController.shared.myDeclinedList
                                    FroopDataListener.shared.myArchivedList = FroopDataController.shared.myArchivedList
                                    
                                    FroopManager.shared.createFroopHistory() { froopHistoryCollection in
                                        DispatchQueue.main.async {
                                            FroopManager.shared.froopHistory = froopHistoryCollection
                                            print("FroopHistory collection updated. Total count: \(FroopManager.shared.froopHistory.count)")
                                        }
                                    }
                                    
                                }
                                
                                if invitationList.myDeclinedList.count > 0 {
                                    appStateManager.selectedTab = 0
                                }
                                
                            }

                            
                            Text("MY FROOPS")
                                .foregroundColor(colorScheme == .dark ? .white : .white)
                                .font(.system(size: 18))
                                .fontWeight(.bold)
                                .padding(.top, 15)
                                .padding(.bottom, 20)
                        }
                        VStack (alignment: .center) {
                            
                            ZStack {
                                RoundedRectangle(cornerRadius: 2, style: .continuous)
                                    .frame(width: appStateManager.selectedTab == 1 ? 125 : appStateManager.selectedTab == 2 ? 125 : 125, height: 30)
                                    .foregroundColor(colorScheme == .dark ? .white : .black)
                                    .opacity(colorScheme == .dark ? 0.2 : 0.05)
                                    .ignoresSafeArea()
                                    .offset(x: appStateManager.selectedTab == 0 ? -140 : appStateManager.selectedTab == 2 ? 140 : 0, y: 0)
                                    .offset(y: -5)
                                    .animation(.linear(duration: 0.2), value: appStateManager.selectedTab)
                                    .padding(.leading, 15)
                                    .padding(.trailing, 15)
                                
                                
                                HStack (alignment: .top){
                                    
                                    ZStack {
                                        HStack {
                                            Text("Scheduled")
                                                .font(.system(size: 16))
                                                .fontWeight(appStateManager.selectedTab == 0 ? .semibold : .medium)
                                                .foregroundColor(appStateManager.selectedTab == 0 ? .green : .primary)
                                                .opacity(1)
                                            
                                            Text("\(invitationList.myInvitesList.count)")
                                                .font(.system(size: 16))
                                                .fontWeight(appStateManager.selectedTab == 0 ? .semibold : .medium)
                                                .foregroundColor(appStateManager.selectedTab == 0 ? .green : .primary)
                                            //
                                        }
                                        .animation(.linear(duration: 0.2), value: appStateManager.selectedTab)
                                        .onTapGesture {
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                                appStateManager.selectedTab = 0
                                                print(appStateManager.selectedTab)
                                                froopListStatus = .invites
                                                froopAdded = true
                                            }
                                            print("Tapped Invites. froopAdded: \(froopAdded), froopListStatus: \(froopListStatus)")
                                        }
                                        
                                    }
                                    .frame(width: 100)
                                    .offset(x: -10)
                                    
                                    
                                    Divider()
                                        .frame(maxHeight: 30)
                                    
                                    ZStack {
                                        
                                        HStack {
                                            Text("I'm Going")
                                                .font(.system(size: 16))
                                                .fontWeight(appStateManager.selectedTab == 1 ? .semibold : .medium)
                                                .foregroundColor(appStateManager.selectedTab == 1 ? Color(red: 249/255, green: 0/255, blue: 98/255) : .primary)
                                                .opacity(1)
                                            
                                            Text( "\(invitationList.myConfirmedList.count)")
                                                .font(.system(size: 16))
                                                .fontWeight(appStateManager.selectedTab == 1 ? .semibold : .medium)
                                                .foregroundColor(appStateManager.selectedTab == 1 ? Color(red: 249/255, green: 0/255, blue: 98/255) : .primary)
                                                .onChange(of: invitationList.myConfirmedList.count) { _ in
                                                    if invitationList.myInvitesList.count == 1 {
                                                        appStateManager.selectedTab = 1
                                                    }
                                                }
                                        }
                                        .animation(.linear(duration: 0.2), value: appStateManager.selectedTab)
                                        .onTapGesture {
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                                appStateManager.selectedTab = 1
                                                print(appStateManager.selectedTab)
                                                froopListStatus = .confirmed
                                                froopAdded = true
                                            }
                                            print("Tapped I'm Going. froopAdded: \(froopAdded), froopListStatus: \(froopListStatus)")
                                        }
                                        
                                    }
                                    .frame(width: 125)
                                    
                                    Divider()
                                        .frame(maxHeight: 30)
                                    
                                    ZStack {
                                        HStack {
                                            Text("Declined")
                                                .font(.system(size: 16))
                                                .fontWeight(appStateManager.selectedTab == 2 ? .semibold : .medium)
                                                .foregroundColor(appStateManager.selectedTab == 2 ? .blue : .primary)
                                                .opacity(1)
                                            
                                            Text("\(invitationList.myDeclinedList.count)")
                                                .font(.system(size: 16))
                                                .fontWeight(appStateManager.selectedTab == 2 ? .semibold : .medium)
                                                .foregroundColor(appStateManager.selectedTab == 2 ? .blue : .primary)
                                        }
                                        .animation(.linear(duration: 0.2), value: appStateManager.selectedTab)
                                        .onTapGesture {
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                                appStateManager.selectedTab = 2
                                                print(appStateManager.selectedTab)
                                                froopListStatus = .declined
                                                froopAdded = true
                                            }
                                            print("Tapped Declined. froopAdded: \(froopAdded), froopListStatus: \(froopListStatus)")
                                        }
                                        
                                    }
                                    .frame(width: 100)
                                    .offset(x: 10)
                                    
                                }
                            }
                            .padding(.leading, 25)
                            .padding(.trailing, 25)
                            
                            GeometryReader { geometry in
                                HStack (spacing: 0){
                                    RoundedRectangle(cornerRadius: 5)
                                        .foregroundColor(.green)
                                        .frame(width: appStateManager.selectedTab == 0 ? geometry.size.width * 0.95 : appStateManager.selectedTab == 2 ? geometry.size.width * 0.0 : geometry.size.width * 0.05, height: 3)
                                        .id("Green")
                                        .ignoresSafeArea()
                                    
                                    RoundedRectangle(cornerRadius: 5)
                                        .foregroundColor(Color(red: 249/255, green: 0/255, blue: 98/255 ))
                                        .frame(width: appStateManager.selectedTab == 1 ? geometry.size.width * 0.90 : geometry.size.width * 0.05, height: 3)
                                        .id("Pink")
                                    
                                    RoundedRectangle(cornerRadius: 5)
                                        .foregroundColor(.blue)
                                        .frame(width: appStateManager.selectedTab == 2 ? geometry.size.width * 0.95 : geometry.size.width * 0.05, height: 3)
                                        .id("Blue")
                                    
                                }
                                .ignoresSafeArea()
                                .animation(.easeInOut(duration: 0.5), value: appStateManager.selectedTab)
                                
                            }
                            .frame(height: 10)
                            .offset(y: -10)
                            
//                            VStack {
//                                TabView(selection: $appStateManager.selectedTab) {
//                                    FroopInvitesList(selectedTab: $appStateManager.selectedTab, froopDetailOpen: $froopDetailOpen, froopData: froopData, selectedFroopUUID: $selectedFroopUUID, froopAdded: $froopAdded, invitedFriends: $invitedFriends, refreshView: $refreshView)
//                                    //.environmentObject(invitationList)
//                                        .tag(0)
//                                    FroopConfirmedList(froopDetailOpen: $froopDetailOpen, froopData: froopData, froopAdded: $froopAdded, invitedFriends: invitedFriends)
//                                        .onAppear {
//                                            appStateManager.selectedTab = 1
//                                            print(appStateManager.selectedTab)
//
//                                        }
//                                    //.environmentObject(invitationList)
//                                        .tag(1)
//                                    FroopDeclinedList(froopDetailOpen: $froopDetailOpen,  froopData: froopData, selectedFroopUUID: $selectedFroopUUID, froopAdded: $froopAdded, invitedFriends: $invitedFriends, refreshView: $refreshView)
//                                    //.environmentObject(invitationList)
//                                        .tag(2)
//                                }
//
//                                .frame(maxHeight: 600)
//                                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
//                                .padding(.leading, 15)
//                                .padding(.trailing, 15)
//                            }
//                            .frame(maxHeight: 600)
                        }
                        
                        
                        .sheet(isPresented: $showNFWalkthroughScreen) {
                            self.walkthroughScreen
                        }
                    }
                    
                    .fullScreenCover(isPresented: $froopManager.froopDetailOpen) {
                    } content: {
                        ZStack (alignment: .top) {
                            
                            VStack {
                                Spacer()
                                switch froopListStatus {
                                    case .invites:
                                        FroopDetailsView2(detailFroopData: $detailFroopData, froopAdded: $froopAdded, invitedFriends: $invitedFriends)
                                        
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
                                        self.froopDetailOpen = false
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
            
        }
        
    }
    
    
    func eveningText () -> String {
        let date = Date()
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        var greeting: String
        if hour < 12 {
            greeting = "Good Morning"
        } else if hour < 17 {
            greeting = "Good Afternoon"
        } else {
            greeting = "Good Evening"
        }
        
        return greeting
    }
    func formatTime(creationTime: Date) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute, .hour, .day]
        formatter.unitsStyle = .abbreviated
        
        let currentTime = Date()
        let timeSinceCreation = currentTime.timeIntervalSince(creationTime)
        
        let formattedTime = formatter.string(from: timeSinceCreation) ?? ""
        
        return formattedTime
    }
}
