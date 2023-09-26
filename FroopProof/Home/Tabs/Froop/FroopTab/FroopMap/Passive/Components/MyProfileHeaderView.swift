//
//  MyProfileHeaderView.swift
//  FroopProof
//
//  Created by David Reed on 8/9/23.
//

import SwiftUI
import Kingfisher
import UIKit
import Combine

struct MyProfileHeaderView: View {
    @ObservedObject var appStateManager = AppStateManager.shared
    @ObservedObject var dataController = DataController.shared
    @ObservedObject var froopDataListener = FroopDataListener.shared
    @ObservedObject var timeZoneManager: TimeZoneManager = TimeZoneManager()
    @ObservedObject var froopManager = FroopManager.shared
    @State var showNFWalkthroughScreen = false
    @State var froopAdded = false
    @State private var walkthroughScreen: NFWalkthroughScreen? = nil


    var size: CGSize
    var safeArea: EdgeInsets
    @State private var now = Date()
    
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
    
    //let hVTimer = Timer.publish(every: 15, on: .main, in: .common).autoconnect()
    
    private var headerHeight: CGFloat {
        (size.height * 0.382) + safeArea.top
    }
    
    private var headerWidth: CGFloat {
        (size.width * 1)
    }
    
    private var minimumHeaderHeight: CGFloat {
        (size.height * 0.1618)
    }
    
    private var minimumHeaderWidth: CGFloat {
        size.width
    }
    
    private var progress: CGFloat {
        max(min(-dataController.offsetY / (headerHeight - minimumHeaderHeight), 1), 0)
    }
    
    
    
    init(size: CGSize, safeArea: EdgeInsets) {
        self.size = size
        self.safeArea = safeArea
        
        UISegmentedControl.appearance().selectedSegmentTintColor = .white
        UISegmentedControl.appearance().setTitleTextAttributes([.foregroundColor: UIColor.black], for: .selected)
        UISegmentedControl.appearance().setTitleTextAttributes([.foregroundColor: UIColor.gray], for: .normal)
    }
    
