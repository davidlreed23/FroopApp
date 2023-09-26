//import SwiftUI
//import MapKit
//import Firebase
//import FirebaseFirestore
//
//struct UserForImages: Codable {
//    let uid: String
//    let profileImageUrl: String
//    let friends: [String]
//}
//
//class GetProfilePics: ObservableObject  {
//    @ObservedObject var printControl = PrintControl.shared
//    @ObservedObject var froopDataListener = FroopDataListener.shared
//    var db = FirebaseServices.shared.db
//
//    @Published var profileImages: [String] = []
//
//    // This function retrieves the profile images of a user's friends from the Firestore database
//    func getProfileImages(for friends: [String]) {
//        PrintControl.shared.printImage("-GetProfilePics: Function: getProfileImages firing")
//
//        friends.forEach { friendUID in
//            let friendRef = db.collection("users").document(friendUID)
//
//            friendRef.getDocument { document, error in
//                guard let document = document, document.exists, error == nil else {
//                    PrintControl.shared.printErrorMessages("Error fetching user data: \(error?.localizedDescription ?? "Unknown error")")
//                    return
//                }
//
//                if let data = document.data(), let profileImageUrl = data["profileImageUrl"] as? String {
//                    self.profileImages.append(profileImageUrl)
//                } else {
//                    PrintControl.shared.printErrorMessages("Document data error or profileImageUrl is not a String")
//                }
//            }
//        }
//    }
//
//    // This function retrieves the UIDs of a user's friends from the Firestore database
//    func getUIDs(for user: UserForImages?) {
//        PrintControl.shared.printImage("-GetProfilePics: Function: getUIDs firing")
//
//        guard let uid = user?.uid else {
//            PrintControl.shared.printImage("No UID provided for fetching profile images")
//            return
//        }
//
//        let userRef = db.collection("users").document(uid).collection("friends").document("friendList")
//
//        userRef.getDocument { document, error in
//            guard let document = document, document.exists, error == nil else {
//                PrintControl.shared.printErrorMessages("Error fetching friend list: \(error?.localizedDescription ?? "Unknown error")")
//                return
//            }
//
//            if let data = document.data(), let friends = data["friendList"] as? [String] {
//                self.getProfileImages(for: friends)
//            } else {
//                PrintControl.shared.printErrorMessages("Document data error or friendList is not an array of String")
//            }
//        }
//    }
//}
