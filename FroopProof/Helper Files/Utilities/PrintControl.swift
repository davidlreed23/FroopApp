//
//  PrintControl.shared.swift
//  FroopProof
//
//  Created by David Reed on 5/9/23.
//

import Foundation

//MARK: PrintControl is a singleton
//MARK: var PrintControl = PrintControl.shared
//MARK: usage:  PrintControl.shared.<property>("Logging in...")

class PrintControl: ObservableObject {
    static let shared = PrintControl()
    
    @Published var developer: String = ""
    @Published var froopCounter: Int = 0
    @Published var printStartUp: Bool = true
    @Published var printMap: Bool = true
    @Published var printFroopDataController: Bool = true
    @Published var printTimeZone: Bool = true
    @Published var printImage: Bool = true
    @Published var printFroopData: Bool = true
    @Published var printMyData: Bool = false
    @Published var printUserData: Bool = false
    @Published var printMediaManager: Bool = true
    @Published var printFroopManager: Bool = true
    @Published var printFriend: Bool = true
    @Published var printLists: Bool = true
    @Published var printTime: Bool = true
    @Published var printProfile: Bool = true
    @Published var printPhotoPicker: Bool = true
    @Published var printAppDelegate: Bool = true
    @Published var printLogin: Bool = true
    @Published var printLocationServices: Bool = true
    @Published var printFroopCreation: Bool = true
    @Published var printInviteFriends: Bool = true
    @Published var printFriendList: Bool = true
    @Published var printFroopDetails: Bool = true
    @Published var printFroopUpdates: Bool = true
    @Published var printFirebaseOperations: Bool = true
    @Published var printErrorMessages: Bool = true
    @Published var printAppStateSetupListener: Bool = false
    @Published var printAppState: Bool = false
    @Published var printUserDataUpdates: Bool = false
    @Published var printNotifications: Bool = false
    
    private init() {}
    
    func printNotifications(_ message: String) {
        if printNotifications {
            print(message)
        }
    }
    
    func printStartUp(_ message: String) {
        if printStartUp {
            print(message)
        }
    }
    
    func printMap(_ message: String) {
        if printMap {
            print(message)
        }
    }
    
    func printFroopDataController(_ message: String) {
        if printFroopDataController {
            print(message)
        }
    }
    
    func printTimeZone(_ message: String) {
        if printTimeZone {
            print(message)
        }
    }
    
    func printImage(_ message: String) {
        if printImage {
            print(message)
        }
    }
    
    func printFroopData(_ message: String) {
        if printFroopData {
            print(message)
        }
    }
    
    func printMyData(_ message: String) {
        if printMyData {
            print(message)
        }
    }
    
    func printUserData(_ message: String) {
        if printUserData {
            print(message)
        }
    }
    
    func printMediaManager(_ message: String) {
        if printMediaManager {
            print(message)
        }
    }
    
    func printFroopManager(_ message: String) {
        if printFroopManager {
            print(message)
        }
    }
    
    func printFriend(_ message: String) {
        if printFriend {
            print(message)
        }
    }
    
    func printLists(_ message: String) {
        if printLists {
            print(message)
        }
    }
    
    func printTime(_ message: String) {
        if printTime {
            print(message)
        }
    }
    
    func printProfile(_ message: String) {
        if printProfile {
            print(message)
        }
    }
    
    func printPhotoPicker(_ message: String) {
        if printPhotoPicker {
            print(message)
        }
    }
    
    func printAppDelegate(_ message: String) {
        if printAppDelegate {
            print(message)
        }
    }
    
    func printLogin(_ message: String) {
        if printLogin {
            print(message)
        }
    }
    
    func printLocationServices(_ message: String) {
        if printLocationServices {
            print(message)
        }
    }
    
    func printFroopCreation(_ message: String) {
        if printFroopCreation {
            print(message)
        }
    }
    
    func printInviteFriends(_ message: String) {
        if printInviteFriends {
            print(message)
        }
    }
    
    func printFriendList(_ message: String) {
        if printFriendList {
            print(message)
        }
    }
    
    func printFroopDetails(_ message: String) {
        if printFroopDetails {
            print(message)
        }
    }
    
    func printFroopUpdates(_ message: String) {
        if printFroopUpdates {
            print(message)
        }
    }
    
    func printFirebaseOperations(_ message: String) {
        if printFirebaseOperations {
            print(message)
        }
    }
    
    func printErrorMessages(_ message: String, file: String = #file, line: Int = #line, function: String = #function) {
        if printPhotoPicker {
            let fileName = (file as NSString).lastPathComponent // To get just the file's name, not the whole path
            print("\(fileName):\(line) \(function) - \(message)")
        }
    }
    
    func printAppStateSetupListener(_ message: String) {
        if printAppStateSetupListener {
            print(message)
        }
    }
    
    func printAppState(_ message: String) {
        if printAppState {
            print(message)
        }
    }

    func printUserDataUpdates(_ message: String) {
        if printUserDataUpdates {
            print(message)
        }
    }
}
