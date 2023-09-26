//
//  FroopTimerServices.swift
//  FroopProof
//
//  Created by David Reed on 5/30/23.
//

import Foundation
import SwiftUI
import UIKit
import ObjectiveC

class TimerServices: ObservableObject {
    static let shared = TimerServices()
    
    
    
    var timer: Timer?
    var shouldCallAppStateTransition = true
    var shouldCallupdateUserLocationInFirestore = true
    
    init() {
        startTimer()
    }
    
    
    var firebaseServices: FirebaseServices {
        return FirebaseServices.shared
    }
    
    func startTimer() {
        
        guard firebaseServices.isAuthenticated else {
            return
        }
        
        firebaseServices.checkDoc(userID: firebaseServices.uid) { (exists) in
            guard exists else {
                print("User document does not exist.")
                return
            }
            // Invalidate any existing timer
            self.timer?.invalidate()
            
            // Create and schedule a new timer
            self.timer = Timer.scheduledTimer(timeInterval: 15, target: self, selector: #selector(self.timerFired), userInfo: nil, repeats: true)
        }
    }
    
    func stopTimer() {
        // Invalidate the timer
        timer?.invalidate()
        timer = nil
    }
    
    @objc func timerFired() {
        // This function will be called every time the timer fires
      
        if shouldCallupdateUserLocationInFirestore {
            LocationManager.shared.updateUserLocationInFirestore()
        }
    }
    
    func formatDate(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E MMM dd"
        return formatter.string(from: date)
    }
    
}
