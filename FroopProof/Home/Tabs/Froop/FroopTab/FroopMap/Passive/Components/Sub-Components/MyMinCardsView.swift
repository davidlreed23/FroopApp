//
//  MyCardsView.swift
//  FroopProof
//
//  Created by David Reed on 8/9/23.
//




import SwiftUI
import Kingfisher

struct MyMinCardsView: View {
    
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject var appStateManager = AppStateManager.shared
    @ObservedObject var printControl = PrintControl.shared
    @ObservedObject var locationServices = LocationServices.shared
    @ObservedObject var froopDataListener = FroopDataListener.shared
    @ObservedObject var froopManager = FroopManager.shared
    @ObservedObject var froopTypeStore = FroopTypeStore.shared
    
    let currentUserId = FirebaseServices.shared.uid
    var db = FirebaseServices.shared.db
    let froopHostAndFriends: FroopHistory
    @State private var offset: CGFloat = 0
    @State private var isDragging = false
    @State private var hostFirstName: String = ""
    @State private var hostLastName: String = ""
    @State private var hostURL: String = ""
    @State private var showAlert = false
    @State private var selectedImageIndex = 0
    @State private var isMigrating = false
    @State private var isDownloading = false
    @State private var downloadedImages: [String: Bool] = [:]
    @State private var isImageSectionVisible: Bool = true
    @State private var froopTypeArray: [FroopType] = []
    @State private var thisFroopType: String = ""
    @State var openFroop: Bool = false
    
    // @Namespace private var animation
    
    init(froopHostAndFriends: FroopHistory, thisFroopType: String) {
        self.froopHostAndFriends = froopHostAndFriends
    }
    
    var body: some View {
        ZStack {
            if openFroop {
                froopHostAndFriends.cardForStatus(openFroop: $openFroop)
                    .padding(.bottom, 10)
            } else {
                
                VStack (){
                    HStack {
                        
                        Image(systemName: thisFroopType)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: 50, maxHeight: 50)
                            .foregroundColor(froopHostAndFriends.colorForStatus())
                            .onAppear {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    if let foundFroopType = froopTypeStore.froopTypes.first(where: { $0.id == froopHostAndFriends.froop.froopType }) {
                                        self.thisFroopType = foundFroopType.imageName
                                        print("Name: \(foundFroopType.name) ImageName: \(foundFroopType.imageName) Froop: \(froopHostAndFriends.froop.froopName)")
                                    } else {
                                        self.thisFroopType = ""
                                    }
                                }
                            }
                            .padding(.top, 5)
                        VStack (alignment:.leading){
                            HStack {
                                Text(froopHostAndFriends.froop.froopName)
                                    .font(.system(size: 16))
                                    .fontWeight(.semibold)
                                    .foregroundColor(colorScheme == .dark ? .black : .black)
                                    .multilineTextAlignment(.leading)
                                Spacer()
                                Text(froopHostAndFriends.textForStatus())
                                    .font(.system(size: 14))
                                    .fontWeight(.semibold)
                                    .foregroundColor(froopHostAndFriends.colorForStatus())
                                    .multilineTextAlignment(.leading)
                                    .padding(.trailing, 15)
                            }
                            .offset(y: 6)
                            
                            HStack (alignment: .center){
                                Text("Host:")
                                    .font(.system(size: 14))
                                    .fontWeight(.light)
                                    .foregroundColor(colorScheme == .dark ? .black : .black)
                                    .multilineTextAlignment(.leading)
                                
                                Text(froopHostAndFriends.host.firstName)
                                    .font(.system(size: 14))
                                    .fontWeight(.light)
                                    .foregroundColor(colorScheme == .dark ? .black : .black)
                                    .multilineTextAlignment(.leading)
                                
                                Text(froopHostAndFriends.host.lastName)
                                    .font(.system(size: 14))
                                    .fontWeight(.light)
                                    .foregroundColor(colorScheme == .dark ? .black : .black)
                                    .multilineTextAlignment(.leading)
                                    .offset(x: -5)
                            }
                            .offset(y: 6)
                            
                            Text("\(formatDate(for: froopHostAndFriends.froop.froopStartTime))")
                                .font(.system(size: 14))
                                .fontWeight(.thin)
                                .foregroundColor(colorScheme == .dark ? .black : .black)
                                .multilineTextAlignment(.leading)
                                .padding(.top, 2)
                                .offset(y: -6)
                        }
                        .padding(.top, 5)
                        
                        Spacer()
                        
                    }
                    .background(Color(red: 251/255, green: 251/255, blue: 249/255))
                    .padding(.horizontal, 10)
                    .padding(.bottom, 1)
                    .frame(maxHeight: 60)
                    
                    Divider()
                        .padding(.top, 10)
                }
            }
            
        }
        .onTapGesture {
            withAnimation(.spring()) {
                openFroop.toggle()
            }
            print("tap")
            for friend in froopHostAndFriends.friends {
                print(friend.firstName)
            }
        }
    }
    
    func formatDate(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE MMM.dd.yyyy 'at' h:mm a"
        return formatter.string(from: date)
    }
    
    var downloadButton: some View {
        // check if current user's id is in the friend list
        let isFriend = froopHostAndFriends.friends.contains { $0.froopUserID == currentUserId }
        
        if isFriend {
            return AnyView(
                Button(action: {
                    isDownloading = true
                    downloadImage()
                }) {
                    Image(systemName: "arrow.down.square")
                        .font(.system(size: 30))
                        .fontWeight(.thin)
                        .foregroundColor(downloadedImages[froopHostAndFriends.froop.froopImages[selectedImageIndex]] == true ? .white : Color(red: 249/255, green: 0/255, blue: 98/255)) // Change color based on isImageDownloaded
                        .background(.ultraThinMaterial)
                }
                    .frame(width: 50, height: 50)
                    .background(Color.white.opacity(0.8))
                    .clipShape(RoundedRectangle(cornerRadius: 5))
                    .disabled(isDownloading)
                    .padding()
            )
        } else {
            return AnyView(EmptyView())
        }
    }
    
    func downloadImage() {
        guard let url = URL(string: froopHostAndFriends.froop.froopImages[selectedImageIndex]) else { return }
        
        // Check if the image has already been downloaded
        if downloadedImages[froopHostAndFriends.froop.froopImages[selectedImageIndex]] == true {
            print("Image already downloaded")
            return
        }
        
        KingfisherManager.shared.retrieveImage(with: url) { result in
            switch result {
                case .success(let value):
                    UIImageWriteToSavedPhotosAlbum(value.image, nil, nil, nil)
                    downloadedImages[froopHostAndFriends.froop.froopImages[selectedImageIndex]] = true
                case .failure(let error):
                    print("Error downloading image: \(error)")
            }
            isDownloading = false
        }
    }
}
