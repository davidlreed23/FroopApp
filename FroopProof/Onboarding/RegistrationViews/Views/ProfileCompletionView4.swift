//
//  ProfileCompletionView.swift
//  FroopProof
//
//  Created by David Reed on 1/19/23.
//

import SwiftUI
import MapKit
import Firebase
import FirebaseStorage
import Kingfisher

struct ProfileCompletionView4: View {
    
    @ObservedObject var appStateManager = AppStateManager.shared
    @ObservedObject var printControl = PrintControl.shared
    @ObservedObject var locationServices = LocationServices.shared
    @ObservedObject var froopDataListener = FroopDataListener.shared
    @State private var isProfileImageSelected = false
    var db = FirebaseServices.shared.db
    @AppStorage("ProfileCompletionCurrentPage") var ProfileCompletionCurrentPage = 4
    @ObservedObject var myData = MyData.shared
    @ObservedObject var photoData = PhotoData()
    @ObservedObject var timeZoneManager: TimeZoneManager = TimeZoneManager()
    
    @State private var isShowingOTPAlert = false
    @State private var enteredOTP: String = ""
    @State private var isSaving = false
    @State var showProfileImagePicker = false
    @State private var headImage = UIImage(named: "profileImage")!
    @State private var avatarImage = UIImage()
    @State var selectedImage: UIImage?
    @State var urlHolder: String = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var selectedTimeZoneIndex = 0
    @State private var progress: Double = 0
    @State private var status: String = ""
    @State private var showProgressView: Bool = false
    let timeZoneIdentifiers = TimeZone.knownTimeZoneIdentifiers.sorted()
    
    let largestCityTimeZones = [
        "America/Puerto_Rico",
        "America/New_York",
        "America/Chicago",
        "America/Houston",
        "America/Denver",
        "America/Phoenix",
        "America/Los_Angeles",
        "America/San_Francisco",
        "America/Anchorage",
        "America/Honolulu"
    ]
    
    var PCtotalPages = 6
    
    @State private var formattedPhoneNumber: String = ""
    
