//
//  FriendCardView.swift
//  FroopProof
//
//  Created by David Reed on 2/13/23.
//
import SwiftUI
import UIKit
import Kingfisher

struct FriendCardView: View {
    
    
    @ObservedObject var appStateManager = AppStateManager.shared
    @ObservedObject var printControl = PrintControl.shared
    @ObservedObject var locationServices = LocationServices.shared
    @ObservedObject var froopDataListener = FroopDataListener.shared
 
    @Binding var selectedFriend: UserData
    @Binding var friendDetailOpen: Bool
    var friend: UserData
    
    var body: some View {
        VStack (spacing: 0) {
            KFImage(URL(string: friend.profileImageUrl))
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 90, height: 90)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.gray, lineWidth: 0))
            
            Text("\(friend.firstName) \(String(friend.lastName.prefix(1))).")
                .font(.body)
                .fontWeight(.light)
                .foregroundColor(.black)
                .padding(2)
        }
        .frame(width: 125, height: 125)
        .cornerRadius(10)
        .padding(.top, 5)
        .gesture(
                    TapGesture()
                        .onEnded {
                            friendDetailOpen = true
                            selectedFriend = friend
                            print("\(friend.firstName) says he was tapped!")
                        }
                )
    }
}
