//
//  MediaData.swift
//  FroopProof
//
//  Created by David Reed on 4/19/23.
//

import Foundation
import CoreLocation
import SwiftUI
import MapKit

struct MediaData: Identifiable {
    
    
    
    @ObservedObject var printControl = PrintControl.shared
   
    @ObservedObject var froopDataListener = FroopDataListener.shared
   
 
    
    let id: String
    let froopId: String
    let type: MediaType
    let localURL: String
    let createdAt: Date
    let latitude: Double
    let longitude: Double
    var show: Bool
}

enum MediaType: String {
    case image
    case video
}
