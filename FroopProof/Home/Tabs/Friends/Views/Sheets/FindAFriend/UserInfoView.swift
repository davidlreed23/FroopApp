//
//  UserInfoView.swift
//  FroopProof
//
//  Created by David Reed on 2/23/23.
//

import SwiftUI
import iPhoneNumberField

struct UserInfoView: View {
    
    @ObservedObject var appStateManager = AppStateManager.shared
    @ObservedObject var printControl = PrintControl.shared
    @ObservedObject var locationServices = LocationServices.shared
    @ObservedObject var froopDataListener = FroopDataListener.shared
 
    
    @ObservedObject var myData = MyData.shared
    var body: some View {
        VStack {
            Text("Name: \(MyData.shared.firstName) \(MyData.shared.lastName)")
                .foregroundColor(.black)
            iPhoneNumberField("Phone Number:", text: $myData.phoneNumber)
            Text("toUserInfo: \(MyData.shared.froopUserID)")
            
        }
    }
}
