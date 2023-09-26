//
//  UpdateVersionView.swift
//  FroopProof
//
//  Created by David Reed on 8/7/23.
//

import SwiftUI
import FirebaseFirestore

struct UpdateVersionView: View {
    var body: some View {
        ZStack {
            ZStack {
                Image("upgradeImage")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
                
            }
            
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.black)
                    .opacity(0.95)
                    .shadow(color: Color.black.opacity(0.2), radius: 7, x: 7, y: 7)
                    .shadow(color: Color.black.opacity(0.2), radius: 7, x: -4, y: -4)
                    .ignoresSafeArea()
                    
                    
                
                VStack {
                    Text("Froop Needs to Update")
                        .font(.system(size: 28))
                        .foregroundColor(.white)
                        .fontWeight(.semibold)
                        .padding(.top, 20)
                    
                    Text("You are currently running an expired version.")
                        .font(.system(size: 18))
                        .foregroundColor(.white)
                        .fontWeight(.light)
                        .padding(.top, 5)
                    Text("Please update the app in TestFlight.")
                        .font(.system(size: 18))
                        .foregroundColor(.white)
                        .fontWeight(.light)
                        .padding(.top, 2)
                    Spacer()
                    
                    HStack {
                        Spacer()
                        Button {
                            let url = URL(string: "https://testflight.apple.com/join/ex7x1Z8o")!
                            UIApplication.shared.open(url)
                        } label: {
                            Text("Open TestFlight")
                                .font(.system(size: 16))
                                .fontWeight(.regular)
                                .foregroundColor(Color(red: 249/255, green: 0/255, blue: 98/255))
                        }
                    }
                    .padding(.leading, 25)
                    .padding(.trailing, 25)
                    .padding(.bottom, 20)
                }
            }
            .frame(minWidth: 300, maxWidth: 400, minHeight: 250, maxHeight: 250)
            .padding(.leading, 20)
            .padding(.trailing, 20)
        }
    }
}

