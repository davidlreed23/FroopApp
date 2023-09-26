//
//  FroopCardView.swift
//  FroopProof
//
//  Created by David Reed on 2/6/23.
//

import SwiftUI
import Firebase
import FirebaseFirestore
import FirebaseAuth
import MapKit


struct FroopCardView: View {
    @ObservedObject var appStateManager = AppStateManager.shared
    @ObservedObject var printControl = PrintControl.shared
    @ObservedObject var locationServices = LocationServices.shared
    @ObservedObject var froopDataListener = FroopDataListener.shared
    @ObservedObject var froopData: FroopData
    @ObservedObject var changeView = ChangeView.shared

    
    var db = FirebaseServices.shared.db
    @ObservedObject var myData = MyData.shared
    @ObservedObject var friendViewController = FriendViewController.shared
    @ObservedObject var timeZoneManager: TimeZoneManager = TimeZoneManager()
    @Binding var froopDetailOpen: Bool
    //@ObservedObject var froopData: FroopData
    var froop: Froop
    @Binding var selectedFroopUUID: String
    @Binding var invitedFriends: [UserData]
    @State private var confirmedFriends: [UserData] = []
    @State private var declinedFriends: [UserData] = []
    @State private var invitedFriendsLocal: [UserData] = []
    @State private var identifiableInvitedFriends: [IdentifiableFriendData] = []
    @State var froopStartTime: Date? = Date()
    @State private var dataLoaded = false
    let visibleFriendsLimit = 8
    @State var myTimeZone: TimeZone = TimeZone.current
    
    
    init(froopData: FroopData, froopDetailOpen: Binding<Bool>, froop: Froop, selectedFroopUUID: Binding<String>, invitedFriends: Binding<[UserData]>) {
        self.froopData = froopData
        self._froopDetailOpen = froopDetailOpen
        self.froop = froop
        self._selectedFroopUUID = selectedFroopUUID
        self._invitedFriends = invitedFriends
        self.timeZoneManager = TimeZoneManager()
    }
    
    var body: some View {
        
        ZStack (alignment: .top){
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white)
                .padding(.top, 20)
                .padding(.leading, 25)
                .padding(.trailing, 25)
                .frame(height: 285)
                .shadow(color: .gray, radius: 2)
            
            VStack (alignment: .leading) {
                HStack (spacing: 0 ){
                    VStack (alignment: .leading){
                        Text(froop.froopName)
                            .font(.system(size: 18))
                            .fontWeight(.semibold)
                            .foregroundColor(.black)
                            .frame(alignment: .leading)
                        
                        Text("Created: \(timeZoneManager.formatDurationSinceCreation(creationDate: froop.froopCreationTime)) ago")
                            .font(.system(size: 11))
                            .fontWeight(.medium)
                            .foregroundColor(.black)
                            .opacity(0.7)
                            .frame(alignment: .leading)
                    }
                    .padding(.leading, 10)
                }
                .padding(.top, 35)
                .padding(.leading, 35)
                
                Divider()
                    .padding(.leading, 35)
                    .padding(.trailing, 35)
                    .padding(1)
                    .padding(1)
                
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(confirmedFriends.prefix(visibleFriendsLimit - 1), id: \.self.id) { friend in
                            FriendProfilePhotoView(imageUrl: friend.profileImageUrl)
                                .frame(width: 45, height: 45)
                        }
                        
                        if confirmedFriends.isEmpty {
                            Text("Invited Friends")
                                .font(.system(size: 16))
                                .foregroundColor(Color(red: 249/255, green: 0/255, blue: 98/255))
                                .frame(height: 45)
                        } else if confirmedFriends.count > visibleFriendsLimit {
                            ZStack {
                                FriendProfilePhotoView(imageUrl: "")
                                    .frame(width: 45, height: 45)
                                    .opacity(0.5)
                                
                                Text("+\(confirmedFriends.count - visibleFriendsLimit + 1)")
                                    .font(.system(size: 16))
                                    .foregroundColor(.white)
                            }
                        }
                    }
                }
                .padding(1)
                .padding(1)
                .padding(.leading, 35)
                .padding(.trailing, 35)
                
                
                Divider()
                    .padding(.leading, 35)
                    .padding(.trailing, 35)
                    .padding(1)
                    .padding(1)
                
