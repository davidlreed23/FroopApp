//
//  PlaceHolderFindFriendCard.swift
//  FroopProof
//
//  Created by David Reed on 4/5/23.
//

//
//  textFriendOutsideFroop.swift
//  FroopProof
//
//  Created by David Reed on 3/12/23.
//

import SwiftUI
import UIKit
import Kingfisher
import MessageUI

struct PlaceHolderFindFriendCard: View {
    
    @ObservedObject var appStateManager = AppStateManager.shared
    @ObservedObject var printControl = PrintControl.shared
    @ObservedObject var locationServices = LocationServices.shared
    @ObservedObject var froopDataListener = FroopDataListener.shared
 
    
    var body: some View {
        ZStack (alignment: .top){
            RoundedRectangle(cornerRadius: 10)
                .frame(height: 280)
                .foregroundColor(.white)
                .padding(.leading, 10)
                .padding(.trailing, 10)
            Image(systemName: "person.crop.circle.fill")
                .font(.system(size: 80))
                .frame(width: 150, height: 150)
                .padding(.leading, 10)
                .foregroundColor(.black)
                .opacity(0.6)
            VStack (alignment: .leading) {
            }
            .padding(.leading, 30)
        }
        Spacer()
    }
}

