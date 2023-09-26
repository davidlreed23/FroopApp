//
//  InviteExternalFriendsView.swift
//  FroopProof
//
//  Created by David Reed on 3/8/23.
//

import SwiftUI
import UIKit
import Kingfisher
import Firebase
import FirebaseAuth
import FirebaseFirestore
import iPhoneNumberField
import Combine

struct InviteExternalFriendsView: View {
    
    
    
    @ObservedObject var appStateManager = AppStateManager.shared
    @ObservedObject var printControl = PrintControl.shared
    @ObservedObject var locationServices = LocationServices.shared
    @ObservedObject var froopDataListener = FroopDataListener.shared
   
 

    var db = FirebaseServices.shared.db
    @State private var phoneNumber: String = ""
    @State private var isFocused = false
    @State private var revealed = false
    @State var callFunc = false
    var timestamp: Date
    
    enum FocusField: Hashable {
        case field
        case nofield
    }
    
    @FocusState private var focusedField: FocusField?
    
    var body: some View {
        
        ZStack (alignment: .top) {
    
            VStack(alignment: .center)  {
                
                iPhoneNumberField("Enter phone number", text: $phoneNumber)
                    .flagHidden(true)
                    .flagSelectable(true)
                    .font(UIFont(size: 42, weight: .thin))
                    .maximumDigits(11)
                    .foregroundColor(Color.black)
                    .accentColor(Color(red: 249/255, green: 0/255, blue: 98/255 ))
                    .frame(width: 280, height: 50)
                    .focused($focusedField, equals: .field)
                    .onAppear {focusedField = .field}
                    .multilineTextAlignment(.center)
                    .padding(.top, 400)
                
                
                Button(action: {
                    self.sendTextInvite()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            revealed = true
                        }
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        self.callFunc = true
                    }
                }) {
                    Text("Send SMS Invitation")
                        .font(.headline)
                        .foregroundColor(.black)
                        .font(.system(size: 24))
                        .fontWeight(.medium)
                        .padding()
                        .cornerRadius(5)
                        .shadow(radius: 5)
                        .border(.gray, width: 0.25)
                        .padding(.top, 10)
                }
            }
            .onTapGesture {
                isFocused = false
            }
        }
        
    }
    
    func sendTextInvite() {
     
       // let usersRef = db.collection("users")
       // let formattedPhoneNumber = phoneNumber.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        print("Not")
        
    }
}
