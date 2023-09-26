//
//  FroopMessageView.swift
//  FroopProof
//
//  Created by David Reed on 6/23/23.
//

import SwiftUI

struct FroopMessageView: View, TaskAddon {
    var systemImageName: String { return "ellipsis.bubble.fill" }
    var description: String { return "Message" }

    func action() {
        // Implement your action here
    }
    
    var body: some View {
        VStack {
            Image(systemName: systemImageName)
                .font(.system(size: 35))
                .foregroundColor(.black)
                .opacity(0.7)
                .fontWeight(.thin)
                .frame(maxWidth: 50, maxHeight: 40)
            Text(description)
                .foregroundColor(.black)
                .font(.system(size: 14))
                .fontWeight(.light)
        }
        .onTapGesture { action() }
        .padding(.trailing, 20)
    }
}
