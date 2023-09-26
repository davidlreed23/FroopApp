//
//  FroopHistoryView.swift
//  FroopProof
//
//  Created by David Reed on 6/19/23.
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import Firebase

struct FroopHistoryView: View {
    @ObservedObject var froopManager = FroopManager.shared
    private var froop: Froop
    private var host: UserData
    
    init(froop: Froop, host: UserData) {
        self.froop = froop
        self.host = host
    }
    
    
    var body: some View {
        Text("Froop Name: \(froop.froopName)")
        Text("Host Name: \(host.firstName)")
    }
}



