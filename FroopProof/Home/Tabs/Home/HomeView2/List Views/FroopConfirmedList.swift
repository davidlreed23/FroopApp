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
//struct FroopConfirmedList: View {
//    @Environment(\.colorScheme) var colorScheme
//    @ObservedObject var appStateManager = AppStateManager.shared
//    @ObservedObject var printControl = PrintControl.shared
//    @ObservedObject var locationServices = LocationServices.shared
//    @ObservedObject var froopDataListener = FroopDataListener.shared
//    @ObservedObject var myData = MyData.shared
//    @State var selectedFroopUUID = FroopManager.shared.selectedFroopUUID
//    var db = FirebaseServices.shared.db
//    @EnvironmentObject var invitationList: InvitationList
//    @ObservedObject var friendViewController = FriendViewController.shared
//    // @State var timer: Timer?
//
//    @Binding var froopDetailOpen: Bool
//
//    @ObservedObject var froopData: FroopData
//    @State var refresh = false
//    //@Binding var selectedFroopUUID: String
//    @Binding var froopAdded: Bool
//    var timeIntervalUntilStart: TimeInterval {
//        return startTime.timeIntervalSinceNow
//    }
//    var startTime: Date = Date()
//    @State var invitedFriends: [UserData] = []
//    @State private var updateView: Int = 0
//
//    var body: some View {
//        ZStack {
//
//            ZStack {
//                RoundedRectangle(cornerRadius: 10)
//                    .foregroundColor(colorScheme == .dark ? .black: .white)
//                    .padding(.leading, 25)
//                    .padding(.trailing, 25)
//                    .frame(height: 125)
//                    .opacity(froopDataListener.myConfirmedList.count == 0 ? 0.75 : 0)
//
//                Text(froopDataListener.myConfirmedList.count == 0 ? "Froops you accept or create will show up here!" : "")
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
//            ScrollView (showsIndicators: false) {
//                ZStack {
//
//                    VStack(spacing: 10) {
//                        ForEach(froopDataListener.myConfirmedList.filter { froop in
//                            let endTime = froop.froopStartTime.addingTimeInterval(TimeInterval(froop.froopDuration * 60))
//                            return endTime > Date()
//                        }
//
//                            .sorted(by: { $0.froopStartTime < $1.froopStartTime })) { result in
//                                FroopConfirmedCardView(froopDetailOpen: $froopDetailOpen, froop: result, invitedFriends: $invitedFriends)
//
//                            }
//                            .onAppear {
//                                PrintControl.shared.printLists("Selected Froop UID printed from FroopSelectionView ForEachLoop \($selectedFroopUUID)")
//                            }
//                    }
//                }
//            }
//
//            .onChange(of: froopAdded) { _ in
//                if froopAdded {
//                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
//                        PrintControl.shared.printLists("froopAdded: \(froopAdded.description)")
//                    }
//                }
//            }
//            .padding(.top, 10)
//            .padding(.bottom, 40)
//            .frame(maxHeight: 600)
//            .shadow(color: .gray, radius: 2)
//            .ignoresSafeArea()
//        }
//    }
//}
