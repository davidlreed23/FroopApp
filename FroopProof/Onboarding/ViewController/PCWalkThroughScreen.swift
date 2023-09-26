//
//  PCWalkThroughScreen.swift
//  FroopProof
//
//  Created by David Reed on 1/19/23.
//

import SwiftUI
import iPhoneNumberField
import Firebase
import FirebaseFirestore
import FirebaseFirestoreSwift
import MapKit

struct PCWalkthroughScreen: View{
    @AppStorage("ProfileCompletionCurrentPage") var ProfileCompletionCurrentPage = 1
    @ObservedObject var printControl = PrintControl.shared
    @ObservedObject var froopDataListener = FroopDataListener.shared

    var body: some View{
        // For Slide Animation...
        
        ZStack{
             //Changing Between Views....
            
            if ProfileCompletionCurrentPage == 1{
                OnboardingView(ProfileCompletionCurrentPage: $ProfileCompletionCurrentPage)
                    .transition(.scale)
            }
            if ProfileCompletionCurrentPage == 2{

                HomeView1(userData: UserData(), photoData: PhotoData())
                    .transition(.scale)
            }
        }
    }
}
