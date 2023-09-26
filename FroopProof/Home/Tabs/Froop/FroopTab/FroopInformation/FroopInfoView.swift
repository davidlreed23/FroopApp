//
//  FroopInfoView.swift
//  FroopProof
//
//  Created by David Reed on 5/8/23.
//

import SwiftUI
import Photos
import FirebaseStorage
import Firebase
import FirebaseAuth
import FirebaseFirestore
import Kingfisher
import SwiftUIBlurView
import MapKit
import Combine

struct FroopInfoView: View {
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject var appStateManager = AppStateManager.shared
    @ObservedObject var printControl = PrintControl.shared
    @ObservedObject var locationServices = LocationServices.shared
    @ObservedObject var froopDataListener = FroopDataListener.shared
    @ObservedObject var froopManager = FroopManager.shared
    @ObservedObject var myData = MyData.shared
    
    var db = FirebaseServices.shared.db
    @ObservedObject var hostData: UserData = UserData()
    @ObservedObject var timeZoneManager:TimeZoneManager = TimeZoneManager()
    @State private var now = Date()
    @State private var opacity = 0.0
    @State var showTypeImage: Bool = false
    @State var activeHostData: UserData = UserData()
    
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    init() {
        UITableView.appearance().backgroundColor = .clear
        
    }
    
