

//
//  FriendDetailView.swift
//  FroopProof
//
//  Created by David Reed on 2/16/23.
//

import SwiftUI
import SwiftUIBlurView
import Kingfisher
import Firebase
import FirebaseAuth
import FirebaseFirestore
import Foundation
import MapKit
import EventKit
import FirebaseCrashlytics


struct FroopDetailsView: View {
    
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
    
    var db = FirebaseServices.shared.db
    
    var froops: [Froop] = []
  
    var timestamp: Date = Date()
//    @State var selectedFroopUUID: String //FroopManager.shared.selectedFroopUUID
//    @State var selectedFroop: Froop //= Froop(dictionary: [:])
    @Binding var detailFroopData: Froop
    @Binding var froopAdded: Bool
    @Binding var invitedFriends: [UserData]
    
    @State private var mapState = MapViewState.locationSelected
    @State private var confirmedFriends: [UserData] = []
    @State private var declinedFriends: [UserData] = []
    @State private var invitedFriendsLocal: [UserData] = []
    @State var detailGuests: [UserData] = []
    @State private var dataLoaded = false
    @State var extractedFD: UserData = UserData()
    @State private var viewLoaded = false
    var dateDisplay: DateDisplay = DateDisplay()
    @State private var formattedDateString: String = ""
    @State private var froopLocation: CLLocationCoordinate2D = CLLocationCoordinate2D()
    @State private var froopHostUrl: String = ""
    @State private var froopName: String = ""
    @State private var showAlert = false
    @State var selectedFroopUUID: String = FroopManager.shared.selectedFroopUUID
    @State var selectedFroop: Froop = FroopManager.shared.selectedFroop
    
    let dateForm = DateForm()
    

