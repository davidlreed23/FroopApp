//
//  RootView.swift
//  FroopProof
//
//  Created by David Reed on 2/11/23.
//

import SwiftUI
import Kingfisher
import FirebaseAuth


struct RootView: View {
    @AppStorage("ProfileCompletionCurrentPage") var ProfileCompletionCurrentPage = 1
    @Environment(\.colorScheme) var colorScheme
    @StateObject var firebaseServices = FirebaseServices.shared
    @StateObject var appStateManager = AppStateManager.shared
    @StateObject var locationServices = LocationServices.shared
    @StateObject var notificationsManager = NotificationsManager.shared
    @StateObject var locationManager = LocationManager.shared
    @StateObject var printControl = PrintControl.shared
    @StateObject var froopDataController = FroopDataController.shared
    @StateObject var timeZoneManager = TimeZoneManager()
    @StateObject var mediaManager = MediaManager()
    @StateObject var locationSearchViewModel = LocationSearchViewModel()
    @StateObject var froopData = FroopData()
    @StateObject var froopDataListener = FroopDataListener.shared
    @StateObject var invitationList: InvitationList = InvitationList(uid: FirebaseServices.shared.uid)
    @StateObject var changeView = ChangeView.shared

    @ObservedObject var friendStore = FriendStore()
    @ObservedObject var photoData = PhotoData()
    @ObservedObject var myData = MyData.shared
    @ObservedObject var friendData: UserData = UserData()
    @ObservedObject var confirmedFroopsList: ConfirmedFroopsList
    @ObservedObject var versionChecker: VersionChecker = VersionChecker.shared 

    @State var selectedTab: Tab = .froop
    @State var froopTabPosition: Int = 1
    @State var friends: [UserData] = []
    @State var areThereFriendRequests: Bool = false
    @State var uploadedImages: [ImageItem] = []
   
    
    private var selectedTabBinding: Binding<Tab> {
            Binding(
                get: { LocationServices.shared.selectedTab },
                set: { LocationServices.shared.selectedTab = $0 }
            )
        }

    // let dataController = DataController()
    var appDelegate: AppDelegate = AppDelegate()
    
    init(friendData: UserData, photoData: PhotoData, appDelegate: AppDelegate, confirmedFroopsList: ConfirmedFroopsList) {
        UITabBar.appearance().isHidden = false
        
        self.friendData = friendData
        self.photoData = photoData
        self.appDelegate = appDelegate
        self.confirmedFroopsList = confirmedFroopsList
    }
    
    var body: some View {
        if versionChecker.isLoadingVersion {
            
            Text("Checking Version... \(versionChecker.version)")
       
        } else if versionChecker.version != versionChecker.versionCheck {
            
            UpdateVersionView()
            
        } else if ProfileCompletionCurrentPage != 2 {
               
            OnboardingView(ProfileCompletionCurrentPage: $ProfileCompletionCurrentPage)
                
        } else {
            NavigationView {
                ZStack {
                    Color.offWhite
                    VStack{
                          
                                    
                           if LocationServices.shared.selectedTab == .froop {
                                FroopTabView(friendData: friendData, viewModel: ImageGridViewModel(), uploadedImages: $uploadedImages, thisFroop: Froop.emptyFroop(), froopTabPosition: $froopTabPosition) 
                                    .environmentObject(locationSearchViewModel)
                                    .environmentObject(MyData.shared)
                                    .environmentObject(AppStateManager.shared)
                                    .environmentObject(FirebaseServices.shared)
                                    .environmentObject(LocationServices.shared)
                                    .environmentObject(LocationManager.shared)
                                    .environmentObject(PrintControl.shared)
                                    .environmentObject(FroopDataController.shared)
                                    .environmentObject(NotificationsManager.shared)
                                    .environmentObject(timeZoneManager)
                                    .environmentObject(appDelegate)
                                    .environmentObject(mediaManager)
                                    .environmentObject(invitationList)
                                    .tag(Tab.froop)
                            }
                    }

                }
            }
            .onAppear {
                PrintControl.shared.printStartUp("RootView Appear")
            }
            .navigationTitle("Froop Beta")
            .foregroundColor(colorScheme == .dark ? .white : .black)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.black.opacity(0.8), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .navigationBarItems(
                leading:
                    Text("\(TimerServices.shared.formatDate(for: Date()))")
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                    .fontWeight(.semibold),
                        
                trailing:
                    NavigationLink(destination: ProfileView(), label: {
                        KFImage(URL(string:  MyData.shared.profileImageUrl))
                            .resizable()
                            .frame(width: 30, height: 30)
                            .clipShape(Circle())
                    })
            )
        }
    }
}



