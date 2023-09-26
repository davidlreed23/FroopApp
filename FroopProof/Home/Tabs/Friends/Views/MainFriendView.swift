import SwiftUI
import Firebase
import UIKit
import FirebaseFirestore
import SwiftUIBlurView

struct MainFriendView: View {
    
    @ObservedObject var appStateManager = AppStateManager.shared
    @ObservedObject var printControl = PrintControl.shared
    @ObservedObject var locationServices = LocationServices.shared
    @ObservedObject var froopDataListener = FroopDataListener.shared
    @ObservedObject var dataController = DataController.shared
    
    var db = FirebaseServices.shared.db
    @ObservedObject var myData = MyData.shared
    @Binding var areThereFriendRequests: Bool
    @ObservedObject var friendData: UserData = UserData()
    @ObservedObject var friendInviteData: FriendInviteData
    @ObservedObject var friendStore = FriendStore()
    @ObservedObject var friendRequestManager = FriendRequestManager(timestamp: Date())
    @ObservedObject var friendListData = FriendListData(dictionary: [:])
    @State var toUserInfo = UserData()
    @State var toUserID = String()
    @State var foundInvite: FriendInviteData?
    @State var friendDetailOpen = false
    @State var friendListViewOpen = false
    @State var selectedFriend: UserData = UserData()
    @State var presentSheetAccept = false
    @State var presentSheetAdd = false
    @State var addFraction = 0.3
    @State var acceptFraction = 0.75
    @State var numberOfFriendRequests: Int = 0
    @State private var searchText: String = ""
    @State private var isInviteShowing = false
    @State var refresh = false
    @State var invitesNum: Int = 0
    var timestamp: Date
    @State var fromUserID: String = ""
    @State var friendsInCommon: [String] = [""]
    @State private var countUpdated = false
    
    
    private var friends: Binding<[UserData]> {
        Binding<[UserData]>(
            get: {
                friendStore.friends
            },
            set: {
                friendStore.friends = $0
            }
        )
    }
    