                VStack (alignment: .leading) {
                    HStack {
                        Image(systemName: "clock")
                            .frame(width: 30, height: 30)
                            .scaledToFill()
                            .font(.system(size: 18))
                            .fontWeight(.light)
                            .foregroundColor(Color(red: 249/255, green: 0/255, blue: 98/255 ))
                        Text(formatDateToTimeZone(passedDate: froop.froopStartTime, timeZone: myTimeZone))
                            .font(.system(size: 16))
                            .fontWeight(.medium)
                            .foregroundColor(.black)
                        Spacer()
                    }
                    HStack {
                        Image(systemName: "mappin.and.ellipse")
                            .frame(width: 30, height: 30)
                            .scaledToFill()
                            .font(.system(size: 18))
                            .fontWeight(.light)
                            .foregroundColor(Color(red: 249/255, green: 0/255, blue: 98/255 ))
                        VStack (alignment: .leading){
                            Text(froop.froopLocationtitle)
                                .font(.system(size: 16))
                                .fontWeight(.medium)
                                .foregroundColor(.black)
                            Text(froop.froopLocationsubtitle)
                                .font(.system(size: 14))
                                .fontWeight(.light)
                                .foregroundColor(.black)
                                .lineLimit(2)
                                .padding(.trailing, 35)
                        }
                        Spacer()
                    }
                }
                .padding(.leading, 35)
                
                Spacer()
            }
        }
        .onTapGesture {
            froopData.froopName = froop.froopName
            froopData.froopType = froop.froopType
            froopData.froopLocationtitle = froop.froopLocationtitle
            froopData.froopLocationsubtitle = froop.froopLocationsubtitle
            froopData.froopLocationCoordinate = froop.froopLocationCoordinate ?? CLLocationCoordinate2D()
            froopData.froopDuration = froop.froopDuration
            froopData.froopInvitedFriends = froop.froopInvitedFriends
            froopData.froopEndTime = froop.froopEndTime
            froopData.froopMessage = froop.froopMessage
            froopData.froopList = froop.froopList
            froopData.template = froop.template
            
            changeView.pageNumber = 5
            print(changeView.pageNumber)
        }
    }
    
    func printFroop () {
        print(froop)
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
    func formatDate(passedDate: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d',' h:mm a"
        let formattedDate = formatter.string(from: passedDate)
        return formattedDate
    }
    
    func loadFriends(listType: String) {
        let uid = FirebaseServices.shared.uid
        let froopRef = db.collection("users").document(uid).collection("myFroops").document(froop.froopId).collection("invitedFriends").document(listType)
        
        froopRef.getDocument { (document, error) in
            if let document = document, document.exists {
                let friendUIDs = document.data()?["uid"] as? [String] ?? []
                self.fetchFriendsData(from: friendUIDs) { friends in
                    if listType == "confirmedList" {
                        self.confirmedFriends = friends
                    } else if listType == "declinedList" {
                        self.declinedFriends = friends
                    }
                }
            } else {
                print("No friends found in the \(listType).")
            }
        }
    }
    
    func fetchFriendsData(from friendUIDs: [String], completion: @escaping ([UserData]) -> Void) {
        
        let usersRef = db.collection("users")
        var friends: [UserData] = []
        
        let group = DispatchGroup()
        
        for friendUID in friendUIDs {
            group.enter()
            
            usersRef.document(friendUID).getDocument { document, error in
                if let document = document, document.exists, let userData = document.data() {
                    let friend = UserData(dictionary: userData)
                    friends.append(friend ?? UserData())
                }
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            completion(friends)
        }
    }
    
    func formatDateToTimeZone(passedDate: Date, timeZone: TimeZone) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE, MMM d',' h:mm a"
        dateFormatter.timeZone = timeZone
        return dateFormatter.string(from: passedDate)
    }
    
}



