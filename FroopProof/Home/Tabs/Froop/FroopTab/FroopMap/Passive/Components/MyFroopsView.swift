//
//  MyFroopsView.swift
//  FroopProof
//
//  Created by David Reed on 5/18/23.
//

import SwiftUI

struct MyFroopsView: View {
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject var appStateManager = AppStateManager.shared
    @ObservedObject var printControl = PrintControl.shared
    @ObservedObject var locationServices = LocationServices.shared
    @ObservedObject var froopDataListener = FroopDataListener.shared
    @ObservedObject var froopManager = FroopManager.shared
    @ObservedObject var timeZoneManager:TimeZoneManager = TimeZoneManager()
    
    @ObservedObject var myData = MyData.shared
    @ObservedObject var changeView = ChangeView()
    @ObservedObject var froopData = FroopData()
    
    
    @State private var froopFeed: [FroopHostAndFriends] = []
    @State private var walkthroughScreen: NFWalkthroughScreen? = nil
    @State var showSheet = false
    @State var froopAdded = false
    @State var showNFWalkthroughScreen = false
    @State private var currentIndex: Int = 0
    @State private var now = Date()
    @State private var loadIndex = 0
    @State private var isFroopFetchingComplete = false
    @State private var thisFroopType: String = ""
    @State var openFroop: Bool = false

    var heightOfOneCard: CGFloat {
        (UIScreen.main.bounds.width * 1.5) + 150
    }
    
    var estimatedHeightOfLazyVStack: CGFloat {
        CGFloat(sortedFroopsForSelectedFriend.count) * heightOfOneCard + 50.0
    }
    
    var estimatedHeightOfVStack: CGFloat {
        CGFloat(displayedFroops.count) * 100 + 50.0
    }
    
    @ViewBuilder
    var dynamicStack: some View {
        if froopManager.areAllCardsExpanded {
            LazyVStack (alignment: .leading, spacing: 0) {
                stackContent
            }
            .ignoresSafeArea()
            .onAppear {
                print("Number of froops in froopFeed: \(froopManager.froopFeed.count)")
            }
        } else {
            VStack (alignment: .leading, spacing: 0) {
                stackContent
            }
            .ignoresSafeArea()
            .onAppear {
                print("Number of froops in froopFeed: \(froopManager.froopFeed.count)")
            }
        }
    }

    var stackContent: some View {
        ForEach(sortedFroopsForSelectedFriend, id: \.self) { froopHistory in
            MyCardsView(froopHostAndFriends: froopHistory, thisFroopType: thisFroopType)
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        // Increment the current index when a card finishes loading
                        currentIndex += 1
                    }
                }
        }
    }
    
    var displayedFroops: [FroopHistory] {
        return froopManager.froopHistory.filter { froopHistory in
            switch froopHistory.froopStatus {
            case .invited, .confirmed:
                return true
            case .archived:
                return froopHistory.froop.froopHost == uid
            default:
                return false
            }
        }
    }
    
    var filteredFroopsForSelectedFriend: [FroopHistory] {
        return displayedFroops.filter {
            !$0.images.isEmpty &&
            ($0.host.froopUserID == froopManager.myUserData.froopUserID ||
             $0.friends.contains(where: { $0.froopUserID == froopManager.myUserData.froopUserID }))
        }
    }
    
    var sortedFroopsForSelectedFriend: [FroopHistory] {
        return filteredFroopsForSelectedFriend.sorted(by: { $0.froop.froopStartTime > $1.froop.froopStartTime })
    }
    
    var sortedFroopsForUser: [FroopHistory] {
//        froopManager.hostedFroopCount = displayedFroops.count
        return displayedFroops.sorted(by: { $0.froop.froopStartTime > $1.froop.froopStartTime })
    }
    
    
    let hVTimer = Timer.publish(every: 15, on: .main, in: .common).autoconnect()
    
    
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
            .environmentObject(changeView)
            .environmentObject(froopData)
    }
    
    let uid = FirebaseServices.shared.uid
    

    var body: some View {
        ZStack (alignment: .top){
            
            Rectangle()
                .frame(height: 1200)
                .foregroundColor(.white)
                .opacity(0.1)
                .onAppear {
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
                    froopManager.isFroopFetchingComplete = true
                }
            
            if froopManager.areAllCardsExpanded {
                VStack {
                    if froopManager.isFroopFetchingComplete {
                        LazyVStack (alignment: .leading, spacing: 0) {
                            ForEach(sortedFroopsForSelectedFriend, id: \.self) { froopHistory in
                                MyCardsView(froopHostAndFriends: froopHistory, thisFroopType: thisFroopType)
                                    .onAppear {
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                            // Increment the current index when a card finishes loading
                                            currentIndex += 1
                                        }
                                    }
                            }
                        }
                    }
                    Spacer()
                }
                .padding(.bottom, 75)
            } else {
                VStack {
                    if froopManager.isFroopFetchingComplete {
                        VStack (alignment: .leading, spacing: 0) {
                            ForEach(sortedFroopsForUser, id: \.self) { froopHistory in
                                MyMinCardsView(froopHostAndFriends: froopHistory, thisFroopType: thisFroopType)
                                    .onAppear {
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                            // Increment the current index when a card finishes loading
                                            currentIndex += 1
                                        }
                                    }
                            }
                        }
                    }
                    Spacer()
                }
                .padding(.bottom, 75)
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



