//
//  Month.swift
//  FroopProof
//
//  Created by David Reed on 6/12/23.
//

import SwiftUI

struct Month: Identifiable {
    let id = UUID()
    let name: String
    let froopHistories: [FroopHistory]

    static let preview: [Month] =
    [
        Month(name: "January", froopHistories: [

        ]),
        Month(name: "February", froopHistories: [

        ]),
        Month(name: "March", froopHistories: [

        ]),
        Month(name: "April", froopHistories: [

        ]),
        Month(name: "May", froopHistories: [

        ]),
        Month(name: "June", froopHistories: [

        ]),
        Month(name: "July", froopHistories: [

        ]),
        Month(name: "August", froopHistories: [

        ]),
        Month(name: "September", froopHistories: [

        ]),
        Month(name: "October", froopHistories: [

        ]),
        Month(name: "November", froopHistories: [

        ]),
        Month(name: "December", froopHistories: [

        ]),
    ]
}
