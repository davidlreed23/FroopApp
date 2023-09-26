//
//  DetailsHeaderView.swift
//  Design_Layouts
//
//  Created by David Reed on 6/20/23.
//

import SwiftUI
import SwiftUIBlurView
import Kingfisher
import Firebase
import FirebaseAuth
import FirebaseFirestore
import Foundation
import MapKit
import EventKit
import FirebaseCrashlytics

struct DetailsHeaderView: View {
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject var appStateManager = AppStateManager.shared
    @ObservedObject var printControl = PrintControl.shared
    @ObservedObject var froopManager = FroopManager.shared

    var body: some View {
        ZStack {
            Rectangle()
                .frame(height: 200)
                .foregroundColor(colorScheme == .dark ? .black : .black)
                .opacity(colorScheme == .dark ? 0.8 : 0.8)
            
            HStack {
                ZStack {
                    Circle()
                        .frame(width: 75)
                        .foregroundColor(colorScheme == .dark ? .white : .white)
                    KFImage(URL(string: froopManager.selectedFroop.froopHostPic))
                        .placeholder {
                            ProgressView()
                        }
                        .resizable()
                        .scaledToFill()
                        .frame(width: 75, height: 75, alignment: .center)
                        .clipShape(Circle())
                    
                }
                VStack (alignment: .leading){
                    Text(froopManager.selectedFroop.froopName)
                        .foregroundColor(colorScheme == .dark ? .white: .white)
                        .font(.system(size: 24))
                    Text("Host: \(froopManager.selectedHost.firstName) \(froopManager.selectedHost.lastName)")
                        .foregroundColor(colorScheme == .dark ? .white: .white)
                        .font(.system(size: 14))
                        .offset(y: 5)
                }
                .padding(.leading, 15)
                Spacer()
            }
            .padding(.top, 95)
            .padding(.trailing, 25)
            .padding(.leading, 25)
        }
    }
}


