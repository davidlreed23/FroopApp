//
//  ProfilePhotoView.swift
//  FroopProof
//
//  Created by David Reed on 2/6/23.
//

import SwiftUI
import Kingfisher

struct HostProfilePhotoView: View {
   
    var imageUrl: String
    
    var body: some View {
        ZStack {
            Circle()
                .frame(width: 60, height: 60)
            KFImage(URL(string: imageUrl))
                .resizable()
                .scaledToFit()
                .frame(width: 60, height: 80)
                .clipShape(Circle())
                .padding()
            
        }
    }
}

