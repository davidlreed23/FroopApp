//
//  StatusBarItem.swift
//  FroopProof
//
//  Created by David Reed on 4/1/23.
//

import SwiftUI

struct StatusBarItem: View {
    @ObservedObject var appStateManager = AppStateManager.shared
    @ObservedObject var printControl = PrintControl.shared
    @ObservedObject var locationServices = LocationServices.shared
    @ObservedObject var froopDataListener = FroopDataListener.shared
    var title: String
    var count: Int
    var color: Color
    var action: () -> Void

    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 20))
                .fontWeight(.light)
                .foregroundColor(.black)
                .opacity(0.7)

            Text("\(count)")
                .font(.system(size: 20))
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
        .onTapGesture(perform: action)
        .padding(.horizontal, 20)
    }
}


