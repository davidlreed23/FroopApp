//
//  FroopChainView.swift
//  FroopProof
//
//  Created by David Reed on 2/10/23.
//

import SwiftUI
import Photos
import FirebaseStorage
import Firebase
import FirebaseAuth
import FirebaseFirestore
import Kingfisher



struct FroopChainView: View {
    
    @State private var searchText = ""
    @State private var isMine = false
    @State private var froopHistoryOpen = false
    @State private var addFraction = 0.3
    @State private var acceptFraction = 0.75
    
    @ObservedObject var froopManager = FroopManager.shared
    
    var body: some View {
        
        ZStack {
            VStack{
                ZStack {
                    Rectangle()
                        .ignoresSafeArea()
                        .frame(height: 125)
                        .background(.ultraThinMaterial)
                        .foregroundColor(.black)
                        .opacity(0.8)
                    VStack {
                        TextField("Search...", text: $searchText)
                            .padding(7)
                            .background(Color(.white))
                            .cornerRadius(8)
                            .padding(.horizontal, 50)
                            .offset(y: -20)
                        HStack {
                            Toggle(isOn: $isMine) {
                                Text(isMine ? "My Froops" : "All")
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.leading)
                            }
                            .toggleStyle(CustomToggleStyle())
                            .padding(.trailing, 25)
                            
                        }
                    }
                }
                
                List {
                    ForEach(froopManager.groupFroopHistoriesByMonth(), id: \.id) { month in
                        Section(header: Text(month.name)
                            .font(.system(size: 20))
                            .fontWeight(.thin)
                            .foregroundColor(.black)
                                
                        ) {
                            ForEach(month.froopHistories.filter { !isMine || $0.froop.froopHost == Auth.auth().currentUser?.uid }, id: \.id) { froopHistory in
                                FroopHistoryCardView(froopHistory: froopHistory, froopHistoryOpen: $froopHistoryOpen)
                                    .onAppear {
                                        print("running....")
                                    }
                            }
                        }
                    }
                }
                .listStyle(PlainListStyle())
            }
            
            .blurredSheet(.init(.ultraThinMaterial), show: $froopHistoryOpen) {
            } content: {
                ZStack {
                    Rectangle()
                        .foregroundColor(.white)
                        .opacity(0.01)
                        .onTapGesture {
                            self.froopHistoryOpen = false
                            print("CLEAR TAP MainFriendView 1")
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .ignoresSafeArea()
                    VStack {
                        Text("tap to close")
                            .font(.system(size: 18))
                            .fontWeight(.light)
                            .foregroundColor(.white)
                            .padding(.top, 25)
                        Image(systemName: "chevron.down")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                        Spacer()
                    }
                    .frame(alignment: .center)
                    
                    
                    VStack {
                        Spacer()
                        FroopHistoryView(froop: FroopManager.shared.froopHistoryFroop, host: FroopManager.shared.froopHistoryHost)
                        
                        
                    }
                    .frame(height: acceptFraction * UIScreen.main.bounds.height)
                }
                .presentationDetents([.large])
            }
        }
    }
}
