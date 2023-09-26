//
//  DetailsAddFriendsView.swift
//  FroopProof
//
//  Created by David Reed on 6/21/23.
//

import SwiftUI

struct DetailsAddFriendsView: View {
    
    @ObservedObject var appStateManager = AppStateManager.shared
    @ObservedObject var printControl = PrintControl.shared
    @ObservedObject var froopDataListener = FroopDataListener.shared
    @ObservedObject var myData = MyData.shared
    @ObservedObject var froopManager = FroopManager.shared
    @ObservedObject var friendViewController = FriendViewController.shared
    @ObservedObject var timeZoneManager: TimeZoneManager = TimeZoneManager()
    @ObservedObject var froopData: FroopData = FroopData()
    @ObservedObject var friendData: UserData = UserData()
    
    @Binding var froopAdded: Bool
    @Binding var invitedFriends: [UserData]
    
    var body: some View {
        
        VStack {
            HStack {
                if (FirebaseServices.shared.uid) == froopManager.selectedFroop.froopHost {
                ZStack (alignment: .center) {
                    Rectangle()
                        .foregroundColor(.black)
                        .opacity(0.75)
                        .frame(maxWidth: .infinity, maxHeight: 100)
                        .ignoresSafeArea()
                    
                    
                  
                        Button {
                            PrintControl.shared.printFroopDetails("Adding Friends")
                            froopManager.addFriendsOpen = true
                            PrintControl.shared.printFroopDetails("editing froop details")
                            //froopManager.froopDetailOpen = false
                        } label:{
                            HStack (alignment: .center) {
                                Spacer()
                                Image(systemName: "plus")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.center)
                                    .frame(width: 50, height: 50)
                                    .padding(.bottom, 25)
                                    .padding(.trailing, 0)
                                if invitedFriends.isEmpty {
                                    Text("INVITE PEOPLE")
                                        .font(.system(size: 18, weight: .thin))
                                        .foregroundColor(.white)
                                        .multilineTextAlignment(.center)
                                        .frame(width: 125, height: 50)
                                        .padding(.bottom, 25)
                                } else {
                                    Text("INVITE MORE PEOPLE")
                                        .font(.system(size: 18, weight: .thin))
                                        .foregroundColor(.white)
                                        .multilineTextAlignment(.center)
                                        .frame(width: 175, height: 50)
                                        .padding(.bottom, 25)
                                }
                                Spacer()
                            }
                        }
                }
                } else {
                    Text("")
                }
            }
        }
        .ignoresSafeArea()
    }
}


