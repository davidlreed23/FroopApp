//
//  TripState.swift
//  FroopProof
//
//  Created by David Reed on 1/20/23.
//

import Foundation
import SwiftUI
import UIKit


enum TripState: Int, Codable {
    
    case driversUnavailable
    case rejectedByDriver
    case rejectedByAllDrivers
    case requested // value has to equal 3 to correspond to mapView tripRequested state
    case accepted
    case driverArrived
    case inProgress
    case arrivedAtDestination
    case complete
    case cancelled
}

