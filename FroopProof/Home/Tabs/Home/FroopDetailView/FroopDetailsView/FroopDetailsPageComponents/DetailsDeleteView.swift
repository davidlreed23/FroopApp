//
//  DetailsDeleteView.swift
//  FroopProof
//
//  Created by David Reed on 6/21/23.
//

import SwiftUI

struct DetailsDeleteView: View {
    
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject var appStateManager = AppStateManager.shared
    @ObservedObject var printControl = PrintControl.shared
    @ObservedObject var froopManager = FroopManager.shared
    @ObservedObject var myData = MyData.shared
    
    @Binding var froopAdded: Bool
    
    var body: some View {
        ZStack {
            if (FirebaseServices.shared.uid) == froopManager.selectedFroop.froopHost {
                
                
                Button(action: {
                    self.froopManager.friendDetailOpen = false
                    self.froopManager.froopDetailOpen = false
                    PrintControl.shared.printFroopDetails("current User UID \(FirebaseServices.shared.uid)")
                    PrintControl.shared.printFroopDetails("MyData.shared.froopUserID \(MyData.shared.froopUserID)")
                    PrintControl.shared.printFroopDetails("selectedFroopUUID \(froopManager.selectedFroopUUID)")
                    FroopDataController.shared.deleteFroop(froopId: froopManager.selectedFroopUUID , froopHost: myData.froopUserID) { closeSheet in
                        print("Deleting Froop \(String(describing: froopManager.selectedFroopUUID))")
                        self.froopAdded = true
                    }
                }) {
                    ZStack {
                        Rectangle ()
                            .frame(height: 60)
                            .foregroundColor(colorScheme == .dark ? Color(red: 250/255 , green: 250/255, blue: 255/255) : Color(red: 250/255 , green: 250/255, blue: 255/255))
                        Rectangle ()
                            .frame(width: 250, height: 50)
                            .foregroundColor(colorScheme == .dark ? .clear : .clear)
                            .border(colorScheme == .dark ? .black : .black, width: 0.25)
                       
                        Text("Delete Froop")
                            .foregroundColor(colorScheme == .dark ? .black : .black)
                            .font(.system(size: 18))
                            .fontWeight(.thin)
                    }
                }
            } else {
                Text("")
            }
        }
    }
}