    var body: some View {
        ZStack {
            GeometryReader { _ in
                ZStack {
                    Color.offWhite
                    
                    Rectangle()
                        .frame(minWidth: 0,maxWidth: .infinity, minHeight: headerHeight, maxHeight: headerHeight, alignment: .top)
                        .foregroundColor(.black)
                        .opacity(0.75)
                        .offset(y: 0)
                        .padding(.top, 20)
                        .onTapGesture {
                            print(MyData.shared)
                        }
                    
                    VStack(alignment: .center) {
                        
                        HStack (alignment: .top){
                            
                            Spacer()
                            
                            VStack{
                                Text("\(eveningText()) \(MyData.shared.firstName)")
                                    .font(.system(size: 16))
                                    .foregroundColor(.white)
                                    .fontWeight(.light)
                                    .padding(.top, 10)
                                    .padding(.bottom, 1)
                                Text(countdownText)
                                    .onReceive(appStateManager.hVTimer) { _ in
                                        now = Date()
                                        print("Timer fired and updated at \(now)")
                                    }
                                    .font(.system(size: 20))
                                    .foregroundColor(.white)
                                    .fontWeight(.medium)
                            }
                            
                            Spacer()
                        }
                        .offset(y: -35)
                    }
                    
                    ZStack {
                        VStack {
                            Spacer()
                            Rectangle()
                                .fill(Color.white)
                                .frame(height: 125)
                                .ignoresSafeArea()
                                .opacity(1.0 * (1 - progress))
                        }
                        VStack {
                            Spacer()
                            HStack(alignment: .center) {
                                Text("CREATE")
                                    .font(.system(size: 18))
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .opacity(0.15)
                                
                                ZStack(alignment: .center) {
                                    
                                    Circle()
                                        .frame(minWidth: 70,maxWidth: 70, minHeight: 75, maxHeight: 75, alignment: .center)
                                        .foregroundColor(.white)
                                        .opacity(1)

                                    
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 60))
                                        .fontWeight(.thin)
                                        .foregroundColor(.black)
                                    
                                }
                                .myMoveMenu(progress, headerHeight, minimumHeaderHeight, headerWidth, minimumHeaderWidth)
                                .onTapGesture {
                                    appStateManager.froopIsEditing = false
                                    TimerServices.shared.shouldCallupdateUserLocationInFirestore = false
                                    TimerServices.shared.shouldCallAppStateTransition = false
                                    LocationManager.shared.requestAlwaysAuthorization()
//                                    self.showSheet = false  // Dismiss the blurred sheet
                                    ChangeView.shared.pageNumber = 1
                                    self.walkthroughScreen = NFWalkthroughScreen(froopData: FroopData(), showNFWalkthroughScreen: $showNFWalkthroughScreen, froopAdded: $froopAdded)
                                    self.showNFWalkthroughScreen = true
                                }
                                
                                Text("FROOP")
                                    .font(.system(size: 18))
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .opacity(0.15)
                            }
                            .offset(y: -100)
                        }
            
                        VStack {
                            Spacer()
                            Text(appStateManager.selectedTabTwo == 0 ? "Froops You have Attended" : "Manage Your Froops")
                                .font(.system(size: 16))
                                .fontWeight(.regular)
                                .foregroundColor(.black)
                                .opacity(0.75)
                                .multilineTextAlignment(.center)
                            
                            Picker("", selection: $appStateManager.selectedTabTwo) {
                                Text("All Froops").tag(0)
                                Text("My Froops").tag(1)
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            .padding(.leading, 10 + (75 * progress))
                            .padding(.trailing, 10 + (75 * progress))
                            .frame(height: 50)
                            .onChange(of: appStateManager.selectedTabTwo, initial: (appStateManager.selectedTabTwo != 0)) { oldValue, newValue in
                                if newValue == 0 {
                                    withAnimation {
                                        froopManager.areAllCardsExpanded = true
                                    }
                                } else {
                                    withAnimation {
                                        froopManager.areAllCardsExpanded = false
                                    }
                                }
                                print("CardsExpanded \(froopManager.areAllCardsExpanded)")
                            }
                            .myMoveMenu(progress, headerHeight, minimumHeaderHeight, headerWidth, minimumHeaderWidth)
                        }
                    }
                    
                }
                .frame(height: (headerHeight + dataController.offsetY) < minimumHeaderHeight ? minimumHeaderHeight : (headerHeight + dataController.offsetY), alignment: .bottom)
                .offset(y: -dataController.offsetY)
                .sheet(isPresented: $showNFWalkthroughScreen) {
                    self.walkthroughScreen
                }
            }
            .frame(height: headerHeight)
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
    
}

struct MyProfileImage: View {
    var progress: CGFloat
    var headerHeight: CGFloat
    @ObservedObject var froopManager = FroopManager.shared
    
    var body: some View {
        GeometryReader {
            let rect = $0.frame(in: .global)
            let halfScaledHeight = (rect.height * 0.4) * 0.5
            //            let halfScaledWidth = (rect.width * 0.4) * 0.5
            let midY = rect.midY - rect.height / 2
            //            let midX = rect.midX - rect.width / 2
            let bottomPadding: CGFloat = 0
            //            let leadingPadding: CGFloat = 0
            let minimumHeaderHeight = 50
            //            let minimumHeaderWidth = 50
            let resizedOffsetY = (midY - (CGFloat(minimumHeaderHeight) - halfScaledHeight - bottomPadding))
            //            let resizedOffsetX = (midX - (CGFloat(minimumHeaderWidth) - halfScaledWidth - leadingPadding))
            
            HStack {
                Spacer()
                ZStack (alignment: .center){
                    Circle()
                        .aspectRatio(contentMode: .fit)
                        .offset(y: -resizedOffsetY * progress)
                    Image(systemName: "plus")
                        .foregroundColor(.white)
                        .font(.system(size: 30))
                        .fontWeight(.thin)
                        .offset(y: -resizedOffsetY * progress)
                }
                .frame(width: rect.width * 0.5, height: rect.height * 0.5)
                .scaleEffect(1 - (progress * 0.6), anchor: .center)
                
                Spacer()
                
            }
            .frame(width: headerHeight * 0.35, height: headerHeight * 0.35)
        }
    }
    
    
}

