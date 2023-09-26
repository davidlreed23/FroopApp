//
//  LocationResultsCell.swift
//  FroopProof
//
//  Created by David Reed on 1/19/23.
//

import SwiftUI
import MapKit
import CoreLocation

struct LocationSearchResultCell: View {
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject var appStateManager = AppStateManager.shared
    @ObservedObject var printControl = PrintControl.shared
    @ObservedObject var locationServices = LocationServices.shared
    @ObservedObject var froopDataListener = FroopDataListener.shared
 
    
    let title: String
    let subtitle: String
    @State private var location: FroopData?
    var body: some View {
        ZStack {
            Rectangle()
                .fill(Color.primary.opacity(0.4))
                .frame(width: 410, height: 75)
                .cornerRadius(5)
                .border(.gray)
                
                
                
            
            HStack {
                Image(systemName: "mappin.circle.fill")
                    .resizable()
                    .foregroundColor(colorScheme == .dark ? .white : .white)
                    .accentColor(.black)
                    .frame(width: 40, height: 40)
                    
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.body)
                        .fontWeight(.bold)
                        .foregroundColor(colorScheme == .dark ? .white : .white)

                    
                    
                    Text(subtitle)
                        .font(.system(size: 15))
                        .foregroundColor(colorScheme == .dark ? .white : .white)

                        .fontWeight(.light)
                        .frame(minWidth: 0, maxWidth: 335)
                    
                    Divider()
                }
                .padding(.leading, 8)
                .padding(.vertical, 4)
            }
            .padding(.leading)
            
            
        }
        .padding(.leading, 15)
        .padding(.trailing, 15)
    }
}

