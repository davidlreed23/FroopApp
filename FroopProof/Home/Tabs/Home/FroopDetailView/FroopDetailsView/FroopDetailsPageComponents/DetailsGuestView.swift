//
//  DetailsGuestView.swift
//  FroopProof
//
//  Created by David Reed on 6/20/23.
//

import SwiftUI
import Foundation
import FirebaseAuth
import FirebaseStorage
import FirebaseFirestore
import UIKit
import Combine
import MapKit
import Kingfisher

struct DetailsGuestView: View {
    
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject var appStateManager = AppStateManager.shared
    @ObservedObject var printControl = PrintControl.shared
    @ObservedObject var locationServices = LocationServices.shared
    @ObservedObject var froopDataListener = FroopDataListener.shared
    @ObservedObject var myData = MyData.shared
    @ObservedObject var froopManager = FroopManager.shared
    @ObservedObject var friendViewController = FriendViewController.shared
    @ObservedObject var timeZoneManager: TimeZoneManager = TimeZoneManager()
    @ObservedObject var froopData: FroopData = FroopData()
    @ObservedObject var friendData: UserData = UserData()
    @ObservedObject private var viewModel = DetailsGuestViewModel()
    
    @State private var detailsTab = 1
    @State private var selectedTab = 1
    @State private var rectangleHeight: CGFloat = 100
    @State private var rectangleY: CGFloat = 100
    
