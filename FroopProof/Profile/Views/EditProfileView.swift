//
//  EditProfileView.swift
//  FroopProof
//
//  Created by David Reed on 1/19/23.
//

import Combine
import SwiftUI
import Foundation
import MapKit
import UIKit
import Firebase
import FirebaseAuth
import FirebaseStorage
import FirebaseFirestore
import FirebaseFirestoreSwift
import CoreLocation
import Kingfisher


struct EditProfileView: View {
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject var printControl = PrintControl.shared
    @ObservedObject var userSettings = UserSettings.shared
    @ObservedObject var locationManager = LocationManager.shared
    var db = FirebaseServices.shared.db
    var uid = FirebaseServices.shared.uid
    //@ObservedObject var myData = MyData.shared
    @ObservedObject var photoData: PhotoData
    @Binding var showEditView: Bool
    @Binding var showAlert: Bool
    @Binding var alertMessage: String
    
    @State private var isSaving = false
    @State private var showSheet = true
    @State var showProfileImagePicker = false
    @State private var headImage = UIImage(named: "profileImage")!
    @State private var avatarImage = UIImage()
    @State var selectedImage: UIImage?
    @State var urlHolder: String = ""
    @State var existingImageUrl: String = MyData.shared.profileImageUrl
    @State var firstName: String = ""
    @State var lastName: String = ""
    @State var phoneNumber: String = ""
    @State var addressNumber: String = ""
    @State var addressStreet: String = ""
    @State var unitName: String = ""
    @State var addressCity: String = ""
    @State var addressState: String = ""
    @State var addressZip: String = ""
    @State var addressCountry: String = ""
    
    
    init(photoData: PhotoData, showEditView: Binding<Bool>, showAlert: Binding<Bool>, alertMessage: Binding<String>, urlHolder: String, firstName: String, lastName: String, phoneNumber: String, addressNumber: String, addressStreet: String, unitName: String, addressCity: String, addressState: String, addressZip: String, addressCountry: String) {
        self.photoData = photoData
        self._showEditView = showEditView
        self._showAlert = showAlert
        self._alertMessage = alertMessage
        self._firstName = State(initialValue: MyData.shared.firstName)
        self._lastName = State(initialValue: MyData.shared.lastName)
        self._phoneNumber = State(initialValue: MyData.shared.phoneNumber)
        
    }
    
    
    var body: some View {
        NavigationView {
            ZStack (alignment: .top){
                Rectangle()
                    .frame(minWidth: 0,maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                    .foregroundColor(.gray)
                    .opacity(0.2)
                    .ignoresSafeArea()
                VStack {
                    ZStack(alignment: .top) {
                        Rectangle()
                            .frame(minWidth: 0,maxWidth: .infinity, minHeight: 175, maxHeight: 175, alignment: .top)
                            .foregroundColor(.black)
                            .opacity(0.5)
                            .ignoresSafeArea()
                            .offset(y: -50)
                        HStack{
                            
                            Text("Back")
                                .foregroundColor(.white)
                                .fontWeight(.medium)
                                .padding(.leading, 10)
                                .onTapGesture {
                                    showEditView = false
                                }
                            Spacer()
                            
                            
                            Button{
                                if avatarImage.size.width != 0 {
                                    uploadImageToFirebase { url in
                                        // Update MyData.shared.profileImageUrl with the new URL
                                        MyData.shared.profileImageUrl = url
                                        saveUserDataToFirestore()
                                    }
                                } else if existingImageUrl.isEmpty {
                                    // Force the user to select an image
                                    showAlert = true
                                    alertMessage = "Please select a profile image."
                                } else {
                                    saveUserDataToFirestore()
                                }
                            }label:{
                                Text("Save")
                                    .foregroundColor(colorScheme == .dark ? .white : .white)                                    .fontWeight(.medium)
                                Image(systemName: "square.and.arrow.up.fill")
                                .foregroundColor(colorScheme == .dark ? .white : .white)                            }
                            .padding(.trailing, 10)
                        }
                        .offset(y: 0)
                        HStack{
                            Spacer()
                            Button {
                                showProfileImagePicker = true
                                
                            } label: {
                                VStack{
                                    ZStack{
                                        
                                        Image(uiImage: headImage)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 126, height: 126)
                                            .clipShape(Circle())
                                            .padding()
                                        
                                        KFImage(URL(string: MyData.shared.profileImageUrl))
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 126, height: 126)
                                            .clipShape(Circle())
                                            .padding()
                                            .onTapGesture {
                                                showProfileImagePicker = true
                                            }
                                        Image(uiImage: avatarImage)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 126, height: 126)
                                            .clipShape(Circle())
                                            .padding()
                                    }
                                    
                                    Text("Tap to Edit Profile Picture")
                                        .font(.system(size: 14, weight: .light))
                                        .foregroundColor(.gray)
                                        .offset(y: -10)
                                    Text("Or Change Any Details Below")
                                        .font(.system(size: 14, weight: .light))
                                        .foregroundColor(.gray)
                                        .offset(y: -10)
                                }
                                .fullScreenCover(isPresented: $showProfileImagePicker, onDismiss: nil, content: {
                                    PhotoPicker(avatarImage: $avatarImage)
                                })
                                .padding(.top, -40)
                                
                            }
                            Spacer()
                        }
                        .padding(.top, 50)
                    }
                    
                    Form {
                        Section(header: Text("Name")) {
                            TextField("First Name", text: $firstName)
                            TextField("Last Name", text:  $lastName)
                        }
                        Section(header: Text("Contact")) {
                            TextField("Phone Number", text:  $phoneNumber)
                        }
                        Section(header: Text("Permissions")) {
                            Toggle("Calendar", isOn: $userSettings.calendarPermission)
                                .onChange(of: userSettings.locateNowPermission, initial: userSettings.locateNowPermission) { oldValue, newValue in
                                    if newValue {
                                        // New value is true, user is trying to grant permission
                                        userSettings.requestCalendarAccess { _ in
                                            print("calendar access granted")
                                        }
                                    } else if oldValue != newValue {
                                        // User is trying to revoke permission, guide them to settings
                                        userSettings.openAppSettings()
                                    }
                                }

                            Toggle("Photo Library", isOn: $userSettings.photoLibraryPermission)
                                .onChange(of: userSettings.locateNowPermission, initial: userSettings.locateNowPermission) { oldValue, newValue in
                                    if newValue {
                                        // New value is true, user is trying to grant permission
                                        userSettings.requestPhotoLibraryAuthorization { _ in
                                            print("photo library access granted")
                                        }
                                    } else if oldValue != newValue {
                                        // User is trying to revoke permission, guide them to settings
                                        userSettings.openAppSettings()
                                    }
                                }

                            Toggle("Location Tracking Always", isOn: $userSettings.trackAlwaysPermission)
                                .onChange(of: userSettings.locateNowPermission, initial: userSettings.locateNowPermission) { oldValue, newValue in
                                    if newValue {
                                        // New value is true, user is trying to grant permission
                                        locationManager.requestAlwaysAuthorization()
                                    } else if oldValue != newValue {
                                        // User is trying to revoke permission, guide them to settings
                                        userSettings.openAppSettings()
                                    }
                                }

                            Toggle("Alerts", isOn: $userSettings.alertsPermission)
                                .onChange(of: userSettings.locateNowPermission, initial: userSettings.locateNowPermission) { oldValue, newValue in
                                    if newValue {
                                        // New value is true, user is trying to grant permission
                                        userSettings.requestNotificationPermission()
                                    } else if oldValue != newValue {
                                        // User is trying to revoke permission, guide them to settings
                                        userSettings.openAppSettings()
                                    }
                                }

                            Toggle("Notifications", isOn: $userSettings.notificationsPermission)
                                .onChange(of: userSettings.locateNowPermission, initial: userSettings.locateNowPermission) { oldValue, newValue in
                                    if newValue {
                                        // New value is true, user is trying to grant permission
                                        userSettings.requestNotificationPermission()
                                    } else if oldValue != newValue {
                                        // User is trying to revoke permission, guide them to settings
                                        userSettings.openAppSettings()
                                    }
                                }
                        }
                    }
                    .scrollContentBackground(.hidden)
                    
                }
                if isSaving {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                        .scaleEffect(2)
                }
                
            }
//            .navigationTitle("Froop Beta 3")
//            .navigationBarTitleDisplayMode(.inline)
//            .navigationBarTitleDisplayMode(.inline)
//            .toolbarBackground(Color.gray, for: .navigationBar)
//            .toolbarBackground(.visible, for: .navigationBar)
//            .toolbarColorScheme(.dark, for: .navigationBar)
//            .toolbar{
//                ToolbarItemGroup(placement: .navigationBarTrailing) {
//                    
//                }
//            }
        }
        .disabled(isSaving)
    }
    
    
    private func saveUserDataToFirestore() {
        isSaving = true
        let uid = Auth.auth().currentUser?.uid ?? ""
        let currentPhotoUID = photoData.id
        let docRef = db.collection("users").document(uid)
        let docRef2 = db.collection("photos").document("profiles").collection("profilePhotos").document(currentPhotoUID)
        MyData.shared.profileImageUrl = urlHolder
        docRef.updateData([
            "firstName": self.firstName,
            "lastName": self.lastName,
            "phoneNumber": self.phoneNumber,
            "profileImageUrl": photoData.url,
            "coordinate": MyData.shared.geoPoint
        ])
        docRef2.setData([
            "id": self.photoData.id,
            "uid": self.photoData.uid,
            "froopUUID": self.photoData.froopUUID,
            "url": self.photoData.url,
            "photoCoord": self.photoData.photoCoord,
            //"photoLatitude": self.photoData.photoCoord.coordinate.latitude,
            //"photoLongitude": self.photoData.photoCoord.coordinate.longitude,
            "dateCreated": self.photoData.dateCreated,
            "title": self.photoData.title,
        ])
        if LocationManager.shared.locationUpdateTimerOn == true {
            TimerServices.shared.shouldCallupdateUserLocationInFirestore = true
        }
        if AppStateManager.shared.stateTransitionTimerOn == true {
            TimerServices.shared.shouldCallAppStateTransition = true
        }
        isSaving = false
        showEditView = false
    }
    
    
    
    private func uploadImageToFirebase(completion: @escaping (String) -> Void) {
        PrintControl.shared.printProfile("-ProfileCompletionView4: Function: uploadImageToFirebase firing")
        let uid = FirebaseServices.shared.uid
        
        // Fetch user data from Firestore
        Firestore.firestore().collection("users").document(uid).getDocument { (document, error) in
            if let document = document, document.exists {
                // If the profileImageURL already exists, use it
                if let profileImageURL = document.data()?["profileImageURL"] as? String {
                    completion(profileImageURL)
                } else {
                    // If the profileImageURL does not exist, create a new one
                    let ref = Storage.storage().reference(withPath: "ProfilePic/\(uid).jpg")
                    guard let imageData = self.avatarImage.jpegData(compressionQuality: 1.0) else { return }
                    let metaData = StorageMetadata()
                    metaData.contentType = "image/jpeg"
                    
                    ref.putData(imageData, metadata: metaData) { metadata, err in
                        if let err = err {
                            PrintControl.shared.printErrorMessages("Failed to push image to Storage \(err)")
                            return
                        }
                        
                        ref.downloadURL { url, err in
                            if let err = err {
                                PrintControl.shared.printErrorMessages("Failed to retrieve downloadURL: \(err)")
                                return
                            }
                            let urlStr = url?.absoluteString ?? ""
                            PrintControl.shared.printProfile("Successfully stored image with url:  \(urlStr)")
                            PrintControl.shared.printProfile("*******\(urlStr)")
                            photoData.uid = FirebaseServices.shared.uid
                            photoData.froopUUID = ""
                            photoData.url = urlStr
                            //photoData.photoCoord = LocationManager.shared.userLocation
                            photoData.photoLatitude = LocationManager.shared.userLocation?.coordinate.latitude ?? 0.0
                            photoData.photoLongitude = LocationManager.shared.userLocation?.coordinate.longitude ?? 0.0
                            photoData.dateCreated = Date.now
                            photoData.title = "Photo of Me"
                            
                            // Save the new profileImageURL to Firestore
                            Firestore.firestore().collection("users").document(uid).setData(["profileImageURL": urlStr], merge: true) { (error) in
                                if let error = error {
                                    PrintControl.shared.printErrorMessages("Failed to save profileImageURL to Firestore: \(error)")
                                } else {
                                    PrintControl.shared.printProfile("Successfully saved profileImageURL to Firestore.")
                                    completion(urlStr)
                                }
                            }
                        }
                    }
                }
            } else {
                PrintControl.shared.printErrorMessages("Failed to fetch user data from Firestore: \(error?.localizedDescription ?? "Unknown error")")
            }
        }
    }
}




