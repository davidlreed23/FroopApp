//
//  ProfileList.swift
//  FroopProof
//
//  Created by David Reed on 1/19/23.
//

import SwiftUI
import UIKit
import Firebase
import FirebaseFirestore
import FirebaseFirestoreSwift
import FirebaseAuth
import FirebaseCore
import FirebaseStorage
import iPhoneNumberField

struct ProfileListView: View {
    @ObservedObject var froopManager = FroopManager.shared
    @ObservedObject var locationManager = LocationManager.shared
    @ObservedObject var myData = MyData.shared
    @ObservedObject var photoData: PhotoData
    @ObservedObject var printControl = PrintControl.shared
    @ObservedObject var firebaseServices = FirebaseServices.shared
    @ObservedObject var userSettings = UserSettings.shared
    @State var showEditView = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    var uid = FirebaseServices.shared.uid
    var db = FirebaseServices.shared.db
    @State private var profileImageUrl: URL?
    
    var body: some View {
        ZStack (alignment: .top){
           
            VStack {
                Rectangle()
                    .fill(.clear)
                    .frame(height: 115)
                VStack (alignment: .leading) {
                    
                    Rectangle()
                        .fill(.clear)
                        .frame(height: 25)
                    
                    Divider()
                    List {
                        Section(header: Text("Name")) {
                            TextField("First Name", text: $myData.firstName)
                            TextField("Last Name", text: $myData.lastName)
                            iPhoneNumberField("Phone Number", text: $myData.phoneNumber)
                                .font(.subheadline)
                        }
                        Section(header: Text("Permissions")) {
                            Toggle("Calendar", isOn: $userSettings.calendarPermission)
                                .onChange(of: userSettings.locateNowPermission) { newValue in
                                    if newValue {
                                        // New value is true, user is trying to grant permission
                                        userSettings.requestCalendarAccess { _ in
                                            print("calendar access granted")
                                        }
                                    } else {
                                        // User is trying to revoke permission, guide them to settings
                                        userSettings.openAppSettings()
                                    }
                                }
                            Toggle("Photo Library", isOn: $userSettings.photoLibraryPermission)
                                .onChange(of: userSettings.locateNowPermission) { newValue in
                                    if newValue {
                                        // New value is true, user is trying to grant permission
                                        userSettings.requestPhotoLibraryAuthorization { _ in
                                            print("calendar access granted")
                                        }
                                    } else {
                                        // User is trying to revoke permission, guide them to settings
                                        userSettings.openAppSettings()
                                    }
                                }
                            Toggle("Location Tracking Always", isOn: $userSettings.trackAlwaysPermission)
                                .onChange(of: userSettings.locateNowPermission) { newValue in
                                    if newValue {
                                        // New value is true, user is trying to grant permission
                                        locationManager.requestAlwaysAuthorization()
                                    } else {
                                        // User is trying to revoke permission, guide them to settings
                                        userSettings.openAppSettings()
                                    }
                                }
                            Toggle("Alerts", isOn: $userSettings.alertsPermission)
                                .onChange(of: userSettings.locateNowPermission) { newValue in
                                    if newValue {
                                        // New value is true, user is trying to grant permission
                                        userSettings.requestNotificationPermission()
                                    } else {
                                        // User is trying to revoke permission, guide them to settings
                                        userSettings.openAppSettings()
                                    }
                                }
                            Toggle("Notifications", isOn: $userSettings.notificationsPermission)
                                .onChange(of: userSettings.locateNowPermission) { newValue in
                                    if newValue {
                                        // New value is true, user is trying to grant permission
                                        userSettings.requestNotificationPermission()
                                    } else {
                                        // User is trying to revoke permission, guide them to settings
                                        userSettings.openAppSettings()
                                    }
                                }
                        }
                    }
                    .environment(\.defaultMinListRowHeight, 5)
                    .font(.subheadline)
                    .frame(maxHeight: 600)
                    
                    
                }
                Spacer()
                HStack {
                    Button("Sign Out") {
                        do {
                            FirebaseServices.shared.stopAllListeners()
                            try Auth.auth().signOut()
                        } catch {
                            PrintControl.shared.printErrorMessages("Error signing out: \(error.localizedDescription)")
                        }
                    }
                }
                Spacer()
            }
         
        }
        FroopBaseTView(showEditView: $showEditView)
            .fullScreenCover(isPresented: $showEditView, onDismiss: nil, content: {
                EditProfileView(photoData: photoData, showEditView: self.$showEditView, showAlert: self.$showAlert, alertMessage: self.$alertMessage, urlHolder: MyData.shared.profileImageUrl, firstName: "", lastName: "", phoneNumber: "", addressNumber: "", addressStreet: "", unitName: "", addressCity: "", addressState: "", addressZip: "", addressCountry: "")
            })
    }
}




