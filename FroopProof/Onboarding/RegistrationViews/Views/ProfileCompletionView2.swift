//
//  ProfileCompletionView2.swift
//  FroopProof
//
//  Created by David Reed on 1/19/23.
//

import SwiftUI


struct ProfileCompletionView2: View {
    
    
    
    @ObservedObject var printControl = PrintControl.shared
   
    @ObservedObject var froopDataListener = FroopDataListener.shared
   
 
    
    var PCtotalPages = 6
    @AppStorage("ProfileCompletionCurrentPage") var ProfileCompletionCurrentPage = 2
    var body: some View {
        NavigationView{
            ScrollView (showsIndicators: false) {
                
                VStack {
                    
                    TitleView2()
                    
                    Spacer()
                    
                    InformationDetailView2()
                    
                    InformationContainerView2()
                    
                    Spacer(minLength: 10)
                    
                }
                .padding(.horizontal)
                
            }
            .navigationTitle("Froop Beta 5")
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


struct InformationDetailView2: View {
    
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


struct InformationContainerView2: View {
    var body: some View {
        VStack(alignment: .leading) {
            InformationDetailView2(title: "Get Together", subTitle: "Each Froop is a way for you and your friends to organize things you can do together in the real world.", imageName: "person.3.fill")
            
            InformationDetailView2(title: "Have Fun", subTitle: "What ever you and your friends like to do, Froop takes care of everything letting you focus on enjoying yourself.", imageName: "figure.play")
            
            InformationDetailView2(title: "Share the Experience", subTitle: "Capture the moment and share videos, pictures, and more with your friends all in one easy place.", imageName: "shared.with.you")
            
            InformationDetailView2(title: "Stay Informed", subTitle: "Every Froop tracks all the details for you, helping you focus on what matters most.  Having fun with your friends.", imageName: "info.circle")
        }
        //.padding(.vertical)
    }
}




struct TitleView2: View {
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
            
            
            Text("Froops Let You...")
                .customTitleText()
            
            //            Text("Froop")
            //                .customTitleText()
            //                .foregroundColor(.black)
        }
    }
}





