////
////  FroopSelectionView.swift
////  FroopProof
////
////  Created by David Reed on 2/7/23.
////
//
//import SwiftUI
//import FirebaseFirestore
//import FirebaseAuth
//import MapKit
//import Foundation
//
//struct FroopInvitesList: View {
//    @Binding var selectedTab: Int
//    @Environment(\.colorScheme) var colorScheme
//    @ObservedObject var appStateManager = AppStateManager.shared
//    @ObservedObject var printControl = PrintControl.shared
//    @ObservedObject var locationServices = LocationServices.shared
//    @ObservedObject var froopDataListener = FroopDataListener.shared
//    
//    var db = FirebaseServices.shared.db
//    @ObservedObject var alertListenerManager: AlertListenerManager = AlertListenerManager()
//   // @State var timer: Timer?
//    //@Binding var froops: [Froop]
//    @Binding var froopDetailOpen: Bool
//    @ObservedObject var myData = MyData.shared
//    @ObservedObject var froopData: FroopData
//    @State var refresh = false
//    @Binding var selectedFroopUUID: String
//    @Binding var froopAdded: Bool
//    var timeIntervalUntilStart: TimeInterval {
//        return startTime.timeIntervalSinceNow
//    }
//    var startTime: Date = Date()
//    @Binding var invitedFriends: [UserData]
//    @Binding var refreshView: Bool
//    
//    // DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
//    
//    
//    var body: some View {
//        ZStack {
//            ZStack {
//                RoundedRectangle(cornerRadius: 10)
//                    .foregroundColor(colorScheme == .dark ? .black: .white)
//                    .padding(.leading, 25)
//                    .padding(.trailing, 25)
//                    .frame(height: 125)
//                    .opacity(froopDataListener.myInvitesList.count == 0 ? 0.75 : 0)
//                
//                Text(froopDataListener.myInvitesList.count == 0 ? "Your Froop invitations will show up here!" : "")
//                    .foregroundColor(colorScheme == .dark ? .white : .black)
//                    .font(.system(size: 18))
//                    .fontWeight(.regular)
//                    .padding(.leading, 50)
//                    .padding(.trailing, 50)
//                    .multilineTextAlignment(.center)
//                
//            }
//            .offset(y: -100)
//            
//        ScrollView (showsIndicators: false) {
//                VStack(spacing: 10) {
//                    ForEach(FroopDataListener.shared.myInvitesList.filter { froop in
//                        let endTime = froop.froopStartTime.addingTimeInterval(TimeInterval(froop.froopDuration * 60))
//                        return endTime > Date()
//                    }
//                        .sorted(by: { $0.froopStartTime < $1.froopStartTime }), id: \.froopId) { result in
//                            FroopInvitesCardView(selectedTab: $selectedTab, froopDetailOpen: $froopDetailOpen, froop: result, selectedFroopUUID: $selectedFroopUUID, invitedFriends: $invitedFriends)
//                        }
//                        .onAppear {
//                            PrintControl.shared.printLists("Selected Froop UID printed from FroopSelectionView ForEachLoop \($selectedFroopUUID)")
//                        }
//                }
//            }
//            .onChange(of: froopAdded) { _ in
//                if froopAdded {
//                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
//                        //                    getData()
//                        froopAdded = false
//                        PrintControl.shared.printLists("froopAdded: \(froopAdded.description)")
//                    }
//                }
//            }
//            .padding(.bottom, 35)
//            .frame(height: 365)
//            .shadow(color: .gray, radius: 2)
//            .ignoresSafeArea()
//            
//            .onAppear {
//                if FroopDataListener.shared.myInvitesList.isEmpty {
//                    //                getData()
//                    alertListenerManager.listenForFroopInvitations()
//                    alertListenerManager.requestNotificationPermission()
//                } else {
//                    PrintControl.shared.printLists("lovely")
//                    //getData()
//                }
//            }
//           // .onDisappear {
//                // Stop the timer when the view disappears
//              //  timer?.invalidate()
//               // timer = nil
//           // }
//        }
//    }
//}
//
//
