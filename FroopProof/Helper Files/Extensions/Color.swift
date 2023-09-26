//
//  Color.swift
//  FroopProof
//
//  Created by David Reed on 1/19/23.
//

import SwiftUI




struct ColorTheme {
    static let primaryTextColor = Color("PrimaryTextColor")
    static let backgroundColor = Color("BackgroundColor")
    static let secondaryBackgroundColor = Color("SecondaryBackgroundColor")
    static let systemBackgroundColor = Color("SystemBackgroundColor")
    static let mapOverlayColor = Color("MapOverlay")
}

struct AdaptiveImage: View {
    @Environment(\.colorScheme) var colorScheme
    let light: Image
    let dark: Image

    @ViewBuilder var body: some View {
        if colorScheme == .light {
            light
        } else {
            dark
        }
    }
}
