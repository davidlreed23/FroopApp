//
//  FriendOfFriendCardView.swift
//  FroopProof
//
//  Created by David Reed on 8/14/23.
//

import SwiftUI
import UIKit
import Kingfisher

struct FriendOfFriendCardView: View {
    
    @ObservedObject var dataController = DataController.shared
    @ObservedObject var appStateManager = AppStateManager.shared
    @ObservedObject var printControl = PrintControl.shared
    @ObservedObject var locationServices = LocationServices.shared
    @ObservedObject var froopDataListener = FroopDataListener.shared
    @State private var selected: Bool = false
    
    @Binding var selectedFriend: UserData
    var friend: UserData
    
    var body: some View {
        VStack (spacing: 0) {
            KFImage(URL(string: friend.profileImageUrl))
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 90, height: 90)
                .border(selected ? .green : .clear, width: selected ? 2 : 0)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.gray, lineWidth: 0))
                .opacity(selected ? 0.5 : 1.0)
            
            Text("\(friend.firstName) \(String(friend.lastName.prefix(1))).")
                .font(.body)
                .fontWeight(.light)
                .foregroundColor(.black)
                .padding(2)
        }
        .frame(width: 125, height: 125)
        .cornerRadius(10)
        .padding(.top, 5)
        .onTapGesture {
            selected.toggle()
            print("Selected was Toggled")
            if selected {
                print("allSelected as added 1")
                dataController.allSelected += 1
            } else {
                print("allSelected as subtracted 1")
                dataController.allSelected -= 1
            }
            print(dataController.allSelected)
            print("selected or deselected")
            print("\(friend.firstName) says they were tapped!")
        }
    }
}
