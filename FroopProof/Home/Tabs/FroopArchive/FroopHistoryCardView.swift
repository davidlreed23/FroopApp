//
//  FroopHistoryCardView.swift
//  FroopProof
//
//  Created by David Reed on 6/11/23.
//

import SwiftUI
import Photos
import FirebaseStorage
import Firebase
import FirebaseAuth
import FirebaseFirestore
import Kingfisher

struct FroopHistoryCardView: View {
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject var froopManager = FroopManager.shared
    @State var froopHistory: FroopHistory
    @Binding var froopHistoryOpen: Bool
    
    var body: some View {
        ZStack (alignment: .center){
            Rectangle()
                .frame(height: 100)
                .foregroundColor(.clear)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .onTapGesture {
                    froopHistoryOpen = true
                    froopManager.froopHistoryFroop = froopHistory.froop
                    froopManager.froopHistoryHost = froopHistory.host
                }

            
            VStack (alignment: .leading) {
                HStack {
                    Text(formatDate(passedDate: froopHistory.froop.froopStartTime))
                        .frame(maxWidth: 225, alignment: .leading)
                        .font(.system(size: 12))
                        .foregroundColor(Color(red: 249/255, green: 0/255, blue: 98/255 ))
                        .opacity(0.8)
                        .fontWeight(colorScheme == .dark ? .regular : .regular)
                        .padding(.leading, 5)
                    Spacer()
                }
                Spacer()
            }
            .frame(maxHeight: 95)
            
            HStack (alignment: .center, spacing: 2) {
                VStack (alignment: .leading) {
                    ZStack {
                        Circle()
                        
                        KFImage(URL(string: froopHistory.froop.froopHostPic))
                            .placeholder {
                                ProgressView()
                            }
                            .resizable()
                            .scaledToFill()
                            .clipShape(Circle())
                        
                    }
                }
                .frame(width: 65, height: 65, alignment: .leading)
                .padding(.top, 15)
                
                VStack (alignment: .leading){
                    
                    Text(froopHistory.froop.froopName)
                        .lineLimit(2)
                        .font(.system(size: 16))
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                        .opacity(0.8)
                        .fontWeight(.regular)
                        .padding(.top)
                    
                    Text("Hosted by: \(froopHistory.host.firstName) \(froopHistory.host.lastName)")
                        .font(.system(size: 12))
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                        .opacity(0.8)
                        .fontWeight(.thin)
                        .padding(.top, 15)
                    
                    Spacer()
                }
                .frame(maxWidth: 250, alignment: .leading)
                .padding(.top, 15)
                .padding(.leading, 10)
                
                Divider()
                    .padding(.trailing, 10)
                
                VStack (alignment: .trailing){
                    HStack {
                        Image(systemName: "person.crop.circle")
                            .font(.system(size: 20))
                            .foregroundColor(Color(red: 249/255, green: 0/255, blue: 98/255 ))
                        Spacer()
                        Text("\(froopHistory.friends.count)")
                            .font(.system(size: 14))
                    }
                    .fontWeight(.light)
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                    .opacity(0.8)
                    HStack {
                        Image(systemName: "photo.circle")
                            .font(.system(size: 20))
                            .foregroundColor(Color(red: 249/255, green: 0/255, blue: 98/255 ))
                        Spacer()
                        Text("\(froopHistory.froop.froopImages.count)")
                            .frame(alignment: .trailing)
                            .font(.system(size: 14))
                    }
                    .fontWeight(.light)
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                    .opacity(0.8)
                    HStack {
                        Image(systemName: "video.circle")
                            .font(.system(size: 20))
                            .foregroundColor(Color(red: 249/255, green: 0/255, blue: 98/255 ))
                        Spacer()
                        Text("\(froopHistory.froop.froopVideos.count)")
                            .font(.system(size: 14))
                    }
                    .fontWeight(.light)
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                    .opacity(0.8)
                }
                .frame(maxWidth: 50)
                Spacer()
            }
            .padding(.leading, 15)
            .padding(.trailing, 15)
        }
    }
    
    func formatDate(passedDate: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d',' h:mm a"
        let formattedDate = formatter.string(from: passedDate)
        return formattedDate
    }
    
}

