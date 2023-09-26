//
//  FroopNotificationCenter.swift
//  FroopProof
//
//  Created by David Reed on 4/16/23.
//

import SwiftUI
import Foundation



class FroopNotificationCenter {
    weak var delegate: FroopNotificationDelegate?

    func notifyParticipantsChanged(_ froop: Froop) {
        delegate?.froopParticipantsChanged(froop)
    }

    func notifyStatusChanged(_ froop: Froop) {
        delegate?.froopStatusChanged(froop)
    }
}
