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


struct FroopConfirmedCardView: View {
    
    @ObservedObject private var viewModel = DetailsGuestViewModel()
    @ObservedObject var appStateManager = AppStateManager.shared
    @ObservedObject var printControl = PrintControl.shared
    @ObservedObject var locationServices = LocationServices.shared
    @ObservedObject var froopDataListener = FroopDataListener.shared
    @ObservedObject var froopManager = FroopManager.shared
    @ObservedObject var friendViewController = FriendViewController.shared
    @ObservedObject var myData = MyData.shared
    @ObservedObject var timeZoneManager: TimeZoneManager = TimeZoneManager()
    @Binding var openFroop: Bool
    @State private var previousAppState: AppState?

    @State private var confirmedFriends: [UserData] = []
    @State private var declinedFriends: [UserData] = []
    @State private var invitedFriendsLocal: [UserData] = []
    @State private var identifiableInvitedFriends: [IdentifiableFriendData] = []
    @State var froopStartTime: Date? = Date()
    @State private var dataLoaded = false
    @State var myTimeZone: TimeZone = TimeZone.current
    @State private var formattedDateString: String = ""
    @State private var isBlinking = false
    @State var hostData: UserData = UserData()
    //@Binding var froopDetailOpen: Bool
    @State var invitedFriends: [UserData] = []
    let froopHostAndFriends: FroopHistory
   
    var db = FirebaseServices.shared.db
   
    var timeUntilStart: String {
        let calendar = Calendar.current
        let now = Date()

        if froopHostAndFriends.froop.froopStartTime > now {
            let components = calendar.dateComponents([.day, .hour, .minute], from: now, to: froopHostAndFriends.froop.froopStartTime)

            let days = components.day ?? 0
            let hours = components.hour ?? 0
            let minutes = components.minute ?? 0

            var timeUntilStart = "Starts in: "
            if days > 0 {
                timeUntilStart += "\(days) day(s) "
            }
            if hours > 0 {
                timeUntilStart += "\(hours) hour(s) "
            }
            if minutes > 0 {
                timeUntilStart += "\(minutes) minute(s) "
            }

            return timeUntilStart.trimmingCharacters(in: .whitespaces)
        } else {
            return "Froop has already started"
        }
    }

    
    let visibleFriendsLimit = 8
    let dateForm = DateForm()
    
    init(openFroop: Binding<Bool>, froopHostAndFriends: FroopHistory, invitedFriends: [UserData]) {
        self._openFroop = openFroop
        self.timeZoneManager = TimeZoneManager()
        self.froopHostAndFriends = froopHostAndFriends
        self.invitedFriends = invitedFriends

    }
    
