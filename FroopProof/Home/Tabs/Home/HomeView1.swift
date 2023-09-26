//
//  HomeView1.swift
//  FroopProof
//
//  Created by David Reed on 2/10/23.
//




import SwiftUI
import UIKit
import FirebaseFirestore
import FirebaseAuth
import Kingfisher


struct HomeView1: View {

    @ObservedObject var appStateManager = AppStateManager.shared
    @ObservedObject var printControl = PrintControl.shared
    @ObservedObject var locationServices = LocationServices.shared
    @ObservedObject var froopDataListener = FroopDataListener.shared
    @StateObject private var sharedViewModel = SharedViewModel()
    @ObservedObject var userData = UserData()
    @ObservedObject var changeView = ChangeView()
    @ObservedObject var froopData = FroopData()
    @ObservedObject var photoData: PhotoData
    @State var animationAmount = 1.0
    @State var showSheet = false
    @State var filteredFroopsCount: Int = 0
    @State var showNFWalkthroughScreen = false
    @State private var walkthroughScreen: NFWalkthroughScreen? = nil
    @State private var froops: [Froop] = []
    @State var firstFinish = false
    @State var froopAdded: Bool = false
    @AppStorage("ProfileCompletionCurrentPage") var ProfileCompletionCurrentPage = 5
    var PCtotalPages = 6
    
    var body: some View {
        NavigationView  {
            ZStack {
                ZStack {
                    Rectangle()
                        .fill(Color.gray)
                        .frame(minWidth: 0, maxWidth: .infinity, minHeight: UIScreen.main.bounds.height / 1, maxHeight: UIScreen.main.bounds.height)
                        .position(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height / 2)
                    Rectangle()
                        .fill(Color.white)
                        .frame(minWidth: 0, maxWidth: .infinity, minHeight: UIScreen.main.bounds.height / 1, maxHeight: UIScreen.main.bounds.height)
                        .position(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height / 1.2)
                       
                    VStack{
                        VStack{
                            Text("\(sharedViewModel.eveningText()) \(MyData.shared.firstName)")
                                .font(.system(size: 18))
                                .foregroundColor(.white)
                                .fontWeight(.light)
                                .padding(.top, 40)
                                .padding(.bottom, 1)
                            
                            Text("Welcome!")
                                .font(.system(size: 30))
                                .foregroundColor(.white)
                                .fontWeight(.thin)
                            Text("Happy Frooping")
                                .font(.system(size: 30))
                                .foregroundColor(.white)
                                .fontWeight(.thin)
                            
                            
                            Button {
                                ProfileCompletionCurrentPage = 6
                            } label: {
                            Text("Skip")
                                    .font(.system(size: 24))
                                    .fontWeight(.thin)
                                    .foregroundColor(.gray)
                            }
                            .padding(.top, 100)
                        }
                        .padding(.top, 50)
                        
                        
                        Spacer()
                        Text("Create Your")
                            .font(.system(size: 48))
                            .foregroundColor(.black)
                            .fontWeight(.light)
                        Text("First Froop")
                            .font(.system(size: 48))
                            .foregroundColor(.black)
                            .fontWeight(.light)
                            .padding(.bottom, 25)
                        
                        Button {
                            LocationManager.shared.requestAlwaysAuthorization()
                            self.showSheet = false  // Dismiss the blurred sheet
                            changeView.pageNumber = 1
                            self.walkthroughScreen = NFWalkthroughScreen(froopData: FroopData(), showNFWalkthroughScreen: $showNFWalkthroughScreen, froopAdded: $froopAdded)
                            self.showNFWalkthroughScreen = true
                        } label: {
                            ZStack {
                                Circle()
                                    .foregroundColor(.black)
                                    .opacity(0.1)
                                    .frame(width: 150, height: 150)
                                    .scaleEffect(animationAmount)
                                Circle()
                                    .foregroundColor(.black)
                                    .frame(width: 100, height: 100)
                                    .scaleEffect(animationAmount)
                                Image(systemName: "plus")
                                    .foregroundColor(.white)
                                    .font(.title)
                                    .fontWeight(.bold)
                            }
                        }
                        .padding(.bottom, 100)
                        .sheet(isPresented: $showNFWalkthroughScreen) {
                            self.walkthroughScreen
                        }
                        
                    }
                }
            }
        }
    }
}

