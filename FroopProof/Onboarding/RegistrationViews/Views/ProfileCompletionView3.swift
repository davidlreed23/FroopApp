//
//  ProfileCompletionView3.swift
//  FroopProof
//
//  Created by David Reed on 1/19/23.
//

import SwiftUI



struct ProfileCompletionView3: View {
    
    
    
    @ObservedObject var printControl = PrintControl.shared
   
    @ObservedObject var froopDataListener = FroopDataListener.shared
   
 
    
    var PCtotalPages = 6
    @AppStorage("ProfileCompletionCurrentPage") var ProfileCompletionCurrentPage = 3
    var body: some View {
        NavigationView{
            ScrollView (showsIndicators: false) {
                VStack() {
                    
                    TitleView3()
                    
                    Spacer()
                    
                    InformationDetailView3()
                    
                    InformationContainerView3()
                    
                    Spacer(minLength: 10)
                    
                }
                .padding(.horizontal)
                
            }
            .navigationTitle("Froop Beta 6")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button{
                        if ProfileCompletionCurrentPage <= PCtotalPages{
                            ProfileCompletionCurrentPage += 1
                            PrintControl.shared.printProfile(ProfileCompletionCurrentPage.description)
                        }
                    }label:{
                        Text("Next")
                        Image(systemName: "arrow.right.square.fill")
                    }
                }
            }
        }
        
    }
}

struct InformationDetailView3: View {
    
    var title: String = ""
    var subTitle: String = ""
    var imageName: String = "circle"
    
    var body: some View {
        HStack(alignment: .center) {
            Image(systemName: imageName)
                .frame(width: 30, height: 30)
                .font(.largeTitle)
                .foregroundColor(.primary)
                .padding()
                .accessibility(hidden: true)
            
            
            VStack(alignment: .leading) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .accessibility(addTraits: .isHeader)
                
                Text(subTitle)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.leading, 20)
            .padding(.trailing, 20)
        }
        
    }
    
}

struct InformationContainerView3: View {
    var body: some View {
        VStack(alignment: .leading) {
            InformationDetailView3(title: "Find a Location", subTitle: "You select where you want to meet, and the Froop locks in on that location.", imageName: "mappin.square.fill")
            
            InformationDetailView3(title: "Set a Date and Time", subTitle: "Froops have a Pre, During, and Post state which are all dependent on you selecting a Date, Time and Duration for your Froop.", imageName: "calendar.badge.clock")
            
            InformationDetailView3(title: "Invite your Friends", subTitle: "Froops are meant to be shared, so invite the friends you want to hang out with!", imageName: "figure.socialdance")
            
            InformationDetailView3(title: "Show Up!", subTitle: "Your Froop will automate a lot of things, making it super easy for you to relax and enjoy spending time with your friends.", imageName: "figure.walk")
        }
        //.padding(.vertical)
    }
}

struct TitleView3: View {
    var body: some View {
        VStack {
            AdaptiveImage(
                light:
                    Image("FroopLogo")
                    .resizable()
                ,
                dark:
                    Image("FroopLogoWhite")
                    .resizable()
            )
            .aspectRatio(contentMode: .fit)
            .frame(width: 300, alignment: .center)
            .accessibility(hidden: true)
            .padding(.top, 50)
            
            
            Text("How does it work?")
                .customTitleText()
            
            //            Text("Froop")
            //                .customTitleText()
            //                .foregroundColor(.black)
        }
    }
}

