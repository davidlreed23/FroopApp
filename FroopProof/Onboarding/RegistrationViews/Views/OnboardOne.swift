//
//  ProfileCompletionView1.swift
//  FroopProof
//
//  Created by David Reed on 1/19/23.
//

import SwiftUI

struct OnboardOne: View {
    @ObservedObject var myData = MyData.shared
    @ObservedObject var printControl = PrintControl.shared
    @ObservedObject var froopDataListener = FroopDataListener.shared
    @Binding var selectedTab: OnboardingTab
    
    @AppStorage("ProfileCompletionCurrentPage") var ProfileCompletionCurrentPage = 1
    
    var body: some View {
        ZStack {
            VStack {
                ProfileCompletionTitleView()
                Spacer()
            }
            .padding(.horizontal)
            
        }
        .ignoresSafeArea(.keyboard)
        
    }
}


