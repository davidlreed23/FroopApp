import SwiftUI
import Firebase
import UIKit
import FirebaseFirestore
import SwiftUIBlurView

struct FriendListView: View {
    
    @ObservedObject var appStateManager = AppStateManager.shared
    @ObservedObject var printControl = PrintControl.shared
    @ObservedObject var locationServices = LocationServices.shared
    @ObservedObject var froopDataListener = FroopDataListener.shared

    var db = FirebaseServices.shared.db
    @State private var friends: [UserData] = []
    @ObservedObject var friendData: UserData = UserData()
    @ObservedObject var myData = MyData.shared
    @State var refresh = false
    @ObservedObject var friendStore = FriendStore()
    @Binding var selectedFriend: UserData
    
    var body: some View {
        ZStack {
            Rectangle()
                .frame(height: 1200)
                .foregroundColor(.white)
                .opacity(0.001)
            //        ScrollView(showsIndicators: false) {
            VStack(spacing: 15) {
                ForEach(froopDataListener.friends.chunked(into: 3), id: \.self) { friendGroup in
                    HStack(spacing: 15) {
                        ForEach(friendGroup, id: \.id) { friend in
                            FriendOfFriendCardView(selectedFriend: $selectedFriend, friend: friend)
                        }
                    }
                }
                Spacer()
            }
            //        }
            .padding(.top, 10)
            .shadow(color: .gray, radius: 2)
            .onAppear() {
                if froopDataListener.friends.isEmpty {
                    froopDataListener.getData(uid: selectedFriend.froopUserID)
                } else {
                    print("lovely")
                }
            }
        }
    }
}

