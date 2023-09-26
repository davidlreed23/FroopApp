//
//  RideType.swift
//  FroopProof
//
//  Created by David Reed on 1/19/23.
//

import Foundation

enum RideType: Int, CaseIterable, Identifiable, Codable {
    case setFroopLocation
  
    
    var id: Int { return rawValue }
    
    var description: String {
        switch self {
        case .setFroopLocation: return "Distance"

        }
    }
    
    var imageName: String {
        switch self {
        case .setFroopLocation: return "location.circle"

        }
    }
    
    var baseFare: Double {
        switch self {
        case .setFroopLocation: return 5

        }
    }
    
    func computePrice(for distanceInMeters: Double) -> Double {
       
        let distanceInMiles = distanceInMeters / 1600
        
        switch self {
        case .setFroopLocation: return distanceInMiles

        }
    }
}
