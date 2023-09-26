//
//  MediaManager.swift
//  FroopProof
//
//  Created by David Reed on 4/19/23.
//

import Foundation
import UIKit
import SwiftUI
import CoreLocation
import Photos

enum MediaAsset {
    case phAsset(PHAsset)
    case uiImage(UIImage)
}

class MediaManager: ObservableObject {
    
    
    
    @ObservedObject var printControl = PrintControl.shared
   
    @ObservedObject var froopDataListener = FroopDataListener.shared
   
 
    
    @Published var activeFroopId: String = ""
    private let imageManager = PHCachingImageManager()

    // Add a new init method that accepts AppDelegate
    public init() {
       
    }
    
    func requestPhotoLibraryAuthorization(completion: @escaping (Bool) -> Void) {
        PrintControl.shared.printMediaManager("-MediaManager: Function: requestPhotoLibraryAuthorization is firing!")
        PHPhotoLibrary.requestAuthorization { status in
            DispatchQueue.main.async {
                completion(status == .authorized)
            }
        }
    }
    
    func fetchMediaFromPhotoLibrary(froopStartTime: Date, froopEndTime: Date, completion: @escaping ([PHAsset]) -> Void) {
        PrintControl.shared.printMediaManager("-MediaManager: Function: fetchMediaFromPhotoLibrary is firing!")
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "creationDate >= %@ AND creationDate <= %@", froopStartTime.addingTimeInterval(-30 * 60) as NSDate, froopEndTime.addingTimeInterval(30 * 60) as NSDate)
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]

        PrintControl.shared.printMediaManager("Fetching media from Photo Library with start time: \(froopStartTime) and end time: \(froopEndTime)")

        let fetchResult = PHAsset.fetchAssets(with: fetchOptions)
        var assets: [PHAsset] = []
        fetchResult.enumerateObjects { (asset, _, _) in
            PrintControl.shared.printMediaManager("Found asset: \(asset.localIdentifier), creationDate: \(asset.creationDate ?? Date())")
            assets.append(asset)
        }

        PrintControl.shared.printMediaManager("Fetched \(assets.count) assets from Photo Library")
        completion(assets)
    }

}
