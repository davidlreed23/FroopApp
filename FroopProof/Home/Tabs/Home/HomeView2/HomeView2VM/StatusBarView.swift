//
//  StatusBarView.swift
//  FroopProof
//
//  Created by David Reed on 4/1/23.
//

import SwiftUI

struct StatusBarView: View {
    @ObservedObject var appStateManager = AppStateManager.shared
    @ObservedObject var printControl = PrintControl.shared
    @ObservedObject var locationServices = LocationServices.shared
    @ObservedObject var froopDataListener = FroopDataListener.shared
    
    @ObservedObject var viewModel: HomeView2ViewModel
    var myInvitesListCount: Int
    var myConfirmedListCount: Int
    var myDeclinedListCount: Int

    var body: some View {
        HStack(alignment: .top) {
            StatusBarItem(
                title: "Invites",
                count: myInvitesListCount,
                color: Color(red: 249/255, green: 0/255, blue: 98/255),
                action: { viewModel.froopListStatus = .invites }
            )

            Divider()

            StatusBarItem(
                title: "I'm Going",
                count: myConfirmedListCount,
                color: .blue,
                action: { viewModel.froopListStatus = .confirmed }
            )

            Divider()

            StatusBarItem(
                title: "Declined",
                count: myDeclinedListCount,
                color: .gray,
                action: { viewModel.froopListStatus = .declined }
            )
        }
        .frame(height: 25)
        .padding()
    }
}
