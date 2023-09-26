//
//  FriendFroopsView.swift
//  FroopProof
//
//  Created by David Reed on 5/18/23.
//

import SwiftUI

struct FriendFroopsView: View {
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject var appStateManager = AppStateManager.shared
    @ObservedObject var printControl = PrintControl.shared
    @ObservedObject var locationServices = LocationServices.shared
    @ObservedObject var froopDataListener = FroopDataListener.shared
    @ObservedObject var froopManager = FroopManager.shared
    @ObservedObject var timeZoneManager:TimeZoneManager = TimeZoneManager()
    @Binding var selectedFriend: UserData

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
    
    var filteredFroopsForSelectedFriend: [FroopHistory] {
        let currentUserId = FirebaseServices.shared.uid // Fetch current user's UID
        
        return froopManager.froopHistory.filter {
            !$0.images.isEmpty &&
            $0.friends.contains(where: { $0.froopUserID == currentUserId }) &&
            $0.friends.contains(where: { $0.froopUserID == selectedFriend.froopUserID })
        }
    }
    
    var sortedFroopsForSelectedFriend: [FroopHistory] {
        return filteredFroopsForSelectedFriend.sorted(by: { $0.froop.froopStartTime > $1.froop.froopStartTime })
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
            .environmentObject(changeView)
            .environmentObject(froopData)
    }
    
    var sortedIndices: [Int] {
        return froopManager.froopFeed.indices.sorted(by: { froopManager.froopFeed[$0].FH.froop.froopStartTime > froopManager.froopFeed[$1].FH.froop.froopStartTime })
    }

    
    init(selectedFriend: Binding<UserData>) {
        _selectedFriend = selectedFriend
        froopManager.fetchFroopData(fuid: selectedFriend.wrappedValue.froopUserID)
    }
    
    var body: some View {
        ZStack (alignment: .top){
                Rectangle()
                    .frame(height: 1200)
                    .foregroundColor(.white)
                    .opacity(0.001)
            if sortedFroopsForSelectedFriend.count == 0 {
                Text(froopManager.froopHistory.isEmpty ? "Your friend's Froops will show up here if they have decided to share them with their community." : "")
                    .foregroundColor(colorScheme == .dark ? .white: .black)
                    .font(.system(size: 20))
                    .fontWeight(.regular)
                    .frame(width: 300)
                // .padding(.top, 0)
                    .padding(.leading, 5)
                    .padding(.trailing, 5)
            } else {
                VStack {
                    LazyVStack (alignment: .leading, spacing: 0) {
                        ForEach(sortedFroopsForSelectedFriend.indices.filter { sortedFroopsForSelectedFriend[$0].host.froopUserID == selectedFriend.froopUserID }, id: \.self) { index in
                            let froopHistory = sortedFroopsForSelectedFriend[index]
                            CardsView(index: index, froopHostAndFriends: froopHistory)
                                .onAppear {
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                        // Increment the current index when a card finishes loading
                                        currentIndex += 1
                                    }
                                }
                        }
                    }
                    .ignoresSafeArea()
                    .onAppear {
                        print("Number of froops in froopFeed: \(froopManager.froopHistory.count)")
                    }
                    Spacer()
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



