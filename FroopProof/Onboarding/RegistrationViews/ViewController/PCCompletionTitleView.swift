//
//  PCCompletionTitleView.swift
//  FroopProof
//
//  Created by David Reed on 1/19/23.
//

import SwiftUI
import UIKit
import iPhoneNumberField
import Firebase
import FirebaseFirestore
import FirebaseFirestoreSwift

struct ProfileCompletionTitleView: View {
    @ObservedObject var myData = MyData.shared
    let db = Firestore.firestore()
    let uid = Auth.auth().currentUser?.uid ?? ""
    
    var body: some View {
        ZStack(alignment: .top) {
            VStack{
                AdaptiveImage(
                    light:
                        Image("FroopLogo")
                        .resizable()
                    ,
                    dark:
                        Image("FroopLogo")
                        .resizable()
                )
                .onTapGesture {
                    print(myData)
                    print("""
                          MyData:
                          - firstName: \(myData.firstName)
                          - lastName: \(myData.lastName)
                          - phoneNumber: \(myData.phoneNumber)
                          - addressNumber: \(myData.addressNumber)
                          - addressStreet: \(myData.addressStreet)
                          - unitName: \(myData.unitName)
                          - addressCity: \(myData.addressCity)
                          - addressState: \(myData.addressState)
                          - addressZip: \(myData.addressZip)
                          - addressCountry: \(myData.addressCountry)
                          - profileImageUrl: \(myData.profileImageUrl)
                          - coordinate: \(myData.coordinate)
                          - badgeCount: \(myData.badgeCount)
                          - fcmToken: \(myData.fcmToken)
                          - OTPVerified: \(myData.OTPVerified)
                          - froopUserID: \(myData.froopUserID)
                          """)
                }
                .aspectRatio(contentMode: .fit)
                .frame(width: 300, alignment: .center)
                .accessibility(hidden: true)
                .padding(.top, 125)
                .onAppear {
                    createUserAndCollections(uid: Auth.auth().currentUser?.uid ?? "") { err in
                        if let err = err {
                            print("Error creating user and collections: \(err)")
                        } else {
                            print("User and collections successfully created.")
                        }
                    }
                }
                
                Text("Do Anything with Anyone, Anywhere!")
                    .font(.title)
                    .foregroundColor(.black)                    
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 50)
                
                Text("Welcome to our Alpha Launch!")
                    .font(.system(size: 24))
                    .foregroundColor(.black)                    
                    .fontWeight(.light)
                    .multilineTextAlignment(.center)
                    .padding(.leading, 20)
                    .padding(.trailing, 20)
                    .multilineTextAlignment(.leading)
                    .padding(.bottom, 10)
                    .foregroundColor(Color(red: 249/255, green: 0/255, blue: 98/255 ))
                
                Text("You are one of the earliest testers of our new platform, so things may not work perfectly every time.")
                    .font(.system(size: 22))
                    .foregroundColor(.black)                   
                    .fontWeight(.light)
                    .multilineTextAlignment(.center)
                    .padding(.leading, 20)
                    .padding(.trailing, 20)
                    .multilineTextAlignment(.leading)
                    .padding(.bottom, 10)
                    .foregroundColor(.black)
                    .opacity(0.8)
                                
                Text("We want to collect as much feedback from you as we can, so please feel free to reach out to the Froop team and share your experience.  Updates will be coming fast and often, so please remember to check if you have a new version to download.")
                    .font(.system(size: 22))
                    .foregroundColor(.black)
                    .fontWeight(.light)
                    .multilineTextAlignment(.center)
                    .padding(.leading, 20)
                    .padding(.trailing, 20)
                    .multilineTextAlignment(.leading)
                    .padding(.bottom, 10)
                    .foregroundColor(.black)
                    .opacity(0.8)
                
                Text("Thanks Again, - Froop Team!")
                    .font(.system(size: 24))
                    .foregroundColor(.black)
                    .fontWeight(.light)
                    .multilineTextAlignment(.center)
                    .padding(.leading, 20)
                    .padding(.trailing, 20)
                
                Spacer()
            }
        }
    }
    
    
    func createUserAndCollections(uid: String, completion: @escaping (Error?) -> Void) {
        let batch = db.batch()
        
        // Get FCM token
        let fcmToken = getUserFcmToken() ?? ""
        
        // Creating the user document
        let userDocRef = RefPath.userDocRef(uid: Auth.auth().currentUser?.uid ?? "")
        
        // Check if the document already exists
        userDocRef.getDocument { (documentSnapshot, error) in
            if let error = error {
                completion(error)
                return
            }
            
            if let documentSnapshot = documentSnapshot, documentSnapshot.exists {
                // If the document exists, update it
                let data = ["froopUserID": Auth.auth().currentUser?.uid ?? "", "fcmToken": fcmToken]
                batch.updateData(data, forDocument: userDocRef)
            } else {
                // If the document does not exist, set it
                var data = MyData.shared.dictionary
                data["froopUserID"] = Auth.auth().currentUser?.uid ?? ""
                data["fcmToken"] = fcmToken
                batch.setData(data, forDocument: userDocRef)
            }
            
            // Creating collections inside the user document
            let collectionsInsideUser = ["myFroops", "froopDecisions", "friends"]
            for collection in collectionsInsideUser {
                let newDocRef = userDocRef.collection(collection).document("placeholder")
                batch.setData(["placeholder": "placeholder"], forDocument: newDocRef)
            }
            
            // Creating collections inside the froopDecisions document
            let froopDecisionsDocRef = RefPath.froopDecisionsColRef(uid: uid).document("froopLists")
            batch.setData(["placeholder": "placeholder"], forDocument: froopDecisionsDocRef)
            
            let collectionsInsideFroopLists = ["myArchivedList", "myConfirmedList", "myDeclinedList", "myInvitesList"]
            for collection in collectionsInsideFroopLists {
                let newCollectionRef = froopDecisionsDocRef.collection(collection).document("placeholder")
                batch.setData(["placeholder": "placeholder"], forDocument: newCollectionRef)
            }
            
            // Committing the batch
            batch.commit() { err in
                completion(err)
            }
        }
    }
    
    
    
    func getUserFcmToken() -> String? {
        // Check if the user is authenticated
        guard let uid = Auth.auth().currentUser?.uid, !uid.isEmpty else {
            PrintControl.shared.printErrorMessages("User is not authenticated. Unable to retrieve fcmToken.")
            let error = NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "User is not authenticated. Unable to retrieve fcmToken."])
            Crashlytics.crashlytics().record(error: error) // Log error to Crashlytics
            return nil
        }
        
        // Get the FCM token from user defaults
        let fcmToken = UserDefaults.standard.value(forKey: "FCMTokenNotification") as? String
        return fcmToken
    }
}
