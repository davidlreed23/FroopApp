//
//  CFSBackGroundComponent.swift
//  FroopProof
//
//  Created by David Reed on 5/16/23.
//

import SwiftUI
import UIKit

struct CFSBackGroundComponent: View {
    @ObservedObject var froopData: FroopData
    
    var body: some View {
        ZStack (alignment: .top){
            
//            Image(backgroundImage())
//                .resizable()
//                .aspectRatio(contentMode: .fill)
//                .frame(maxWidth: UIScreen.main.bounds.width)
//                .scaleEffect(x: 1, y: -1)
//                .offset(y: 785)
//                .ignoresSafeArea(.all, edges: .bottom)
            
            Image(backgroundImage())
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(maxWidth: UIScreen.main.bounds.width)
                .ignoresSafeArea()
                .padding(.top, -67)
            
            Rectangle()
                .ignoresSafeArea()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .foregroundColor(.black)
                .opacity(0.25)
            
            VStack{
                
            }
            .toolbar{
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    
                }
            }
        }
    }
    
    func backgroundImage() -> String {
        let froopType = froopData.froopType
        switch froopType {
        case 1: return "Bar"
        case 2: return "BirthDay"
        case 3: return "DinnerParty"
        case 4: return "Golf1"
        case 5: return "Camping"
        case 6: return "F_bkg1"
        case 7: return "WinterSport"
        case 8: return "BeachDay"
        case 9: return "Bar2"
        case 10: return "Bar"
        case 11: return "DinnerParty"
        case 12: return "Concert"
        case 13: return "Karaoke"
        case 14: return "MovieNight"
        case 15: return "BurningMan"
        case 16: return "BurningMan"
        case 17: return "BoolParty2"
        case 18: return "Concert"
        case 19: return "Concert"
        case 20: return "BeachDay"
        case 21: return "PoolParty1"
        case 22: return "PoolParty2"
        case 23: return "DinnerParty"
        case 24: return "MovieNight"
        case 25: return "Karaoke"
        case 26: return "Concert"
        case 27: return "Background_Froop"
        default: return "DefaultImage" // Default image if froopType doesn't match any case
        }
    }
}