    var friendsFilter: [UserData] {
        if searchText.isEmpty {
            return friends.wrappedValue
        } else {
            return friends.wrappedValue.filter { friend in
                friend.firstName.localizedCaseInsensitiveContains(searchText) ||
                friend.lastName.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var friendUUIDsBinding: Binding<[String]> {
        Binding<[String]>(
            get: { friendStore.friends.map { $0.froopUserID } },
            set: { friendUUIDs in
                friendStore.friends = friendUUIDs.map { id in UserData() }
            }
        )
    }
    
    private var friendsBinding: Binding<[UserData]> {
        Binding<[UserData]>(
            get: {
                friendsFilter
            },
            set: { newValue in
                friends.wrappedValue = newValue
            }
        )
    }
    
    
    var addBlurRadius: CGFloat {
        presentSheetAdd == true ? 10 : 0
    }
    var acceptBlurRadius: CGFloat {
        presentSheetAccept == true ? 10 : 0
    }
    var blurRadius = 10
    
    var body: some View {
        ZStack (alignment: .top){
            
           
            
            VStack {
                SearchBar(text: $searchText)
                    .padding(.top, 25)
                    .onAppear {
                        FirebaseServices.shared.checkSMSInvitations()
                    }
                    .padding(.leading, 75)
                    .padding(.trailing, 75)
                    .padding(.bottom, 25)
                
                NavigationView {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 0) {
                            ForEach(friendStore.friends.filter { friend in
                                searchText.isEmpty ? true : friend.firstName.localizedCaseInsensitiveContains(searchText)
                            }.chunked(into: 3), id: \.self) { friendGroup in
                                HStack(spacing: 0) {
                                    ForEach(friendGroup, id: \.id) { friend in
                                        FriendCardView(selectedFriend: $selectedFriend, friendDetailOpen: $friendDetailOpen, friend: friend)
                                    }
                                }
                            }
                        }
                    }
                }
                //.searchable(text: $searchText)
                .font(.system(size: 18))
                .foregroundColor(.black)
                .offset(y: -15)
                
            }
            
            VStack {
                Spacer()
               
                HStack {
                    Spacer()
                    
                    Text(friendStore.friends.isEmpty ? "Tap the" : "")
                        .font(.system(size: 28))
                        .fontWeight(.light)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                    
                    if friendStore.friends.isEmpty {
                        Image(systemName: "plus")
                            .foregroundColor(Color(red: 249/255, green: 0/255, blue: 98/255))
                            .scaledToFill()
                            .frame(width: 25, height: 25)
                            .font(.system(size: 25))
                            .fontWeight(.semibold)
                    }
                    
                    Text(friendStore.friends.isEmpty ? "icon to add Friends!" : "")
                        .font(.system(size: 28))
                        .fontWeight(.light)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                    
                    Spacer()
                }
               
                Spacer()
            }
            
            HStack {
                Button {
                    withAnimation (.easeInOut) {
                        presentSheetAccept.toggle()
                        
                    }
                    print("Open Friend Request Sheet View")
                } label: {
                    if countUpdated {
                        Image(systemName: "person.3.fill")
                            .foregroundColor(numberOfFriendRequests > 0 ? Color(red: 249/255, green: 0/255, blue: 98/255) : .gray)
                        
                            .scaledToFill()
                            .frame(width: 25, height: 25)
                            .font(.system(size: 25))
                            .fontWeight(.light)
                            .overlay(
                                Group {
                                    if numberOfFriendRequests > 0 {
                                        VStack {
                                            Text(String(numberOfFriendRequests))
                                                .foregroundColor(.white)
                                                .frame(width: 15, height: 15)
                                                .font(.system(size: 16))
                                                .padding(2)
                                                .background(Circle().foregroundColor(Color(red: 249/255, green: 0/255, blue: 98/255)))
                                                .offset(x: 25, y: -12)
                                        }
                                        
                                    }
                                }
                            )
                            .padding(.leading, 25)
                            .padding(.top, 25)
                    }
                    
                    Spacer()
                    Button {
                        withAnimation (.easeInOut) {
                            
                            presentSheetAdd.toggle()
                        }
                        print("CreateNewFriend")
                    } label: {
                        Image(systemName: "plus")
                            .foregroundColor(Color(red: 249/255, green: 0/255, blue: 98/255))
                            .scaledToFill()
                            .frame(width: 25, height: 25)
                            .font(.system(size: 25))
                            .fontWeight(.semibold)
                        
                    }
                    .padding(.trailing, 25)
                    .padding(.top, 25)
                }
            }
            
        }
        .onAppear {
            let identity = FirebaseServices.shared.uid
            let friendRequestsRef = db.collection("friendRequests")
                .whereField("toUserID", isEqualTo: identity)
                .whereField("status", isEqualTo: "pending")
            
            friendRequestsRef.addSnapshotListener { querySnapshot, error in
                guard let snapshot = querySnapshot else {
                    print("Error fetching friend requests: \(String(describing: error))")
                    return
                }
                print("Snapshot Count \(snapshot.documents.count)")
                self.numberOfFriendRequests = snapshot.documents.count
            }
            countUpdated = true
            
            if numberOfFriendRequests > 0 {
                isInviteShowing = true
            } else {
                isInviteShowing = false
            }
        }
        
        //MARK: FRIEND DETAIL VIEW OPEN
        .fullScreenCover(isPresented: $friendDetailOpen) {
            friendListViewOpen = false
        } content: {
            ZStack {
                VStack {
                    Spacer()
                    FriendDetailView(selectedFriend: $selectedFriend)
//                        .ignoresSafeArea()
                }
                VStack {
                    HStack {
                        Spacer()
                        Image(systemName: "xmark")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                            .blendMode(.difference)
                            .padding(.trailing, 25)
                            .padding(.top, 20)
                            .onTapGesture {
                                dataController.allSelected = 0
                                self.friendDetailOpen = false
                                print("CLEAR TAP MainFriendView 1")
                            }
                    }
                    .frame(alignment: .trailing)
                    Spacer()
                }
            }
        }
        //MARK: ACCEPT SHEET
        .blurredSheet(.init(.ultraThinMaterial), show: $presentSheetAccept) {
        } content: {
            ZStack {
                Rectangle()
                    .foregroundColor(.white)
                    .opacity(0.01)
                    .onTapGesture {
                        self.presentSheetAccept = false
                        print("CLEAR TAP Main Friend View 2")
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .ignoresSafeArea()
                VStack {
                    Text("tap to close")
                        .font(.system(size: 18))
                        .fontWeight(.light)
                        .foregroundColor(.white)
                        .padding(.top, 25)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                    Spacer()
                }
                .frame(alignment: .center)
               
                
                
                VStack {
                    Spacer()
                    BeMyFriendView(
                        toUserID: $toUserID
                        )
                }
                .frame(height: acceptFraction * UIScreen.main.bounds.height)
            }
            .presentationDetents([.large])
        }
        //MARK: ADD SHEET
        .blurredSheet(.init(.ultraThinMaterial), show: $presentSheetAdd) {
        } content: {
            ZStack (alignment: .bottom) {
                Rectangle()
                    .foregroundColor(.white)
                    .opacity(0.01)
                    .onTapGesture {
                        self.presentSheetAdd = false
                        print("CLEAR TAP Main Friend View 3")
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .ignoresSafeArea()
                VStack {
                    Text("tap to close")
                        .font(.system(size: 18))
                        .fontWeight(.light)
                        .foregroundColor(.white)
                        .padding(.top, 25)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                    Spacer()
                }
                .frame(alignment: .center)
                
                VStack {
                    SearchUserView(toUserID: $toUserID)
                }
                //.frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
            }
            .presentationDetents([.large])
        }
    }
    
}

struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            TextField("Search...", text: $text)
                .padding(7)
                .padding(.leading, 25)
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .overlay(
                    HStack {
                        Image(systemName: "magnifyingglass")
                        Spacer()
                    }
                    .padding(.horizontal, 10)
                )
        }
        .padding(.horizontal, 10)
    }
}
