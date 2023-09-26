//
//  ProfileHeaderView.swift
//  FroopProof
//
//  Created by David Reed on 8/9/23.
//

import SwiftUI
import Kingfisher
import UIKit
import Combine

struct ProfileHeaderView: View {
    @ObservedObject var dataController = DataController.shared
    @Binding var offsetY: CGFloat
    @Binding var selectedFriend: UserData
    @Binding var profileView: Bool
    var size: CGSize
    var safeArea: EdgeInsets
    @State private var selectedTab = 0

    
    private var headerHeight: CGFloat {
        (size.height * 0.5) + safeArea.top
    }
    
    private var headerWidth: CGFloat {
        (size.width * 0.5)
    }
    
    private var minimumHeaderHeight: CGFloat {
        100 + safeArea.top
    }
    
    private var minimumHeaderWidth: CGFloat {
        0
    }
    
    private var progress: CGFloat {
        max(min(-offsetY / (headerHeight - minimumHeaderHeight), 1), 0)
    }
    
    var body: some View {
        GeometryReader { _ in
            ZStack {
                ZStack (alignment: .top) {
                    Rectangle()
                        .fill(Color(.white).gradient)
                    
                    Rectangle()
                        .fill(Color(.black).gradient)
                        .frame(height: 250 * (1 - progress))
                }
        
                VStack(alignment: .center) {
                    HStack {
                        Spacer()
                        ProfileImage(progress: progress, headerHeight: headerHeight, selectedFriend: $selectedFriend)
                        Spacer()
                    }
                    .padding(.top, 85)
                    .offset(y: 35)
                    HStack {
                        Spacer()
                        Text("\(selectedFriend.firstName) \(selectedFriend.lastName)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.black)
                            .opacity(0.8)
                            .frame(alignment: .leading)
                            .moveText(progress, headerHeight, minimumHeaderHeight, headerWidth, minimumHeaderWidth)
                        Spacer()
                    }
                    .offset(y: 35)

                    HStack (spacing: 45) {
                        Spacer()
                        Image(systemName: "phone.fill")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                            .opacity(0.8)
                          
                        Image(systemName: "text.bubble.fill")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.pink)
                            .opacity(0.8)
                           
                        Image(systemName: "message.fill")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                            .opacity(0.8)
                        Spacer()
                    }
                    .offset(y: 25)
                    .frame(height: 50 - (1 * progress))
                    .moveSymbols(progress, headerHeight, minimumHeaderHeight, headerWidth, minimumHeaderWidth)
                    
                    HStack {
                        Spacer()
                        Text("Your Description of what you want to say goes here.  You can put anything that fits in three lines.").italic()
                            .font(.system(size: 16))
                            .foregroundColor(.black)
                            .opacity(0.6)
                            .lineLimit(3)
                            .fontWeight(.light)
                            .italic()
                            .frame(height: 75 - (1 * progress), alignment: .center)
                            .ignoresSafeArea()
                        Spacer()
                    }
                    .offset(y: 10)
                    .padding(.leading, 25)
                    .padding(.trailing, 25)
                    .opacity(1.0 * (1 - progress))

                    Spacer()
            
                    Picker("", selection: $selectedTab) {
                        Text("Froops").tag(0)
                        Text("Friends").tag(1)
                    }
                    .foregroundColor(.black)
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.leading, 25 + (75 * progress))
                    .padding(.trailing, 25 + (75 * progress))
                    .frame(height: 50)
                    .onChange(of: selectedTab) { newValue in
                        dataController.allSelected = 0
                        profileView = (newValue == 0) // profileView is true when Froops is selected, false otherwise
                    }
                    .moveMenu(progress, headerHeight, minimumHeaderHeight, headerWidth, minimumHeaderWidth)
                  
                    
                }
                
                .padding(.top, safeArea.top)
                .padding(.bottom, 15)
            }
            .frame(height: (headerHeight + offsetY) < minimumHeaderHeight ? minimumHeaderHeight : (headerHeight + offsetY), alignment: .bottom)
            .offset(y: -offsetY)
        }
        .frame(height: headerHeight)
    }
}

struct ProfileImage: View {
    
    var progress: CGFloat
    var headerHeight: CGFloat
    @Binding var selectedFriend: UserData
    
    var body: some View {
        GeometryReader {
            let rect = $0.frame(in: .global)
            let halfScaledHeight = (rect.height * 1) * 0.15
            let halfScaledWidth = (rect.width * 0.4) * 0.5
            let midY = rect.midY - rect.height / 2
            let midX = rect.midX - rect.width / 2
            let bottomPadding: CGFloat = 0
            let leadingPadding: CGFloat = 0
            let minimumHeaderHeight = 50
            let minimumHeaderWidth = 50
            let resizedOffsetY = (midY - (CGFloat(minimumHeaderHeight) - halfScaledHeight - bottomPadding))
            let resizedOffsetX = (midX - (CGFloat(minimumHeaderWidth) - halfScaledWidth - leadingPadding))
            
            KFImage(URL(string: selectedFriend.profileImageUrl))
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: rect.width * 1, height: rect.height * 1)
                .clipShape(Circle())
                .scaleEffect(1 - (progress * 0.6), anchor: .leading)
                .offset(x: -resizedOffsetX * progress, y: -resizedOffsetY * progress)
        }
        .frame(width: headerHeight * 0.35, height: headerHeight * 0.35)
    }
}

