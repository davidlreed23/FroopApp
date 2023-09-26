//
//  DetailsHostMessageView.swift
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

struct DetailsHostMessageView: View {
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
    
    @State private var showAlert = false


    @Binding var messageEdit: Bool
    
    var body: some View {
        ZStack {
            VStack (spacing: 0){
                
                ZStack {
                    Rectangle()
                        .frame(height: 50)
                        .foregroundColor(colorScheme == .dark ? Color(red: 250/255 , green: 250/255, blue: 255/255) : Color(red: 250/255 , green: 250/255, blue: 255/255))
                    VStack {
                        Spacer()
                        
                        HStack {
                            Text("Message from the Host")
                                .font(.system(size: 14))
                                .foregroundColor(.black)
                                .opacity(0.7)
                                .fontWeight(.semibold)
                                .padding(.top, 10)
                                .padding(.leading, 15)
                                .padding(.bottom, 15)
                            Spacer()
                            if FirebaseServices.shared.uid == froopManager.selectedFroop.froopHost {
                                Text("Edit Message")
                                    .foregroundColor(.blue)
                                    .font(.system(size: 14))
                                    .fontWeight(.light)
                                    .opacity(0.7)
                                    .multilineTextAlignment(.center)
                                    .padding(.bottom, 10)
                                    .padding(.trailing, 15)
                                    .offset(y: 2)
                                    .onTapGesture {
                                        messageEdit = true
                                    }
                            } else {
                                Text("")
                            }
                            
                        }
                        .padding(.trailing, 25)
                        .padding(.leading, 15)
                    }
                    .frame(maxHeight: 50)
                }
                Divider()
                ZStack {
                    Rectangle()
                        .frame(height: 125)
                        .foregroundColor(colorScheme == .dark ? Color(red: 250/255 , green: 250/255, blue: 255/255) : Color(red: 250/255 , green: 250/255, blue: 255/255))
                    HStack (alignment: .top) {
                        ZStack {
                            Rectangle()
                                .frame(maxWidth: 75, maxHeight: 125)
                                .foregroundColor(.clear)
                                .ignoresSafeArea()
                            Image("angels_bk")
                                .resizable()
                                .scaledToFit()
                                .frame(maxWidth: 75, maxHeight: 125)
                                .ignoresSafeArea()
                            Image(systemName: "play.circle")
                                .foregroundColor(.white)
                                .font(.system(size: 28))
                        }
                        .onTapGesture {
                            self.showAlert = true  // Update this line
                        }
                        .alert(isPresented: $showAlert) {  // Add this block
                            Alert(title: Text("Alert"), message: Text("This button is not active yet."), dismissButton: .default(Text("OK")))
                        }
                        .padding(.trailing, 10)
                        Text (froopManager.selectedFroop.froopMessage)
                            .font(.system(size: 16))
                            .fontWeight(.light)
                            .padding(.top, 5)
                            .padding(.bottom, 5)
                        Spacer()
                        
                    }
                    .padding(.trailing, 25)
                    .padding(.leading, 25)
                }
                
            }
        }
        Divider()
    }
}




