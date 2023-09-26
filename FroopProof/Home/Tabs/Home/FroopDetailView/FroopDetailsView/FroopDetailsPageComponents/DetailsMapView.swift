//
//  DetailsMapView.swift
//  Design_Layouts
//
//  Created by David Reed on 6/20/23.
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

struct DetailsMapView: View {
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
    
    var body: some View {
        ZStack {
            Rectangle()
                .frame(height: 75)
                .foregroundColor(colorScheme == .dark ? Color(red: 220/255 , green: 220/255, blue: 225/255) : Color(red: 220/255 , green: 220/255, blue: 225/255))
    
            HStack (alignment: .center) {
                Image(systemName: "mappin.and.ellipse")
                    .font(.system(size: 24))
                    .foregroundColor(colorScheme == .dark ? Color(red: 249/255, green: 0/255, blue: 98/255 ) : Color(red: 249/255, green: 0/255, blue: 98/255 ))
                    .padding(.trailing, 15)
                
                VStack (alignment: .leading){
                    Text(froopManager.selectedFroop.froopLocationtitle)
                        .foregroundColor(colorScheme == .dark ? .black : .black)
                        .opacity(0.7)
                        .font(.system(size: 16))
                        .fontWeight(.semibold)
                    Text(froopManager.selectedFroop.froopLocationsubtitle)
                        .foregroundColor(colorScheme == .dark ? .black : .black)
                        .opacity(0.7)
                        .font(.system(size: 12))
                        .lineLimit(2)
                    
                }
                
                Spacer()
                
                Button () {
                    froopManager.froopMapOpen = true
                } label: {
                    ZStack {
                        
                        Image("mapImage")
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: 75, maxHeight: 75)
                        Rectangle()
                            .frame(width: 75, height: 75)
                            .foregroundColor(colorScheme == .dark ? .black : .black)
                            .opacity(0.4)
                        
                        VStack  {
                            Text("Open")
                                .foregroundColor(colorScheme == .dark ? .white : .white)
                                .font(.system(size: 16))
                            Text("Map")
                                .foregroundColor(colorScheme == .dark ? .white : .white)
                                .font(.system(size: 16))
                        }
                        .font(.system(size: 12))
                    }
                }
                
            }
            .ignoresSafeArea()
            .padding(.leading, 25)
        }
        Divider()
    }
}


