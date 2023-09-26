//
//  FroopTypeOrTemplate.swift
//  FroopProof
//
//  Created by David Reed on 6/18/23.
//

import SwiftUI
import iPhoneNumberField
import Firebase
import FirebaseFirestore
import FirebaseFirestoreSwift
import UIKit


struct FroopTypeOrTemplate: View {
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject var appStateManager = AppStateManager.shared
    @ObservedObject var printControl = PrintControl.shared
    @ObservedObject var locationServices = LocationServices.shared
    @ObservedObject var froopDataListener = FroopDataListener.shared
    @State private var mapState = MapViewState.noInput
    @ObservedObject var froopData: FroopData
    var onFroopNamed: (() -> Void)?
    @State private var showAlert = false
    @EnvironmentObject var locationViewModel: LocationSearchViewModel
    @ObservedObject var froopTypeStore = FroopTypeStore()
    @State var searchText: String = ""
    @State var selectedFroopType: FroopType?
    
    // Add a state variable for the selected tab
    @State private var selectedTab = 0

    var body: some View {

        NavigationView {
            ZStack {
                Color.offWhite
                VStack {
                    Text("What kind of Froop do you want to create")
                        .fontWeight(.semibold)
                        .font(.system(size: 26))
                        .multilineTextAlignment(.center)
                        .padding(.top, 25)
                        .foregroundColor(.black)
                        .padding(.vertical, 25)
                        .frame(maxWidth: 400)
                    TextField("Search", text: $searchText)
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                        .padding(10)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        .padding(.vertical, 25)
                        .frame(maxWidth: 400)
                    
                    // Add a Picker for the tabs
                    Picker("", selection: $selectedTab) {
                        Text("Select Type").tag(0)
                        Text("Saved Templates").tag(1)
                    }
                    .foregroundColor(colorScheme == .dark ? .black : .black)
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)
                    
                    // Add a TabView for the content
                    TabView(selection: $selectedTab) {
                        FroopTypeView(froopData: froopData, searchText: $searchText)
                            .tag(0)
                        FroopSavedTemplates(froopData: froopData)
                            .tag(1)
                    }
                }
    
            }
        }
    }
}