    var body: some View {
        
        ZStack {
            FTVBackGroundComponent()
            Rectangle()
                .foregroundColor(.clear)
                .background(.ultraThinMaterial)
                .ignoresSafeArea()
            ZStack {
                ScrollView(showsIndicators: false) {
                    VStack {
                        
                        ZStack {
                            Rectangle()
                                .foregroundColor(.clear)
                                .frame(height: 200)
                                .background(Color.white.opacity(0.8))
                            
                                .cornerRadius(0)
                                .padding(.bottom, 10)
                                .padding(.leading, 0)
                                .padding(.trailing, 0)
                            
                            VStack {
                                HStack {
                                    switch AppStateManager.shared.currentStage {
                                        case .starting:
                                            Text("Froop Starts in: \(timeZoneManager.formatDuration2(durationInMinutes: AppStateManager.shared.inProgressFroop.froopStartTime.timeIntervalSince(now)/60))")
                                                .font(.system(size: 16))
                                                .fontWeight(.medium)
                                                .multilineTextAlignment(.leading)
                                                .foregroundColor(colorScheme == .dark ? Color(red: 249/255, green: 0/255, blue: 95/255) : Color(red: 249/255, green: 0/255, blue: 95/255))
                                        case .running:
                                            ZStack {
                                                Text("Froop In Progress")
                                                    .font(.system(size: 16))
                                                    .fontWeight(.medium)
                                                    .foregroundColor(colorScheme == .dark ? Color(red: 249/255, green: 0/255, blue: 95/255) : Color(red: 249/255, green: 0/255, blue: 95/255))
                                                    .multilineTextAlignment(.leading)
                                                
                                                Image(systemName: "circle.fill")
                                                    .foregroundColor(Color(red: 249/255, green: 0/255, blue: 95/255))
                                                    .modifier(ParticleEffect(pcount: 2))
                                                    .frame(width: 2, height: 2)
                                                    .offset(x: -75)
                                                
                                                Image(systemName: "circle.fill")
                                                    .foregroundColor(Color(red: 249/255, green: 0/255, blue: 95/255))
                                                    .modifier(ParticleEffect(pcount: 5))
                                                    .frame(width: 2, height: 2)
                                                    .offset(x: 75)
                                                
                                                
                                                
                                            }
                                        case .ending:
                                            Text("Froop Archive in: \(timeZoneManager.formatDuration2(durationInMinutes: (AppStateManager.shared.inProgressFroop.froopEndTime.timeIntervalSince(now)+1800)/60))")
                                                .font(.system(size: 16))
                                                .fontWeight(.medium)
                                                .foregroundColor(colorScheme == .dark ? Color(red: 249/255, green: 0/255, blue: 95/255) : Color(red: 249/255, green: 0/255, blue: 95/255))
                                                .multilineTextAlignment(.leading)
                                        case .none:
                                            Text("No Froops Scheduled")
                                                .font(.system(size: 16))
                                                .fontWeight(.medium)
                                                .foregroundColor(colorScheme == .dark ? Color(red: 249/255, green: 0/255, blue: 95/255) : Color(red: 249/255, green: 0/255, blue: 95/255))
                                                .multilineTextAlignment(.leading)
                                    }
                                }
                                
                                .padding(.leading, 20)
                                .padding(.trailing, 20)
                                .padding(.top, 15)
                                
                                HStack (alignment: .top){
                                    ZStack {
                                        Circle()
                                            .frame(width: 100, height: 100, alignment: .leading)
                                        KFImage(URL(string: AppStateManager.shared.inProgressFroop.froopHostPic))
                                            .placeholder {
                                                ProgressView()
                                            }
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 100, height: 100, alignment: .leading)
                                            .clipShape(Circle())
                                            .onTapGesture {
                                                froopManager.comeFrom = true
                                                locationServices.selectedTab = .froop
                                                froopManager.froopDetailOpen = true
                                                froopManager.selectedFroop = appStateManager.inProgressFroop
                                                froopManager.selectedFroopUUID = appStateManager.inProgressFroop.froopId
                                            }
                                        
                                    }
                                    .padding(.leading, 25)
                                    VStack (alignment: .leading){
                                        
                                        Text(AppStateManager.shared.inProgressFroop.froopName)
                                            .font(.system(size: 30))
                                            .fontWeight(.medium)
                                            .foregroundColor(.black)
                                            .multilineTextAlignment(.leading)
                                            .padding(.top)
                                        HStack {
                                            Text("Hosted by:")
                                                .font(.system(size:18))
                                                .fontWeight(.light)
                                                .foregroundColor(.black)
                                                .multilineTextAlignment(.leading)
                                            Text(activeHostData.firstName)
                                                .font(.system(size: 18))
                                                .fontWeight(.light)
                                                .foregroundColor(.black)
                                                .multilineTextAlignment(.leading)
                                            Text(activeHostData.lastName)
                                                .font(.system(size: 18))
                                                .fontWeight(.light)
                                                .foregroundColor(.black)
                                                .multilineTextAlignment(.leading)
                                                .padding(.leading, -5)
                                        }
                                        Text("Start: \(formatDate(passedDate: AppStateManager.shared.inProgressFroop.froopStartTime))")
                                            .font(.system(size:18))
                                            .fontWeight(.light)
                                            .foregroundColor(.black)
                                            .multilineTextAlignment(.leading)
                                            .padding(.top, 0)
                                        
                                    }
                                    .padding(.top, 5)
                                    .padding(.leading, 20)
                                    Spacer()
                                }
                                .padding(.top, 5)
                                Spacer()
                            }
                        }
                        
                    }
                    
                    
                    ZStack (alignment: .leading){
                        Rectangle()
                            .foregroundColor(.clear)
                            .frame(height: 100)
                            .background(Color.white.opacity(0.8))
                        //.background(.ultraThinMaterial.opacity(1))
                            .cornerRadius(10)
                            .padding(.bottom, 10)
                            .padding(.leading, 15)
                            .padding(.trailing, 15)
                        
                        VStack (alignment: .leading){
                            HStack {
                                Image("LocationIcon")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 60, height: 100)
                                    .cornerRadius(10)
                                    .padding(.top, 5)
                                    .padding(.leading, 40)
                                    .padding(.trailing, 15)
                                    .padding(.trailing, 15)
                                    .onTapGesture {
                                        print(AppStateManager.shared.activeInvitedFriends.count)
                                        froopManager.printLocationData(froopLocation: AppStateManager.shared.inProgressFroop.froopLocationCoordinate ?? CLLocationCoordinate2D(), userLocation: myData.coordinate)
                                        
                                    }
                                
                                VStack (alignment: .leading){
                                    Text(AppStateManager.shared.inProgressFroop.froopLocationtitle)
                                        .font(.system(size: 18))
                                        .fontWeight(.medium)
                                        .foregroundColor(.black)
                                        .multilineTextAlignment(.leading)
                                    
                                    Text(AppStateManager.shared.inProgressFroop.froopLocationsubtitle)
                                        .font(.system(size: 14))
                                        .fontWeight(.regular)
                                        .foregroundColor(.black)
                                        .multilineTextAlignment(.leading)
                                    
                                        .lineLimit(2)
                                        .padding(.bottom, 10)
                                }
                                .padding(.top, 10)
                                .padding(.leading, -15)
                                .padding(.trailing, 15)
                                Spacer()
                            }
                        }
                    }
                    .onTapGesture {
                        LocationServices.shared.selectedFroopTab = .map
                    }
                    
                    ZStack {
                        
                        VStack (spacing: 2) {
                            ForEach(AppStateManager.shared.activeInvitedFriends.indices, id: \.self) { index in
                                let friend = AppStateManager.shared.activeInvitedFriends[index]
                                AttendingUserCard(
                                    guestFirstName: friend.firstName,
                                    guestLastName: friend.lastName,
                                    guestURL: friend.profileImageUrl,
                                    guestLocation: friend.coordinate,
                                    froopLocation: appStateManager.inProgressFroop.froopLocationCoordinate ?? CLLocationCoordinate2D()
                                    
                                )
                            }
                        }
                        .padding(.leading, 15)
                        .padding(.trailing, 15)
                    }
                    
                    ZStack {
                        Rectangle()
                            .foregroundColor(.clear)
                            .frame(height: 200)
                            .background(Color.white.opacity(0.8))
                            .cornerRadius(10)
                            .padding(.bottom, 10)
                            .padding(.leading, 15)
                            .padding(.trailing, 15)
                    }
                    
                    Rectangle()
                        .frame(height: 100)
                        .foregroundColor(.clear)
                }
            }
            ZStack {
                FTVBackGroundComponent()
            }
            .opacity(opacity)
            .onAppear {
                if PrintControl.shared.froopCounter == 0 {
                    opacity = 1.0
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        self.opacity = 0
                    }
                }
                PrintControl.shared.froopCounter = 1
            }
            .onChange(of: AppStateManager.shared.inProgressFroop) { newValue in
                print(showTypeImage)
                showTypeImage = true
                if showTypeImage == true {
                    opacity = 1.0
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        self.opacity = 0
                    }
                }
                showTypeImage = false
                print(showTypeImage)
            }
        }
        .id(appStateManager.inProgressFroop.froopId)
        .onAppear {
            DispatchQueue.main.async {
                AppStateManager.shared.setupListener() { userData in
                    self.activeHostData = userData ?? UserData()
                }
            }
        }
        .onReceive(timer) { _ in
            now = Date()
        }
    }
    
    
    func formatDate(passedDate: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EE, h:mm a"
        let formattedDate = formatter.string(from: passedDate)
        return formattedDate
    }
}