    init(
         detailFroopData: Binding<Froop>,
         froopAdded: Binding<Bool>,
         invitedFriends: Binding<[UserData]>) {
        
       
        self._detailFroopData = detailFroopData
        self._froopAdded = froopAdded
        self._invitedFriends = invitedFriends
    }
    
    
    var body: some View {
        
        ZStack{
            //MARK:  Background Layout Objects
            
            ZStack (alignment: .top) {
                
                VStack {
                    Rectangle()
                        .fill(RadialGradient(gradient: Gradient(colors: [.black, .purple]), center: .center, startRadius: 2, endRadius: 900))
                        .frame(height: UIScreen.main.bounds.height * 0.25)
                        .opacity(0.6)
                    Rectangle()
                        .fill(RadialGradient(gradient: Gradient(colors: [.white, .gray]), center: .center, startRadius: 2, endRadius: 900))
                        .frame(height: UIScreen.main.bounds.height * 0.75)
                        .opacity(0.5)
                        .offset(y: -10)
                }
                
                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                .ignoresSafeArea()
                .onAppear {
                    froopHostUrl = selectedFroop.froopHostPic
                    froopName = selectedFroop.froopName
                    
                    PrintControl.shared.printFroopDetails("-----FroopHostUrl:  \(froopHostUrl)")
                    PrintControl.shared.printFroopDetails("-----froopName:  \(froopName)")
                    
                    PrintControl.shared.printFroopDetails("Pre-Function: \(froopData.froopStartTime)")
                    timeZoneManager.convertUTCToCurrentDetail(date: selectedFroop.froopStartTime, currentTZ: TimeZone.current.identifier) { convertedDate in
                        print(TimeZone.current.identifier)
                        print(froopData.froopStartTime)
                        formattedDateString = timeZoneManager.formatDateDetail(passedDate: convertedDate)
                        if !viewLoaded {
                            Task {
                                do {
                                    self.detailGuests = try await FriendViewController.shared.fetchInvitedFriends(froopId: selectedFroopUUID)
                                } catch {
                                    print("Error fetching invited friends: \(error.localizedDescription)")
                                }
                            }
                            
                            PrintControl.shared.printFroopDetails(froops.description)
                            PrintControl.shared.printFroopDetails("*******************************")
                            PrintControl.shared.printFroopDetails(selectedFroopUUID)
                            FriendViewController.shared.convertDataModel(selectedFroop.froopHost) { extractedFD, error in
                                if let error = error {
                                    print("Error converting data model: \(error.localizedDescription)")
                                    return
                                }
                                self.extractedFD = extractedFD ?? UserData()
                            }
                            fetchFriendLists()
                            dataLoaded = true
                            viewLoaded = true
                        }
                    }
                }
                .frame(minWidth: 0,maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                .ignoresSafeArea()
                VStack {
                    ScrollView (showsIndicators: false) {
                        //MARK:  Secondary Background Layout Objects
                        ZStack (alignment: .top){
                            VStack {
                                
                                VStack (alignment: .center) {
                                    ZStack {
                                        Circle()
                                            .frame(width: 128, height: 128, alignment: .center)
                                        
                                        KFImage(URL(string: dataLoaded ? froopManager.selectedFroop.froopHostPic : ""))
                                            .placeholder {
                                                ProgressView()
                                            }
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 128, height: 128, alignment: .center)
                                            .clipShape(Circle())
                                    }
                                    
                                    HStack (alignment: .top){
                                        Spacer()
                                        Text("Host:")
                                            .font(.system(size: 18))
                                            .fontWeight(.medium)
                                            .foregroundColor(.black)
                                            .frame(alignment: .leading)
                                        Text(dataLoaded ? ("\(extractedFD.firstName) \(extractedFD.lastName)") : "")
                                            .font(.system(size: 18))
                                            .fontWeight(.light)
                                            .foregroundColor(.black)
                                            .frame(alignment: .leading)
                                        Spacer()
                                    }
                                    .padding(.top,5)
                                    .frame(width: 300, alignment: .center)
                                }
                                .padding(.top, 125)
                                
                                .ignoresSafeArea()
                                
                                
                            }
                        }
                        
                        //MARK: Content
                        ZStack (alignment: .top){
                            
                            VStack (alignment: .center){
                                
                                //MARK: FROOP NAME
                                ZStack {
                                    RoundedRectangle(cornerRadius: 10)
                                        .foregroundColor(.clear)
                                        .frame(height:125)
                                        .padding(.leading, 15)
                                        .padding(.trailing, 15)
                                    
                                    VStack(alignment: .center) {
                                        HStack {
                                            Text(froopManager.selectedFroop.froopName )
                                                .font(.system(size: 32))
                                                .minimumScaleFactor(0.5)
                                                .opacity(0.75)
                                                .fontWeight(.light)
                                                .foregroundColor(.black)
                                                .padding(.leading, 25)
                                                .padding(.trailing, 25)
                                                .padding(.top, 15)
                                                .lineLimit(3)
                                                .frame(maxHeight: 115, alignment: .top)
                                                .multilineTextAlignment(.center)
                                        }
                                        
                                    }
                                }
                                .frame(maxWidth: 400, maxHeight: 125)
                                
                                //MARK: FROOP TIME
                                ZStack {
                                    RoundedRectangle(cornerRadius: 10)
                                        .foregroundColor(.white)
                                        .frame(height: 75)
                                        .padding(.leading, 15)
                                        .padding(.trailing, 15)
                                    VStack (alignment: .leading) {
                                        HStack {
                                            Image(systemName: "calendar.badge.clock")
                                                .frame(width: 60, height: 60)
                                                .scaledToFill()
                                                .font(.system(size: 24))
                                                .fontWeight(.medium)
                                                .foregroundColor(Color(red: 249/255, green: 0/255, blue: 98/255 ))
                                                .padding(.leading, 25)
                                                .frame(alignment: .center)
                                            Text(formattedDateString)
                                                .font(.system(size: 18))
                                                .opacity(0.8)
                                                .fontWeight(.regular)
                                                .foregroundColor(.black)
                                                .padding(.trailing, 25)
                                                .frame(width: 300, height: 115, alignment: .leading)
                                                
                                            Spacer()
                                        }
//                                        .onTapGesture {
//                                                createCalendarEvent()
//                                        }
                                        .frame(maxWidth: 400, maxHeight: 75)
                                    }
                                }
                                .frame(maxWidth: 400, maxHeight: 75)
                                .padding(.top, -35)
                                
                                
                                //MARK: LOCATION
                                ZStack {
                                    RoundedRectangle(cornerRadius: 10)
                                        .foregroundColor(.white)
                                        .frame(height: 75)
                                        .padding(.leading, 15)
                                        .padding(.trailing, 15)
                                    VStack {
                                        HStack {
                                            Image(systemName: "mappin.and.ellipse")
                                                .frame(width: 60, height: 60)
                                                .scaledToFill()
                                                .font(.system(size: 24))
                                                .fontWeight(.medium)
                                                .foregroundColor(Color(red: 249/255, green: 0/255, blue: 98/255 ))
                                                .padding(.leading, 25)
                                                .frame(alignment: .center)
                                            VStack (alignment: .leading){
                                                //Text("Trever's on the Tracks")
                                                Text(froopManager.selectedFroop.froopLocationtitle)
                                                    .font(.system(size: 16))
                                                    .fontWeight(.medium)
                                                    .foregroundColor(.black)
                                                    .padding(.trailing, 25)
                                                //Text("123 Main Street, Los Angeles CA, 90210")
                                                Text(froopManager.selectedFroop.froopLocationsubtitle)
                                                    .font(.system(size: 14))
                                                    .fontWeight(.light)
                                                    .foregroundColor(.black)
                                                    .lineLimit(2)
                                                    .padding(.trailing, 25)
                                            }
                                            Spacer()
                                        }
                                        .frame(maxWidth: 400, maxHeight: 75)
                                        .onTapGesture {
                                            froopManager.froopMapOpen = true
                                        }
                                    }
                                }
                                .frame(maxWidth: 400, maxHeight: 75)
                                
                                //MARK: DURATION
                                ZStack {
                                    RoundedRectangle(cornerRadius: 10)
                                        .foregroundColor(.white)
                                        .frame(height: 75)
                                        .padding(.leading, 15)
                                        .padding(.trailing, 15)
                                    VStack {
                                        HStack {
                                            Image(systemName: "hourglass.tophalf.filled")
                                                .frame(width: 60, height: 60)
                                                .scaledToFill()
                                                .font(.system(size: 24))
                                                .fontWeight(.medium)
                                                .foregroundColor(Color(red: 249/255, green: 0/255, blue: 98/255 ))
                                                .padding(.leading, 25)
                                                .frame(alignment: .center)
                                            Text("Duration: \(timeZoneManager.formatDuration(durationInSeconds: froopManager.selectedFroop.froopDuration))")
                                            //Text("Duration: 4 hours & 30 minutes")
                                                .font(.system(size: 16))
                                                .fontWeight(.medium)
                                                .foregroundColor(.black)
                                            //.frame(width: 300, height: 115, alignment: .leading)
                                                .padding(.trailing, 25)
                                            
                                            Spacer()
                                        }
                                        .frame(maxWidth: 400, maxHeight: 75)
                                    }
                                }
                               
                                .frame(maxWidth: 400, maxHeight: 75)
                                
                                Spacer()
                                
                                VStack(alignment: .leading, spacing: 0) {
                                    Text("\(confirmedFriends.count) Coming")
                                        .font(.system(size: 18))
                                        .fontWeight(.semibold)
                                        .foregroundColor(.black)
                                        .opacity(0.7)
                                        .padding(.top)
                                        .padding(.leading, 25)
                                        .padding(.bottom, 15)
                                        .multilineTextAlignment(.leading)
                                    ForEach(confirmedFriends.chunked(into: 4), id: \.self) { friendGroup in
                                        HStack(spacing: 0) {
                                            ForEach(friendGroup, id: \.id) { friend in
                                                DetailFriendCardView(friendDetailOpen: $froopManager.friendDetailOpen, invitedFriends: $invitedFriends, friend: friend, detailGuests: $detailGuests)
                                            }
                                        }
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.leading, 25)
                                        .padding(.trailing, 25)
                                    }
                                    
                                    Text("\(invitedFriends.count) Not Responded")
                                        .font(.system(size: 18))
                                        .fontWeight(.semibold)
                                        .foregroundColor(.black)
                                        .opacity(0.7)
                                        .padding(.top)
                                        .padding(.leading, 25)
                                        .padding(.bottom, 15)
                                        .multilineTextAlignment(.leading)
                                    ForEach(invitedFriends.chunked(into: 4), id: \.self) { friendGroup in
                                        HStack(spacing: 0) {
                                            ForEach(friendGroup, id: \.id) { friend in
                                                DetailFriendCardView(friendDetailOpen: $froopManager.friendDetailOpen, invitedFriends: $invitedFriends, friend: friend, detailGuests: $detailGuests)
                                            }
                                        }
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.leading, 25)
                                        .padding(.trailing, 25)
                                    }
                                    
                                    Text("\(declinedFriends.count) Not Coming")
                                        .font(.system(size: 18))
                                        .fontWeight(.semibold)
                                        .foregroundColor(.black)
                                        .opacity(0.7)
                                        .padding(.top)
                                        .padding(.leading, 25)
                                        .padding(.bottom, 15)
                                        .multilineTextAlignment(.leading)
                                    ForEach(declinedFriends.chunked(into: 4), id: \.self) { friendGroup in
                                        HStack(spacing: 0) {
                                            ForEach(friendGroup, id: \.id) { friend in
                                                DetailFriendCardView(friendDetailOpen: $froopManager.friendDetailOpen, invitedFriends: $invitedFriends, friend: friend, detailGuests: $detailGuests)
                                            }
                                        }
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.leading, 25)
                                        .padding(.trailing, 25)
                                    }
                                }
                            }
                            
                            //MARK: EDIT FROOP
                        }
                        .padding(.bottom, 20)
                        
                        ZStack {
                            if (FirebaseServices.shared.uid) == froopManager.selectedFroop.froopHost {
                                
                                
                                Button(action: {
                                    self.froopManager.friendDetailOpen = false
                                    self.froopManager.froopDetailOpen = false
                                    PrintControl.shared.printFroopDetails("current User UID \(FirebaseServices.shared.uid)")
                                    PrintControl.shared.printFroopDetails("MyData.shared.froopUserID \(MyData.shared.froopUserID)")
                                    PrintControl.shared.printFroopDetails("selectedFroopUUID \(selectedFroopUUID)")
                                    FroopDataController.shared.deleteFroop(froopId: froopManager.selectedFroopUUID , froopHost: myData.froopUserID) { closeSheet in
                                        print("Deleting Froop \(String(describing: froopManager.selectedFroopUUID))")
                                        self.froopAdded = true
                                    }
                                }) {
                                    ZStack {
                                        Rectangle ()
                                            .frame(width: 250, height: 50)
                                            .border(.black, width: 0.25)
                                        Text("Delete Froop")
                                            .foregroundColor(.black)
                                            .font(.system(size: 18))
                                            .fontWeight(.thin)
                                    }
                                }
                            } else {
                                Text("")
                            }
                        }
                    }
                    
                    Spacer()
                    
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
                    
                    .blurredSheet(.init(.ultraThinMaterial), show: $froopManager.froopMapOpen) {
                    } content: {
                        ZStack {
                            VStack {
                                Spacer()
                                DetailsMapViewRepresentable(mapState: $mapState, selectedFroop: $froopManager.selectedFroop, selectedFroopUUID: $froopManager.selectedFroopUUID, froopMapOpen: $froopManager.froopMapOpen)
                            }
                             
                                                          
                            VStack {
                                Rectangle()
                                    .foregroundColor(.white)
                                    .opacity(0.01)
                                    .onTapGesture {
                                        print(froopManager.selectedFroop.froopLocationCoordinate.debugDescription)
                                        self.froopManager.froopMapOpen = false
                                        print("CLEAR TAP Froop Details View")
                                        
                                    }
                                    .frame(maxWidth: .infinity, maxHeight: 100)
                                    .ignoresSafeArea()
                                //.border(.pink)
                                Spacer()
                            }
                            VStack {
                                Text("tap to close")
                                    .font(.system(size: 18))
                                    .fontWeight(.light)
                                    .foregroundColor(.black)
                                    .padding(.top, 25)
                                    .opacity(0.5)
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 24))
                                    .foregroundColor(.black)
                                Spacer()
                            }
                            .frame(alignment: .top)
                        }
                        .presentationDetents([.large])
                    }
                    
                    
                    .blurredSheet(.init(.ultraThinMaterial), show: $froopManager.addFriendsOpen) {
                    } content: {
                        ZStack {
                            VStack {
                                Spacer()
                                
                                AddFriendsFroopView(friendData: friendData, friendDetailOpen: $froopManager.friendDetailOpen, invitedFriends: $invitedFriends, selectedFroopUUID: $selectedFroopUUID, addFriendsOpen: $froopManager.addFriendsOpen, timestamp: timestamp, detailGuests: $detailGuests)
                            }
                            
                            
                            VStack {
                                Rectangle()
                                    .foregroundColor(.white)
                                    .opacity(0.01)
                                    .onTapGesture {
                                        self.froopManager.addFriendsOpen = false
                                        print("CLEAR TAP Froop Details View")
                                        
                                    }
                                    .frame(maxWidth: .infinity, maxHeight: 100)
                                    .ignoresSafeArea()
                                //.border(.pink)
                                Spacer()
                            }
                            VStack {
                                Text("tap to close")
                                    .font(.system(size: 18))
                                    .fontWeight(.light)
                                    .foregroundColor(.gray)
                                    .padding(.top, 25)
                                    .opacity(0.5)
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 24))
                                    .foregroundColor(.gray)
                                Spacer()
                            }
                            .frame(alignment: .top)
                        }
                        .presentationDetents([.large])
                    }
                    
                }
                .alert(isPresented: $showAlert) {
                    Alert(
                        title: Text("Event Saved"),
                        message: Text("\(extractedFD.firstName)'s Froop has been added to your calendar.  The Froop: \(selectedFroop.froopName) will start on \(selectedFroop.froopStartTime)."),
                        dismissButton: .default(Text("OK"))
                    )
                }
                .ignoresSafeArea()
            }
        }
    }
    
    func fetchFriendLists() {
        let uid = selectedFroop.froopHost
        let froopUUID = selectedFroopUUID
        
        guard !uid.isEmpty else {
            Crashlytics.crashlytics().log("Function: fetchFriendLists: UID nil")
            return
        }
        
        guard !froopUUID.isEmpty else {
            Crashlytics.crashlytics().log("Function: fetchFriendLists: selectedFroopUUID is nil")
            return
        }
        
        let invitedFriendsRef = db.collection("users").document(uid).collection("myFroops").document(froopUUID).collection("invitedFriends")
        
        let inviteListDocRef = invitedFriendsRef.document("inviteList")
        let declinedListDocRef = invitedFriendsRef.document("declinedList")
        let confirmedListDocRef = invitedFriendsRef.document("confirmedList")
        
        inviteListDocRef.getDocument { document, error in
            if let error = error {
                Crashlytics.crashlytics().record(error: error)
            } else if let document = document, document.exists, let invitedFriendUIDs = document.data()?["uid"] as? [String] {
                fetchFriendsData(from: invitedFriendUIDs) { friends in
                    invitedFriends = friends
                }
            } else {
                Crashlytics.crashlytics().log("Document does not exist for inviteListDocRef")
            }
        }
        
        declinedListDocRef.getDocument { document, error in
            if let error = error {
                Crashlytics.crashlytics().record(error: error)
            } else if let document = document, document.exists, let declinedFriendUIDs = document.data()?["uid"] as? [String] {
                fetchFriendsData(from: declinedFriendUIDs) { friends in
                    declinedFriends = friends
                }
            } else {
                Crashlytics.crashlytics().log("Document does not exist for declinedListDocRef")
            }
        }
        
        confirmedListDocRef.getDocument { document, error in
            if let error = error {
                Crashlytics.crashlytics().record(error: error)
            } else if let document = document, document.exists, let confirmedFriendUIDs = document.data()?["uid"] as? [String] {
                fetchFriendsData(from: confirmedFriendUIDs) { friends in
                    confirmedFriends = friends
                }
            } else {
                Crashlytics.crashlytics().log("Document does not exist for confirmedListDocRef")
            }
        }
    }
    
    func fetchFriendsData(from friendUIDs: [String], completion: @escaping ([UserData]) -> Void) {
        guard !friendUIDs.isEmpty else {
            Crashlytics.crashlytics().log("Function: fetchFriendsData: friendUIDs is empty")
            completion([])
            return
        }

        let usersRef = db.collection("users")
        var friends: [UserData] = []
        let group = DispatchGroup()
        
        for friendUID in friendUIDs {
            group.enter()
            usersRef.document(friendUID).getDocument { document, error in
                if let error = error {
                    Crashlytics.crashlytics().record(error: error)
                } else if let document = document, document.exists, let friendData = document.data() {
                    let friend = UserData(dictionary: friendData)
                    friends.append(friend ?? UserData())
                } else {
                    Crashlytics.crashlytics().log("Document does not exist for friendUID \(friendUID)")
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
    
    func requestCalendarAccess(completion: @escaping (Bool) -> Void) {
        let eventStore = EKEventStore()
        
        eventStore.requestAccess(to: .event) { (granted, error) in
            DispatchQueue.main.async {
                completion(granted)
            }
        }
    }
    
//    func createCalendarEvent() {
//        let eventStore = EKEventStore()
//
//        requestCalendarAccess { granted in
//            if granted {
//                let event = EKEvent(eventStore: eventStore)
//                event.title = selectedFroop.froopName
//                event.startDate = selectedFroop.froopStartTime
//                event.endDate = selectedFroop.froopEndTime
//                event.notes = ("\(selectedFroop.froopLocationtitle) at \(selectedFroop.froopLocationsubtitle)")
//                event.calendar = eventStore.defaultCalendarForNewEvents
//
//                do {
//                    try eventStore.save(event, span: .thisEvent)
//                    print("Event saved successfully")
//                    showAlert = true
//                } catch {
//                    PrintControl.shared.printErrorMessages("Error saving event: \(error.localizedDescription)")
//                }
//            } else {
//                PrintControl.shared.printErrorMessages("Calendar access not granted")
//            }
//        }
//    }
}



