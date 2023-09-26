//
//  MapViewActionButton.swift
//  FroopProof
//
//  Created by David Reed on 1/19/23.
//

import SwiftUI
import MapKit

struct MapViewActionButton: View {
    @ObservedObject var appStateManager = AppStateManager.shared
    @ObservedObject var printControl = PrintControl.shared
    @ObservedObject var locationServices = LocationServices.shared
    @ObservedObject var froopDataListener = FroopDataListener.shared
    
    @Binding var mapState: MapViewState
    @EnvironmentObject var viewModel: LocationSearchViewModel
    
    
    var body: some View {
        Text("")
    }
            
//        Button {
//            withAnimation(.spring()) {
//                actionForState(mapState)
//            }
//        } label: {
//            Image(systemName: imageNameForState(mapState))
//                .font(.title2)
//                .foregroundColor(.black)
//                .padding()
//                .background(.white)
//                .clipShape(Circle())
//                .shadow(color: .black, radius: 6)
//        }
//        .frame(maxWidth: .infinity, alignment: .leading)
//    }
    
    func actionForState(_ state: MapViewState) {
        PrintControl.shared.printLocationServices("-MapViewActionButton: Function: actionForState is firing!")
        switch state {
        case .noInput:
            mapState = .searchingForLocation
        case .searchingForLocation:
            mapState = .noInput
        case .locationSelected, .polylineAdded:
            mapState = .noInput
            viewModel.selectedFroopLocation = (nil as CLLocationCoordinate2D?)!
        case .tripRequested,
                .tripAccepted,
                .driverArrived,
                .tripInProgress,
                .arrivedAtDestination,
                .tripCompleted,
                .tripCancelled:
            mapState = .noInput
            viewModel.selectedFroopLocation = (nil as CLLocationCoordinate2D?)!
            
        }
    }
    
    func imageNameForState(_ state: MapViewState) -> String {
        PrintControl.shared.printLocationServices("-MapViewActionButton: Function: imageNameForState is firing!")
        switch state {
        case .searchingForLocation,
                .locationSelected,
                .tripAccepted,
                .tripRequested,
                .tripCompleted,
                .polylineAdded:
            return "arrow.left"
        case .noInput, .tripCancelled:
            return "line.3.horizontal"
        default:
            return "line.3.horizontal"
        }
    }
}


