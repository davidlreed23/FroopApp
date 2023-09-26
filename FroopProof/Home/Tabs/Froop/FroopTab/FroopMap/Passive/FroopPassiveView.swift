//
//  FroopPassiveView.swift
//  FroopProof
//
//  Created by David Reed on 5/18/23.
//

import SwiftUI
import UserNotifications
import FirebaseAuth
import FirebaseFirestore


struct FroopPassiveView: View {
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject var appStateManager = AppStateManager.shared
    @ObservedObject var printControl = PrintControl.shared
    @ObservedObject var locationServices = LocationServices.shared
    @ObservedObject var froopDataListener = FroopDataListener.shared
    @ObservedObject var timeZoneManager:TimeZoneManager = TimeZoneManager()
    
    @ObservedObject var myData = MyData.shared
    @ObservedObject var froopManager = FroopManager.shared
    @ObservedObject var changeView = ChangeView()
    @ObservedObject var froopData = FroopData()

    
    @State var selectedFriend: UserData = UserData()
    @State private var walkthroughScreen: NFWalkthroughScreen? = nil
    @State var showSheet = false
    @State var froopAdded = false
    @State var showNFWalkthroughScreen = false
    @State private var sortedIndices: [Int] = []
    @State private var currentIndex: Int = 0
    @State private var now = Date()
    @State private var loadIndex = 0
   

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
    
    var body: some View {
        
        Text(froopManager.froopHistory.count == 0 ? "Your friend's Froops will show up here if they have decided to share them with their community." : "")
            .foregroundColor(colorScheme == .dark ? .white: .black)
            .font(.system(size: 20))
            .fontWeight(.regular)
            .frame(width: 300)
        // .padding(.top, 0)
        
        ZStack (alignment: .top){
            Color.white
            VStack {
                UserDetailView()
                    .ignoresSafeArea()
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


