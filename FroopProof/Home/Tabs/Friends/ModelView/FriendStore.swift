//
//  FriendStore.swift
//  FroopProof
//
//  Created by David Reed on 2/12/23.
//

import Foundation
import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore
import FirebaseFirestoreSwift
import UIKit

class FriendStore: ObservableObject {
    
    @ObservedObject var appStateManager = AppStateManager.shared
    @ObservedObject var printControl = PrintControl.shared
    @ObservedObject var locationServices = LocationServices.shared
    @ObservedObject var froopDataListener = FroopDataListener.shared
    
    var db = FirebaseServices.shared.db
    @Published var friends: [UserData] = []
    
    init() {
        let friendListRef = db.collection("users").document(FirebaseServices.shared.uid).collection("friends").document("friendList")
        
        friendListRef.addSnapshotListener { querySnapshot, error in
            guard let snapshot = querySnapshot else {
                print("Error fetching friends: \(error?.localizedDescription ?? "unknown error")")
                return
            }
            
            let friends = snapshot.data()?["friendUIDs"] as? [String] ?? []
            
            self.friends.removeAll()
            
            for friendUID in friends {
                let friendRef = self.db.collection("users").document(friendUID)
                
                friendRef.getDocument { document, error in
                    if let document = document, document.exists {
                        if let data = document.data(),
                           let friendData = UserData(dictionary: data) {
                            // A UserData instance was successfully initialized from the Firestore document data.
                            self.friends.append(friendData)
                        } else {
                            // A UserData instance could not be initialized from the Firestore document data.
                            print("Unable to initialize UserData from Firestore document data")
                        }
                    } else if let error = error {
                        print("Error fetching friend: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
}
        
        
