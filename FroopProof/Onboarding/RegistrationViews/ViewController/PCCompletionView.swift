//
//  PCCompletionView.swift
//  FroopProof
//
//  Created by David Reed on 1/19/23.
//

import SwiftUI
import iPhoneNumberField
import Firebase
import FirebaseFirestore
import FirebaseFirestoreSwift

struct ProfileCompletionView: View {
    
    @ObservedObject var printControl = PrintControl.shared
    @ObservedObject var froopDataListener = FroopDataListener.shared
    @ObservedObject var photoData: PhotoData
    @ObservedObject var appDelegate: AppDelegate
    @ObservedObject var friendData: UserData

    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject var timeZoneManager = TimeZoneManager()
    var PCtotalPages = 6
    
    @StateObject var mediaManager = MediaManager()
    @AppStorage("ProfileCompletionCurrentPage_\(FirebaseServices.shared.uid)") var ProfileCompletionCurrentPage = 1
    @ObservedObject var myData = MyData.shared
    @State var showEditView: Bool = false
    @State var showAlert: Bool = false
    @State var alertMessage: String = ""
    @State var hasFroops: Bool = false
    @Binding var confFroops: [Froop]
 
    var db = FirebaseServices.shared.db
    
    func checkFroops() {
        PrintControl.shared.printProfile("-ProfileCompletionView: Function: checkFroops firing")
        let uid = FirebaseServices.shared.uid
        db.collection("photos").document("profiles").collection("profilePhotos").whereField("uid", isEqualTo: uid).getDocuments { (snapshot, error) in
            if let error = error {
                // Log error and show an appropriate error message to the user
                PrintControl.shared.printProfile(error.localizedDescription)
                self.alertMessage = "Failed to check Froops. Please try again."
                self.showAlert = true
            } else if snapshot!.documents.count > 0 {
                self.hasFroops = true
            }
        }
    }

    var body: some View {
        VStack {
            if hasFroops {
                RootView(friendData: UserData(), photoData: PhotoData(), appDelegate: AppDelegate(), confirmedFroopsList: ConfirmedFroopsList())
            } else if ProfileCompletionCurrentPage == PCtotalPages {
                ActiveOrPassiveView(friendData: friendData)
            } else {
                PCWalkthroughScreen()
            }
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Error"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
        .onAppear(perform: checkFroops)
    }

}
