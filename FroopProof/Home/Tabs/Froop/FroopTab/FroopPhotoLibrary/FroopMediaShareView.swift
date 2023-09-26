

//
//  FroopMediaShare.swift
//  FroopProof
//
//  Created by David Reed on 7/10/23.
//

import SwiftUI

struct FroopMediaShareView: View {
    @Environment(\.colorScheme) var colorScheme
    @State private var selectedTab = 0
    @Binding var uploadedImages: [ImageItem]
    
    var body: some View {
        ZStack {
           
            ZStack {
                Rectangle()
                    .foregroundColor(.white)
                    .opacity(0.5)
                    .ignoresSafeArea()
                    .background(.ultraThinMaterial)
                
                VStack {
                    Text(selectedTab == 0 ? "Everyone's Shared Photos" : "Upload Images from your Library")
                        .foregroundColor(colorScheme == .dark ? .black : .black)
                        .fontWeight(.semibold)
                        .font(.system(size: 22))
                        .multilineTextAlignment(.center)
                        .padding(.top, 25)
                        .padding(.bottom, 10)
                    Picker("", selection: $selectedTab) {
                        Text("All Froop Images").tag(0)
                        Text("Your Photo Library").tag(1)
                    }
                    .foregroundColor(colorScheme == .dark ? .black : .black)
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)
                    Spacer()
                }
            }
            ZStack {
                VStack {
                    Rectangle()
                        .foregroundColor(.clear)
                        .frame(height: 125)
                    TabView(selection: $selectedTab) {
                        FroopMediaFeedView()
                            .tag(0)
                        PhotoLibraryView(viewModel: ImageGridViewModel(), uploadedImages: $uploadedImages)
                            .tag(1)
                    }
                }
            }
        }
    }
}
