//
//  LogStatus.swift
//  FroopProof
//
//  Created by David Reed on 1/18/23.
//

import SwiftUI
import Firebase
import FirebaseFirestore
import GoogleSignIn


struct LogStatus: View {
    @AppStorage("log_status") var logStatus: Bool = false
    @ObservedObject var myData = MyData.shared
    @EnvironmentObject var mapUpdateState: MapUpdateState
    @EnvironmentObject var appDelegate: AppDelegate
    
    var body: some View {
        if Auth.auth().currentUser != nil && logStatus {
            RootView(friendData: UserData(), photoData: PhotoData(), appDelegate: AppDelegate(), confirmedFroopsList: ConfirmedFroopsList())
        } else {
            Login()
                .onAppear {
                                   if Auth.auth().currentUser == nil {
                                       let error = NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "User is not authenticated."])
                                       Crashlytics.crashlytics().record(error: error) // Log error to Crashlytics
                                   }
                                   logStatus = false // reset logStatus every time this view appears
                                   try? Auth.auth().signOut() // sign the user out from Firebase Auth
                               }
//                .onAppear {
//                    if Auth.auth().currentUser == nil {
//                        let error = NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "User is not authenticated."])
//                        Crashlytics.crashlytics().record(error: error) // Log error to Crashlytics
//                    }
//                }
        }
    }
}
