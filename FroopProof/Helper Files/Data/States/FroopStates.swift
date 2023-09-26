//
//  FroopStates.swift
//  FroopProof
//
//  Created by David Reed on 2/6/23.
//

import Foundation

enum FroopState: Int, CustomStringConvertible {
    case noInput
    case froopCreated
    case invitedFriends
    case froopPreGame
    case froopStarted
    case froopInProgress
    case froopCompleted
    case froopArchived
    case froopCancelled
    case froopEdit

    var description: String {
        switch self {
        case .noInput:
            return "No input"
        case .froopCreated:
            return "Froop created"
        case .invitedFriends:
            return "Invited friends"
        case .froopPreGame:
            return "Froop pre-game"
        case .froopStarted:
            return "Froop started"
        case .froopInProgress:
            return "Froop in progress"
        case .froopCompleted:
            return "Froop completed"
        case .froopArchived:
            return "Froop archived"
        case .froopCancelled:
            return "Froop cancelled"
        case .froopEdit:
            return "Froop edit"
        }
    }
    func onStateActivated() {
        PrintControl.shared.printFroopManager("-FroopState: Function: onStateActivated is firing!")
           switch self {
           case .noInput:
               PrintControl.shared.printFroopManager("No noInput activated")
           case .froopCreated:
               PrintControl.shared.printFroopManager("Froop froopCreated activated")
           case .invitedFriends:
               PrintControl.shared.printFroopManager("Froop invitedFriends activated")
           case .froopPreGame:
               PrintControl.shared.printFroopManager("Froop froopPreGame activated")
           case .froopStarted:
               PrintControl.shared.printFroopManager("Froop froopStarted activated")
           case .froopInProgress:
               PrintControl.shared.printFroopManager("Froop froopInProgress activated")
           case .froopCompleted:
               PrintControl.shared.printFroopManager("Froop froopCompleted activated")
           case .froopArchived:
               PrintControl.shared.printFroopManager("Froop froopArchived activated")
           case .froopCancelled:
               PrintControl.shared.printFroopManager("Froop froopCancelled activated")
           case .froopEdit:
               PrintControl.shared.printFroopManager("Froop froopEdit activated")
           }
       }
}
