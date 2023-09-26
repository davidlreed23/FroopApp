//
//  FroopSelectionView.swift
//  FroopProof
//
//  Created by David Reed on 2/7/23.
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import MapKit
import Foundation

struct FroopDeclinedList: View {
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject var appStateManager = AppStateManager.shared
    @ObservedObject var printControl = PrintControl.shared
    @ObservedObject var locationServices = LocationServices.shared
    @ObservedObject var froopDataListener = FroopDataListener.shared
    var db = FirebaseServices.shared.db
    @EnvironmentObject var invitationList: InvitationList
  //  @State var timer: Timer?

    @Binding var froopDetailOpen: Bool
    @ObservedObject var myData = MyData.shared
    @ObservedObject var froopData: FroopData
    @State var refresh = false
    @Binding var selectedFroopUUID: String
    @Binding var froopAdded: Bool
    var timeIntervalUntilStart: TimeInterval {
        return startTime.timeIntervalSinceNow
    }
    var startTime: Date = Date()
    @Binding var invitedFriends: [UserData]
    @Binding var refreshView: Bool
    @State private var previousFroopAdded: Bool = false

    // DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
    
    
    var body: some View {
        ZStack {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .foregroundColor(colorScheme == .dark ? .black: .white)
                    .padding(.leading, 25)
                    .padding(.trailing, 25)
                    .frame(height: 125)
                    .opacity(froopDataListener.myDeclinedList.count == 0 ? 0.75 : 0)
                
                Text(froopDataListener.myDeclinedList.count == 0 ? "If you decline a Froop, you can find them here." : "")
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                    .font(.system(size: 18))
                    .font(.system(size: 18))
                    .fontWeight(.regular)
                    .padding(.leading, 50)
                    .padding(.trailing, 50)
                    .multilineTextAlignment(.center)
                
            }
            .offset(y: -100)
            ScrollView (showsIndicators: false) {
                VStack(spacing: 10) {
                    ForEach(FroopDataListener.shared.myDeclinedList.filter { froop in
                        let endTime = froop.froopStartTime.addingTimeInterval(TimeInterval(froop.froopDuration * 60))
                        return endTime > Date()
                    }
                            
                        .sorted(by: { $0.froopStartTime < $1.froopStartTime })) { result in
                            FroopDeclinedCardView(froopDetailOpen: $froopDetailOpen, froop: result, selectedFroopUUID: $selectedFroopUUID, invitedFriends: $invitedFriends)
                            
                        }
                        .onAppear {
                            print("Selected Froop UID printed from FroopSelectionView ForEachLoop \($selectedFroopUUID)")
                        }
                }
            }
            .onChange(of: froopAdded, initial: previousFroopAdded) { oldValue, newValue in
                if newValue {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        // getData()
                        froopAdded = false
                        PrintControl.shared.printLists("froopAdded: \(froopAdded.description)")
                    }
                }

                // Update the previous value after processing the changes
                previousFroopAdded = newValue
            }

            .padding(.bottom, 35)
            .frame(height: 365)
            .shadow(color: .gray, radius: 2)
            .ignoresSafeArea()
            
            .onAppear {
                if FroopDataListener.shared.myDeclinedList.isEmpty {
                    //                getData()
                } else {
                    PrintControl.shared.printLists("lovely")
                    //getData()
                }
            }
         //   .onDisappear {
                // Stop the timer when the view disappears
         //       timer?.invalidate()
          //      timer = nil
         //   }
        }
    }
}
            