    var otpAlert: Alert {
        Alert(title: Text("Enter OTP"),
              message: Text("Please enter the received OTP code:"),
              primaryButton: .default(Text("Verify"), action: {
                  verifyOTP(enteredOTP: enteredOTP)
              }),
              secondaryButton: .cancel()
        )
    }
    
 
    var body: some View {
        NavigationView{
            ZStack (alignment: .top){
                
                Rectangle()
                    .frame(minWidth: 0,maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                    .foregroundColor(.black)
                    .opacity(0.2)
                    .ignoresSafeArea()
                    .onAppear {
                        formattedPhoneNumber = formatPhoneNumber(myData.phoneNumber)
                        if myData.phoneNumber != "" {
                            ProfileCompletionCurrentPage = 6
                        }
                    }
                
                VStack {
                    ZStack(alignment: .top) {
                        
                        Rectangle()
                            .frame(minWidth: 0,maxWidth: .infinity, minHeight: 225, maxHeight: 225, alignment: .top)
                            .foregroundColor(.black)
                            .opacity(0.5)
                            .ignoresSafeArea()
                        
                        Spacer()
                        
                        
                        HStack{
                            
                            Spacer()
                            
                            Text("Profile Setup")
                                .foregroundColor(.white)
                                .fontWeight(.bold)
                            
                            Spacer()
                        }
                        .offset(y: -30)
                        HStack{
                            
                            Spacer()
                            
                            Button(action: {
                            
                                showProfileImagePicker = true
                                
                            }) {
                                
                                VStack{
                                    
                                    ZStack{
                                        
                                        Image(uiImage: headImage)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 126, height: 126)
                                            .clipShape(Circle())
                                        
                                        KFImage(URL(string: MyData.shared.profileImageUrl))
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 126, height: 126)
                                            .clipShape(Circle())
                                            .onTapGesture {
                                                showProfileImagePicker = true
                                            }
                                        
                                        Image(uiImage: avatarImage)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 126, height: 126)
                                            .clipShape(Circle())
                                    }
                                    .padding(.top, 75)
                                  
                                    
                                    Text("Profile Picture")
                                        .font(.system(size: 16, weight: .regular))
                                        .foregroundColor(.secondary)
                                        
                                }
                                .padding(.top, -40)
                                
                            
                            
                            .sheet(isPresented: $showProfileImagePicker, onDismiss: {
                                isProfileImageSelected = true
                            }, content: {
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
                            TextField("First Name", text: $myData.firstName)
                            TextField("Last Name", text: $myData.lastName)
                        }
                        Section(header: Text("Contact")) {
                            TextField("Phone Number", text: $formattedPhoneNumber)
                                .onChange(of: formattedPhoneNumber) { newValue in
                                    // Update myData.phoneNumber with cleaned (unformatted) value
                                    myData.phoneNumber = removePhoneNumberFormatting(newValue)
                                }
                        }
                        Section(header: Text("Time Zone")) {
                            Picker("", selection: $myData.timeZone) {
                                ForEach(timeZoneIdentifiers, id: \.self) { timeZoneIdentifier in
                                    Text(timeZoneIdentifier)
                                }
                            }
                        }
                    }
                    .scrollContentBackground(.hidden)
                    .frame(maxHeight: .infinity)
                    .multilineTextAlignment(.leading)
                    .padding(.top)
                    
                }
                if isSaving {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                        .scaleEffect(2)
                }
                if showProgressView {
                       ProgressView()
                   }
                
            }
            

            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button(action: {
                        verifyOTP(enteredOTP: MyData.shared.phoneNumber)
                        FirebaseServices.shared.saveUserFcmToken()
                    }) {
                        Text("Save")
                            .foregroundColor(.white)
                        Image(systemName: "square.and.arrow.up.fill")
                            .foregroundColor(.white)
                    }
                }
            }
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Missing Information"),
                      message: Text(alertMessage),
                      dismissButton: .default(Text("OK")))
            }
        }
        .disabled(isSaving)
    }
    
    
    
    func saveProfile() {
        isSaving = true
        PrintControl.shared.printProfile("-ProfileCompletionView4: Function: saveProfile firing")
        if MyData.shared.firstName.isEmpty ||
            MyData.shared.lastName.isEmpty ||
            MyData.shared.phoneNumber.isEmpty ||
            !isProfileImageSelected {
            // Check what fields are missing
            var missingFields: [String] = []
            
            if !isProfileImageSelected {
                   missingFields.append("Required - Profile Picture")
               }
            if MyData.shared.firstName.isEmpty {
                missingFields.append("Required - First Name")
            }
            if MyData.shared.lastName.isEmpty {
                missingFields.append("Required - Last Name")
            }
            if MyData.shared.phoneNumber.isEmpty {
                missingFields.append("Required - Phone Number")
            }
            if avatarImage.size == headImage.size && MyData.shared.profileImageUrl.isEmpty {
                missingFields.append("Required - Profile Picture")
            }
            // Show appropriate alert message
            if missingFields.count == 1 {
                alertMessage = "Please add your \(missingFields[0]) for this device."
            } else {
                let lastField = missingFields.removeLast()
                let fields = missingFields.joined(separator: ", ") + " and " + lastField
                alertMessage = "Please add a \(fields) and your Mobile Number associated with this device."
            }
            showAlert = true
        } else {
            // Validate phone number
            if !isValidPhoneNumber(MyData.shared.phoneNumber) {
                alertMessage = "Please enter a valid phone number."
                showAlert = true
                return
            }
            // Set the froopUserID to the current user's UID
            MyData.shared.froopUserID = FirebaseServices.shared.uid
            
            // Assign the user's correct TimeZone identifier to the timeZone property
            if let location = LocationManager.shared.userLocation {
                let geoCoder = CLGeocoder()
                geoCoder.reverseGeocodeLocation(location) { placemarks, error in
                    if let error = error {
                        PrintControl.shared.printProfile("Error getting location address: \(error.localizedDescription)")
                    } else if let placemarks = placemarks, let placemark = placemarks.first {
                        MyData.shared.timeZone = placemark.timeZone?.identifier ?? TimeZone.current.identifier
                        MyData.shared.geoPoint = GeoPoint(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude) // Set the geoPoint property
                    } else {
                        MyData.shared.timeZone = TimeZone.current.identifier
                        MyData.shared.geoPoint = GeoPoint(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude) // Set the geoPoint property
                    }
                }
            } else {
                MyData.shared.timeZone = TimeZone.current.identifier
            }
            if MyData.shared.profileImageUrl != "" {
                PrintControl.shared.printProfile("Profile Image Already Exists!")
                saveUserDataToFirestore()
            } else {
                uploadImageToFirebase { url in
                    // Update userData with profileImageUrl
                    MyData.shared.profileImageUrl = url
                    saveUserDataToFirestore()
                }
            }
        }
        
        isSaving = false
    }
    
    private func saveUserDataToFirestore() {
        let userRef = db.collection("users").document(MyData.shared.froopUserID)
        let userDocumentData: [String: Any] = [
            "froopUserID": MyData.shared.froopUserID,
            "firstName": MyData.shared.firstName,
            "lastName": MyData.shared.lastName,
            "phoneNumber": removePhoneNumberFormatting(MyData.shared.phoneNumber),
            "addressNumber": MyData.shared.addressNumber,
            "addressStreet": MyData.shared.addressStreet,
            "unitName": MyData.shared.unitName,
            "addressCity": MyData.shared.addressCity,
            "addressState": MyData.shared.addressState,
            "addressZip": MyData.shared.addressZip,
            "addressCountry": MyData.shared.addressCountry,
            "profileImageUrl": MyData.shared.profileImageUrl,
            "timeZone": MyData.shared.timeZone,
            "coordinate": MyData.shared.geoPoint
        ]
        userRef.setData(userDocumentData) { error in
            if let error = error {
                PrintControl.shared.printProfile("Error creating user document: \(error)")
            } else {
                PrintControl.shared.printProfile("User document created")
                
                // Set up required collections and documents
                _ = userRef.collection("myFroops")
                let froopDecisionsRef = userRef.collection("froopDecisions")
                let friendsRef = userRef.collection("friends")
                
                let froopListsRef = froopDecisionsRef.document("froopLists")
                froopListsRef.setData(["placeholder": []], merge: true)
                
                let myArchivedListRef = froopListsRef.collection("myArchivedList").document("placeholder")
                myArchivedListRef.setData(["placeholder": []], merge: true)
                
                let myConfirmedListRef = froopListsRef.collection("myConfirmedList").document("placeholder")
                myConfirmedListRef.setData(["placeholder": []], merge: true)
                
                let myDeclinedListRef = froopListsRef.collection("myDeclinedList").document("placeholder")
                myDeclinedListRef.setData(["placeholder": []], merge: true)
                
                let myInvitesListRef = froopListsRef.collection("myInvitesList").document("placeholder")
                myInvitesListRef.setData(["placeholder": []], merge: true)
                
                let friendListRef = friendsRef.document("friendList")
                friendListRef.updateData([
                    "friendUIDs": FieldValue.arrayUnion([]),
                ])
                
                // Present the next view in the series
                ProfileCompletionCurrentPage = 5
            }
        }
    }
    
    func removePhoneNumberFormatting(_ phoneNumber: String) -> String {
        let cleanedPhoneNumber = phoneNumber.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        return cleanedPhoneNumber
    }
    
    private func checkForExistingFroops(completion: @escaping (Bool) -> Void) {
        PrintControl.shared.printProfile("-ProfileCompletionView4: Function: checkForExistingFroops firing")
        let uid = FirebaseServices.shared.uid
        db.collection("froops").whereField("uid", isEqualTo: uid).getDocuments { (snapshot, error) in
            if let error = error {
                PrintControl.shared.printErrorMessages("Error checking for existing Froops: \(error)")
                completion(false)
                return
            }
            let hasExistingFroops = !snapshot!.documents.isEmpty
            completion(hasExistingFroops)
        }
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
    
    func formatPhoneNumber(_ phoneNumber: String) -> String {
        let cleanedPhoneNumber = phoneNumber.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        let mask = "(XXX) XXX-XXXX"
        var result = ""
        var index = cleanedPhoneNumber.startIndex
        for ch in mask where index < cleanedPhoneNumber.endIndex {
            if ch == "X" {
                result.append(cleanedPhoneNumber[index])
                index = cleanedPhoneNumber.index(after: index)
            } else {
                result.append(ch)
            }
        }
        return result
    }

    func isValidPhoneNumber(_ phoneNumber: String) -> Bool {
        PrintControl.shared.printLogin("-Login: Function: isValidPhoneNumber firing")
        
        // Strip out non-numeric characters
        let numericOnlyString = phoneNumber.filter { $0.isNumber }
        
        // Ensure there are exactly 10 digits
        guard numericOnlyString.count == 10 else {
            return false
        }

        // Now, verify if the input format matches any of the desired formats
        let phoneNumberPatterns = [
            "^\\(\\d{3}\\) \\d{3}-\\d{4}$",  // (123) 999-9999
            "^\\d{10}$",                    // 1239999999
            "^\\d{3}\\.\\d{3}\\.\\d{4}$",  // 123.999.9999
            "^\\d{3} \\d{3} \\d{4}$"       // 123 999 9999
        ]

        return phoneNumberPatterns.contains { pattern in
            let predicate = NSPredicate(format: "SELF MATCHES %@", pattern)
            return predicate.evaluate(with: phoneNumber)
        }
    }
    
    func sendOTP(phoneNumber: String) {
        PhoneAuthProvider.provider().verifyPhoneNumber(phoneNumber, uiDelegate: nil) { (verificationID, error) in
            if let error = error {
                // Handle the error
                print(error.localizedDescription)
                return
            }
            // If there's no error, save the verificationID
            UserDefaults.standard.set(verificationID, forKey: "authVerificationID")
            isShowingOTPAlert = true
        }
    }
    
    func verifyOTP(enteredOTP: String) {
        guard let verificationID = UserDefaults.standard.string(forKey: "authVerificationID") else { return }
        let credential = PhoneAuthProvider.provider().credential(withVerificationID: verificationID, verificationCode: enteredOTP)
        
        Auth.auth().signIn(with: credential) { (authResult, error) in
            if let error = error {
                // Handle the error
                print(error.localizedDescription)
                return
            }
            // User is signed in successfully!
            // Continue with the profile completion or any other task
            
            saveProfile()
        }
    }
}


