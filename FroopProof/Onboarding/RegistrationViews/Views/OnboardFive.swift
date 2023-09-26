//
//  OnboardFour.swift
//  FroopProof
//
//  Created by David Reed on 9/21/23.
//



import SwiftUI
import MapKit
import Firebase
import FirebaseStorage
import Kingfisher

struct OnboardFive: View {
    @ObservedObject var photoData = PhotoData()
    @ObservedObject var myData = MyData.shared
    @State var address: String = ""
    @State var city: String = ""
    @State var state: String = ""
    @State var zipcode: String = ""
    @State private var isKeyboardShown: Bool = false
    @State private var keyboardHeight: CGFloat = 0
    @State private var isSaving = false
    @State var showProfileImagePicker = false
    @State private var showAlert = false
    @State private var avatarImage = UIImage()
    @State private var isProfileImageSelected = false
    @State private var headImage = UIImage(named: "profileImage")!
    @State private var alertMessage = ""
    @Binding var selectedTab: OnboardingTab
    @Binding var ProfileCompletionCurrentPage: Int

    let imageW: Font.Weight = .thin
    let fontS = Font.system(size: 35)
    var body: some View {
        ZStack {
            VStack {
                
                Rectangle()
                    .fill(Color(red: 235/255, green: 235/255, blue: 250/255))
                    .frame(height: UIScreen.main.bounds.height / 2)
                Spacer()
            }
            
            VStack {
                Text("SELECT A PROFILE IMAGE.")
                    .font(.system(size: 18))
                    .fontWeight(.semibold)
                    .foregroundColor(Color(red: 249/255, green: 0/255, blue: 98/255))
                    .padding(.top, UIScreen.main.bounds.height / 2 + 10)
                
                Text("Select a picture for your profile.  This is what people will see when you attend.")
                    .font(.system(size: 24))
                    .fontWeight(.light)
                    .foregroundColor(.black)
                    .opacity(/*@START_MENU_TOKEN@*/0.8/*@END_MENU_TOKEN@*/)
                    .padding(.leading, 35)
                    .padding(.trailing, 35)
                    .padding(.top, 25)
                    .multilineTextAlignment(.center)
                VStack (spacing: 0){
                    Text("FroopId \(myData.froopUserID)")
                    Text("First Name \(myData.firstName)")
                    Text("Last Name \(myData.lastName)")
                    Text("Address \(myData.addressStreet)")
                    Text("City \(myData.addressCity)")
                    Text("State \(myData.addressState)")
                    Text("Zip \(myData.addressZip)")
                    Text("Google Code:  \(myData.fcmToken)")
                    Text("URL \(myData.profileImageUrl)")
                }
                .font(.system(size: 12))
                
                Spacer()
            }
            
            VStack {
                VStack {
                    Button {
                        showProfileImagePicker = true
                    } label: {
                        HStack {
                            ZStack {
                                Circle()
                                    .frame(width: 151, height: 151)
                                    .foregroundColor(.black)
                                    .opacity(0.6)
                                Image("profileImage")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 150, height: 150)
                                
                                KFImage(URL(string: MyData.shared.profileImageUrl))
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 150, height: 150)
                                    .clipShape(Circle())
                                    .onTapGesture {
                                        showProfileImagePicker = true
                                    }
                            }
                        }
                    }
                    Text("Tap to Select")
                        .font(.system(size: 20))
                        .fontWeight(.light)
                        .foregroundColor(.black)
                        .opacity(0.5)
                }
                
                
                
                Button () {
                    
                } label: {
                    HStack {
                        Spacer()
                        Button {
                            if isProfileImageSelected {
                                SaveProfile()
                            } else {
                                ProfileCompletionCurrentPage = 2
                            }
                        } label: {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10)
                                    .frame(width: 75, height: 35)
                                    .foregroundColor(Color(red: 249/255, green: 0/255, blue: 98/255))
                                Text(isProfileImageSelected ? "Finish" : "Skip")
                                    .font(.system(size: 18))
                                    .fontWeight(.regular)
                                    .foregroundColor(.white)
                            }
                        }
                    }
                }
                .padding(.top, 50)
                Spacer()
            }
            .frame(width: UIScreen.main.bounds.width - 100)
            .padding(.top, 120)
        }
        .onReceive(
            NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)
                .merge(
                    with: NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)
                )
        ) { notification in
            guard let userInfo = notification.userInfo else { return }
            
            let endFrame = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue
            
            let duration = (userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue ?? 0.0
            
            withAnimation(.easeInOut(duration: duration)) {
                if notification.name == UIResponder.keyboardWillShowNotification {
                    keyboardHeight = endFrame?.height ?? 0
                } else {
                    keyboardHeight = 0
                }
            }
        }
//        .offset(y: isKeyboardShown ? 0 : keyboardHeight / 2)
        .sheet(isPresented: $showProfileImagePicker, onDismiss: {
            isProfileImageSelected = true
        }, content: {
            PhotoPicker(avatarImage: $avatarImage)
        })
        .ignoresSafeArea()
    }
    
    func SaveProfile() {
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
            "coordinate": MyData.shared.geoPoint,
            "OTPVerified": MyData.shared.OTPVerified
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
                ProfileCompletionCurrentPage = 2
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
}