    var body: some View {
        
        ZStack (alignment: .top) {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(red: 241/255, green: 241/255, blue: 255/255))
                .shadow(color: Color.black.opacity(0.2), radius: 7, x: 7, y: 7)
                .shadow(color: Color.white.opacity(0.7), radius: 7, x: -4, y: -4)
                .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.gray, lineWidth: 0.5)
                    )                .frame(height: 210)
                .foregroundColor(.white)
                .padding(.leading, 10)
                .padding(.trailing, 10)
                .onTapGesture {
                    withAnimation(.spring()) {
                        openFroop = false
                    }
                }
               
            
            VStack {
                HStack {
                    Spacer()
                    if appStateManager.inProgressFroops.contains(where: { $0.froopId == froopHostAndFriends.froop.froopId }) {
                        Text("IN PROGRESS")
                            .font(.system(size: 12))
                            .fontWeight(.semibold)
                            .foregroundColor(Color(red: 249/255, green: 0/255, blue: 98/255 ))
                            .opacity(isBlinking ? 0.0 : 1.0)
                            .onChange(of: appStateManager.appState, initial: previousAppState != nil) { oldValue, newValue in
                                // Check if the newValue is different from the previous state, if necessary
                                // If they are the same, you may wish to skip any updates.
                                guard newValue != oldValue else { return }

                                withAnimation(Animation.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
                                    self.isBlinking = true
                                }

                                // Update the previous state after processing the changes
                                previousAppState = newValue
                            }

                    }
                }
                Spacer()
            }
            .frame(height: 185)
            .padding(.top, 5)
            .padding(.trailing, 35)
            
            
            
            VStack (alignment: .leading) {
                HStack (alignment: .center){
                    HostProfilePhotoView(imageUrl: froopHostAndFriends.froop.froopHostPic)
                        .scaledToFit()
                        .frame(width: 65, height: 35)
                        .padding(.leading, 5)
                       
                    
                    VStack (alignment: .leading) {
                        Text(froopHostAndFriends.froop.froopName)
                            .font(.system(size: 16))
                            .fontWeight(.semibold)
                            .foregroundColor(.black)
                            .frame(alignment: .leading)
                        
                        Text(timeUntilStart)
                            .font(.system(size: 14))
                            .fontWeight(.regular)
                            .foregroundColor(.black)
                            .frame(alignment: .leading)
//                            .padding(.top, 5)
                        
                        Text("Host: \(froopHostAndFriends.host.firstName) \(froopHostAndFriends.host.lastName)")
                            .font(.system(size: 14))
                            .fontWeight(.light)
                            .foregroundColor(.black)
                            .multilineTextAlignment(.leading)
                    }
                    Spacer()
                    
                    VStack (alignment: .center) {
                        Image(systemName: "rectangle.expand.vertical")
                            .font(.system(size: 24))
                            .fontWeight(.light)
                            .foregroundColor(.blue)
                            .frame(alignment: .leading)
                        
                        
                    }
                    .padding(.trailing, 30)
                    .onTapGesture {
                        if appStateManager.appState == .active && appStateManager.inProgressFroops.contains(where: { $0.froopId == froopHostAndFriends.froop.froopId }) {
                            locationServices.selectedTab = .froop
                            appStateManager.findFroopById(froopId: froopHostAndFriends.froop.froopId) { found in
                                if found {
                                    locationServices.selectedTab = .froop
                                } else {
                                    froopManager.froopDetailOpen = true
                                    PrintControl.shared.printLists("ImageURL:  \(froopHostAndFriends.froop.froopHostPic)")
                                }
                            }
                        } else {
                            froopManager.selectedFroopUUID = froopHostAndFriends.froop.froopId
                            froopManager.selectedFroop = froopHostAndFriends.froop
                            froopManager.selectedHost = hostData
                            viewModel.fetchGuests()
                            froopManager.fetchFroopData(froopId: froopHostAndFriends.froop.froopId, froopHost: froopHostAndFriends.froop.froopHost) { completion in
                                print("Getting Froop")
                            }
                            froopManager.froopDetailOpen = true
                            PrintControl.shared.printLists("ImageURL:  \(froopHostAndFriends.froop.froopHostPic)")
                        }
                    }
                    
                    
                }
                .frame(height: 50)
                .padding(.top, 10)
                .padding(.leading, 10)
                
                Divider()
                    .padding(.leading, 15)
                    .padding(.trailing, 15)
                    .padding(1)
                    .padding(1)
                VStack (alignment: .leading) {
                    HStack {
                        Image(systemName: "clock")
                            .frame(width: 65, height: 30)
                            .scaledToFill()
                            .font(.system(size: 24))
                            .fontWeight(.light)
                            .foregroundColor(Color(red: 249/255, green: 0/255, blue: 98/255 ))
                       
                        Text(formattedDateString)
                            .font(.system(size: 16))
                            .fontWeight(.medium)
                            .foregroundColor(.black)
                            .padding(.leading, -15)
                        Spacer()
                    }
                    HStack {
                        Image(systemName: "mappin.and.ellipse")
                            .frame(width: 65, height: 30)
                            .scaledToFill()
                            .font(.system(size: 24))
                            .fontWeight(.light)
                            .foregroundColor(Color(red: 249/255, green: 0/255, blue: 98/255 ))
                        VStack (alignment: .leading){
                            Text(froopHostAndFriends.froop.froopLocationtitle)
                                .font(.system(size: 16))
                                .fontWeight(.medium)
                                .foregroundColor(.black)
                            Text(froopHostAndFriends.froop.froopLocationsubtitle)
                                .font(.system(size: 14))
                                .fontWeight(.light)
                                .foregroundColor(.black)
                                .lineLimit(2)
                                .padding(.trailing, 25)
                        }
                        .padding(.leading, -15)
                        Spacer()
                    }
                }
                .padding(.leading, 5)
                
                Spacer()
            }
            .onAppear {
                appStateManager.fetchHostData(uid: froopHostAndFriends.froop.froopHost) { result in
                    switch result {
                    case .success(let userData):
                        self.hostData = userData
                    case .failure(let error):
                        print("Failed to fetch host data. Error: \(error.localizedDescription)")
                    }
                }
                loadConfirmedFriends()
                PrintControl.shared.printLists("Printing Date \(froopHostAndFriends.froop.froopStartTime)")
                timeZoneManager.convertUTCToCurrent(date: froopHostAndFriends.froop.froopStartTime, currentTZ: TimeZone.current.identifier) { convertedDate in
                    formattedDateString = timeZoneManager.formatDate(passedDate: convertedDate)
                }
            }

        }
    }
    
    func printFroop () {
        print(froopHostAndFriends.froop)
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
    
    func loadInvitedFriends() {
        let uid = FirebaseServices.shared.uid
        let froopRef = db.collection("users").document(uid).collection("myFroops").document(froopHostAndFriends.froop.froopId).collection("invitedFriends").document("inviteList")

        froopRef.getDocument { (document, error) in
            if let document = document, document.exists {
                let invitedFriendUIDs = document.data()?["uid"] as? [String] ?? []
                self.fetchFriendsData(from: invitedFriendUIDs) { invitedFriends in
                    self.invitedFriends = invitedFriends
                }
            } else {
                print("No friends found in the invite list.")
            }
        }
    }

    func loadConfirmedFriends() {
        let uid = FirebaseServices.shared.uid
        let froopRef = db.collection("users").document(uid).collection("myFroops").document(froopHostAndFriends.froop.froopId).collection("invitedFriends").document("confirmedList")

        froopRef.getDocument { (document, error) in
            if let document = document, document.exists {
                let confirmedFriendUIDs = document.data()?["uid"] as? [String] ?? []
                self.fetchFriendsData(from: confirmedFriendUIDs) { confirmedFriends in
                    self.confirmedFriends = confirmedFriends
                }
            } else {
                print("No friends found in the confirmed list.")
            }
        }
    }

    func loadDeclinedFriends() {
        let uid = FirebaseServices.shared.uid
        let froopRef = db.collection("users").document(uid).collection("myFroops").document(froopHostAndFriends.froop.froopId).collection("invitedFriends").document("declinedList")

        froopRef.getDocument { (document, error) in
            if let document = document, document.exists {
                let declinedFriendUIDs = document.data()?["uid"] as? [String] ?? []
                self.fetchFriendsData(from: declinedFriendUIDs) { declinedFriends in
                    self.declinedFriends = declinedFriends
                }
            } else {
                print("No friends found in the declined list.")
            }
        }
    }
    
    func fetchConfirmedFriends() {
        let uid = FirebaseServices.shared.uid
     
        let invitedFriendsRef = db.collection("users").document(uid).collection("myFroops").document(froopHostAndFriends.froop.froopId).collection("invitedFriends")

        let confirmedListDocRef = invitedFriendsRef.document("confirmedList")

        confirmedListDocRef.getDocument { document, error in
            if let document = document, document.exists {
                let confirmedFriendUIDs = document.data()?["uid"] as? [String] ?? []
                
                // Fetch confirmed friends data from Firestore and update confirmedFriends array
                fetchFriendsData(from: confirmedFriendUIDs) { friends in
                    confirmedFriends = friends
                }
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
                if let document = document, document.exists, let friendData = document.data() {
                    let friend = UserData(dictionary: friendData)
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



