//
//  NFWalkthroughScreen.swift
//  FroopProof
//
//  Created by David Reed on 1/19/23.
//

import SwiftUI
import iPhoneNumberField
import Firebase
import FirebaseFirestore
import FirebaseFirestoreSwift



class ChangeView: ObservableObject {
    static let shared = ChangeView()
    @ObservedObject var printControl = PrintControl.shared
    @ObservedObject var froopDataListener = FroopDataListener.shared
    @ObservedObject var myData = MyData.shared
    @Published var nextView: Bool = false
    @Published var pageNumber: Int = 1
    
    func changeThePageNumber() {
        PrintControl.shared.printProfile("-ChangeView: Function: changeThePageNumber is firing!")
        if self.nextView == true {
            self.pageNumber += 1
            self.nextView = false
        }
    }
}

struct NFWalkthroughScreen: View {
    @Environment(\.colorScheme) var colorScheme
    @StateObject var locationViewModel = LocationSearchViewModel()
    @ObservedObject var froopData: FroopData
    @ObservedObject var myData = MyData.shared
    @ObservedObject var changeView = ChangeView.shared
    @State private var homeViewModel = HomeViewModel()
    @Binding var showNFWalkthroughScreen: Bool
    @Binding var froopAdded: Bool
    
    var body: some View {
        // For Slide Animation...
        
        ZStack {
            VStack {
                HStack {
                    Button {
                        changeView.pageNumber -= 1
                    } label: {
                        Image(systemName: "arrow.backward.square.fill")
                            .font(.system(size: 24))
                            .foregroundColor(colorScheme == .dark ? .black : .black)
                            .opacity(changeView.pageNumber >= 2 ? 0.0 : 1.0)
                    }
                    Spacer()
                }
                Spacer()
            }
            .padding(.top, 20)
            .padding(.leading, 20)
            // Changing Between Views....
            
            switch changeView.pageNumber {
                case 1:
                    FroopTypeOrTemplate(froopData: froopData)
                        .environmentObject(locationViewModel)
                    
                case 2:
                    FroopLocationView(changeView: changeView, froopData: froopData, homeViewModel: $homeViewModel)
                        .environmentObject(locationViewModel)
                case 3:
                    FroopDateView(changeView: changeView, froopData: froopData, homeViewModel: $homeViewModel)
                        .environmentObject(locationViewModel)
                case 4:
                    FroopNameView(froopData: froopData)
                        .environmentObject(locationViewModel)
                    
                case 5:
                    FroopSummaryView(froopData: froopData, changeView: changeView, showNFWalkthroughScreen: $showNFWalkthroughScreen, froopAdded: $froopAdded)
                        .environmentObject(locationViewModel)
                default:
                    Text("Invalid page number")
            }
        }
    }
}