    private var gridItems = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]

    
    var body: some View {
        VStack (spacing: 0){
            ZStack {
                Rectangle()
                    .frame(height: 75)
                    //.border(.black, width: 0.25)
                    .foregroundColor(colorScheme == .dark ? Color(red: 250/255 , green: 250/255, blue: 255/255) : Color(red: 250/255 , green: 250/255, blue: 255/255))
                  
                 
                VStack {
                    Spacer()
                    ZStack{
                        HStack {
                            Spacer()
                            RoundedRectangle(cornerRadius: 2, style: .continuous)
                                .frame(width: selectedTab == 1 ? 125 : selectedTab == 2 ? 125 : 125, height: 30)
                                .foregroundColor(colorScheme == .dark ? .white : .black)
                                .opacity(colorScheme == .dark ? 0.2 : 0.05)
                                .ignoresSafeArea()
                                .offset(x: selectedTab == 0 ? -140 : selectedTab == 2 ? 140 : 0, y: 10)
                                .animation(.linear(duration: 0.2), value: selectedTab)
                                .padding(.leading, 15)
                                .padding(.trailing, 15)
                            Spacer()
                        }
                        VStack {
                        Text("PLAYERS")
                                .foregroundColor(.black)
                                .opacity(0.7)
                                .font(.system(size: 15))
                                .fontWeight(.semibold)
                                .offset(y: -15)
                            HStack {
                                Text("SCHEDULED:")
                                    .foregroundColor(.black)
                                    .opacity(0.5)
                                    .font(.system(size: 14))
                                    .fontWeight(.semibold)
                                    .onTapGesture {
                                        selectedTab = 0
                                    }
                                Text(froopManager.invitedFriends.count.description)
                                    .foregroundColor(.black)
                                    .opacity(0.5)
                                    .font(.system(size: 14))
                                    .fontWeight(.semibold)
                                Spacer()
                                Text("Confirmed:")
                                    .foregroundColor(.black)
                                    .opacity(0.5)
                                    .font(.system(size: 14))
                                    .fontWeight(.semibold)
                                    .onTapGesture {
                                        selectedTab = 1
                                    }
                                Text(froopManager.confirmedFriends.count.description)
                                    .foregroundColor(.black)
                                    .opacity(0.5)
                                    .font(.system(size: 14))
                                    .fontWeight(.semibold)
                                Spacer()
                                Text("Declined:")
                                    .foregroundColor(.black)
                                    .opacity(0.5)
                                    .font(.system(size: 14))
                                    .fontWeight(.semibold)
                                    .onTapGesture {
                                        selectedTab = 2
                                    }
                                Text(froopManager.declinedFriends.count.description)
                                    .foregroundColor(.black)
                                    .opacity(0.5)
                                    .font(.system(size: 14))
                                    .fontWeight(.semibold)
                            }
                        }
                    }
                    .padding(.bottom, 10)
                    .padding(.trailing, 40)
                    .padding(.leading, 40)
                }
                .frame(maxHeight: 75)
            }
            
            ZStack {
                Rectangle()
                    .border(.black, width: 0.25)
                    .frame(height: 100)
                    .foregroundColor(colorScheme == .dark ? Color(red: 250/255 , green: 250/255, blue: 255/255) : Color(red: 250/255 , green: 250/255, blue: 255/255))
                  
                TabView(selection: $selectedTab) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack (alignment: .center){
                            ForEach(froopManager.invitedFriends, id: \.self) { friend in
                                VStack {
                                    KFImage(URL(string: friend.profileImageUrl))
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .clipShape(Circle())
                                        .frame(width: 50, height: 50)
                                    Text("\(friend.firstName) \(String(friend.lastName.prefix(1))).")
                                        .font(.system(size: 12))
                                        .frame(maxWidth: 75)
                                        .fontWeight(.light)
                                        .foregroundColor(.black)
                                        .opacity(0.5)
                                }
                            }
                        }
                        .padding(.leading, 25)
                        .padding(.trailing, 25)
                    }
                    .frame(height: rectangleHeight)
            
                    .tag(0)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(froopManager.confirmedFriends, id: \.self) { friend in
                                VStack {
                                    KFImage(URL(string: friend.profileImageUrl))
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .clipShape(Circle())
                                        .frame(width: 50, height: 50)
                                    Text("\(friend.firstName) \(String(friend.lastName.prefix(1))).")
                                        .frame(maxWidth: 75)
                                        .font(.system(size: 12))
                                        .fontWeight(.light)
                                        .foregroundColor(.black)
                                        .opacity(0.5)
                                }
                            }
                        }
                        .padding(.leading, 25)
                        .padding(.trailing, 25)
                    }
                    .frame(height: rectangleHeight)
                    .tag(1)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(froopManager.declinedFriends, id: \.self) { friend in
                                VStack {
                                    KFImage(URL(string: friend.profileImageUrl))
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .clipShape(Circle())
                                        .frame(width: 50, height: 50)
                                    Text("\(friend.firstName) \(String(friend.lastName.prefix(1))).")
                                        .font(.system(size: 12))
                                        .frame(minWidth: 75)
                                        .fontWeight(.light)
                                        .foregroundColor(.black)
                                        .opacity(0.5)
                                }
                            }
                        }
                        .padding(.leading, 25)
                        .padding(.trailing, 25)
                    }
                    .frame(height: rectangleHeight)
                    .tag(2)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .padding(.trailing, 25)
                .padding(.leading, 25)
            }
        }
        Divider()
    }
}


class DetailsGuestViewModel: ObservableObject {
    @ObservedObject var froopManager = FroopManager.shared

    func fetchGuests() {
        let group = DispatchGroup()
        
        group.enter()
        froopManager.fetchConfirmedFriendData(for: froopManager.selectedFroop) { result in
            switch result {
            case .success(let friends):
                    self.froopManager.confirmedFriends = friends
            case .failure(let error):
                print("Failed to fetch confirmed friends: \(error)")
            }
            group.leave()
        }
        
        group.enter()
        froopManager.fetchInvitedFriendData(for: froopManager.selectedFroop) { result in
            switch result {
            case .success(let friends):
                    self.froopManager.invitedFriends = friends
            case .failure(let error):
                print("Failed to fetch invited friends: \(error)")
            }
            group.leave()
        }
        
        group.enter()
        froopManager.fetchDeclinedFriendData(for: froopManager.selectedFroop) { result in
            switch result {
            case .success(let friends):
                    self.froopManager.declinedFriends = friends
            case .failure(let error):
                print("Failed to fetch declined friends: \(error)")
            }
            group.leave()
        }

        group.notify(queue: .main) {
            self.froopManager.initializeListenersForFroop(froopId: self.froopManager.selectedFroop.froopId)
        }
    }
}
