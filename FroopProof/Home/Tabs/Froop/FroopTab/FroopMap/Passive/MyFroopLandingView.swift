//
//  MyFroopLandingView.swift
//  FroopProof
//
//  Created by David Reed on 8/9/23.
//

import SwiftUI

struct MyFroopLandingView: View {
    @ObservedObject var dataController = DataController.shared
    @ObservedObject var froopManager = FroopManager.shared
    var size: CGSize
    var safeArea: EdgeInsets
    @State var friendsView: Bool = false
    //    @State private var offsetY: CGFloat = 0
    
    
    
    var body: some View {
        ZStack {
            Color.white
            ScrollViewReader { scrollProxy in
                ZStack {
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 5) {
                            MyProfileHeaderView(size: size, safeArea: safeArea)
                                .zIndex(1000)
                                .ignoresSafeArea()
                            MyFroopsView()
                                .transition(.opacity)
                        }
                        .id("SCROLLVIEW")
                        .background {
                            ScrollDetector { offset in
                                dataController.offsetY = -offset
                            } onDraggingEnd: { offset, velocity in
                                /// Resetting to Intial State, if not Completely Scrolled
                                let headerHeight = (size.height * 0.3) + safeArea.top
                                let minimumHeaderHeight = (size.height * 0.3) + safeArea.top
                                
                                let targetEnd = offset + (velocity * 45)
                                if targetEnd < (headerHeight - minimumHeaderHeight) && targetEnd > 0 {
                                    withAnimation(.interactiveSpring(response: 0.55, dampingFraction: 0.65, blendDuration: 0.65)) {
                                        scrollProxy.scrollTo("SCROLLVIEW", anchor: .top)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}




