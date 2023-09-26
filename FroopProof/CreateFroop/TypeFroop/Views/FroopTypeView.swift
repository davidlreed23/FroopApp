//
//  FroopTypeView.swift
//  FroopProof
//
//  Created by David Reed on 1/19/23.
//

import SwiftUI
import iPhoneNumberField
import Firebase
import FirebaseFirestore
import FirebaseFirestoreSwift
import Foundation
import UIKit


struct FroopTypeView: View {
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject var appStateManager = AppStateManager.shared
    @ObservedObject var printControl = PrintControl.shared
    @ObservedObject var locationServices = LocationServices.shared
    @ObservedObject var froopDataListener = FroopDataListener.shared
    @State private var mapState = MapViewState.noInput
    @ObservedObject var changeView = ChangeView.shared
    @ObservedObject var froopData: FroopData
    var onFroopNamed: (() -> Void)?
    @State private var showAlert = false
    @EnvironmentObject var locationViewModel: LocationSearchViewModel
    @ObservedObject var froopTypeStore = FroopTypeStore()
    @Binding var searchText: String
    @State var selectedFroopType: FroopType?
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.offWhite
                VStack {
                   
                    ScrollView (showsIndicators: false) {
                        VStack(spacing: 10) {
                            ForEach(froopTypeStore.froopTypes.filter { froopType in
                                searchText.isEmpty ? true : froopType.name.localizedCaseInsensitiveContains(searchText)
                            }.chunked(into: 3), id: \.self[0].id) { froopTypeGroup in
                                HStack(spacing: 10) {
                                    ForEach(froopTypeGroup, id: \.id) { froopType in
                                        VStack {
                                            Image(systemName: froopType.imageName)
                                                .resizable()
                                                .aspectRatio(contentMode: .fit)
                                                .frame(maxWidth: 100, maxHeight: 100)
                                                .foregroundColor(.black)
                                                .padding(.all, 20)
                                            Text(froopType.name)
                                                .font(.system(size: 12))
                                                .fontWeight(.medium)
                                                .foregroundColor(.black)
                                                .padding(5)
                                                .multilineTextAlignment(.center)
                                        }
                                        .frame(width: 120, height: 120)
                                        .background(Color.white)
                                        .cornerRadius(10)
                                        // remove this line to get rid of the border
                                        // .border(Color.gray, width: 1)
                                        .background(RoundedRectangle(cornerRadius: 10)
                                            .fill(Color.offWhite))
                                        .shadow(color: Color.black.opacity(0.2), radius: 7, x: 7, y: 7)
                                        .shadow(color: Color.white.opacity(0.7), radius: 7, x: -4, y: -4)
                                        .ignoresSafeArea()
                                        .onTapGesture {
                                            withAnimation(.spring()) {
                                                mapState = .searchingForLocation
                                            }
                                            froopData.froopType = froopType.id
                                            if appStateManager.froopIsEditing {
                                                changeView.pageNumber = 5
                                            } else {
                                                changeView.pageNumber += 1
                                                print(changeView.pageNumber)
                                            }
                                            
                                        }
                                    }
                                }
                            }
                            .onReceive(LocationManager.shared.$userLocation) { location in
                                if let location = location {
                                    locationViewModel.userLocation = location.coordinate
                                    PrintControl.shared.printLocationServices("updating userLocation FIVE")
                                }
                            }
                        }
                        .padding()
                    }
                    .padding(.leading, 15)
                    .padding(.trailing, 15)
                }
            }
            .ignoresSafeArea()
        }
    }
}

