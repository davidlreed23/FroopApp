//
//  LocationSearchView.swift
//  FroopProof
//
//  Created by David Reed on 1/19/23.
//

import SwiftUI
import UIKit

struct LocationSearchView: View {
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject var appStateManager = AppStateManager.shared
    @ObservedObject var printControl = PrintControl.shared
    @ObservedObject var locationServices = LocationServices.shared
    @ObservedObject var froopDataListener = FroopDataListener.shared
    
    @State private var isEditing = false
    @EnvironmentObject var viewModel: LocationSearchViewModel
    @Binding var mapState: MapViewState
    @Binding var showLocationSearchView: Bool
    @EnvironmentObject var locationViewModel: LocationSearchViewModel
    @Binding var showRec: Bool
    @State var locationFilter: [String] = ["Search Nearby"]
    @ObservedObject var froopData: FroopData
    
    var body: some View {
        //LocationSearchView(locationFilter: locationFilter)
        ZStack(alignment: .top) {
            VStack(alignment: .center) {
                Text("You have a location in mind?")
                    .font(.system(size: 48, weight: .thin))
                    .foregroundColor(colorScheme == .dark ? .white : .white)
                    .opacity(isEditing ? 0 : 1)
                    .padding(.top, 150)
                    .multilineTextAlignment(.center)
                    .padding(.leading, 15)
                    .padding(.trailing, 15)
                ZStack{
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.clear)
                        .frame(maxHeight: withAnimation(.easeInOut(duration: 0.4)) {
                            isEditing ? 150 : 50
                        })
                        .padding(.leading, 20)
                        .padding(.trailing, 20)
                        .overlay(
                            Text("Search Location")
                                .font(.title)
                                .foregroundColor(colorScheme == .dark ? .white : .white)
                                .opacity(isEditing ? 0 : 0.6)
                                .fontWeight(.light)
                                .opacity(0.7)
                                .offset(x: 10, y: 0)
                               
                        )
                        .border(Color.gray, width: 1)
                        .cornerRadius(4)
                        .foregroundColor(Color.gray)
                        .padding(.leading, 15)
                        .padding(.trailing, 15)
                    
                    TextField("", text: $viewModel.queryFragment, onCommit: {
                        withAnimation(.easeInOut(duration: 0.4)) {
                            self.isEditing = false
                        }
                    })
                    .foregroundColor(isEditing ? (colorScheme == .dark ? .white : .white) : .clear)
                    .font(isEditing ? .system(size: 48, weight: .thin) : .title)
                    .opacity(1)
                    .fontWeight(.thin)
                    .padding(.leading, 20)
                    .padding(.trailing, 20)
                    
                    if !isEditing {
                        Text("Search Location")
                            .font(.title)
                            .foregroundColor(colorScheme == .dark ? .white : .white)
                            .opacity(isEditing ? 0.6 : 0)
                            .fontWeight(.light)
                            .offset(x: 10, y: 0)
                    }
                }
                .frame(maxWidth: 500)
                .padding(.leading, 25)
                .padding(.trailing, 25)
                if isEditing {
                    ScrollView (showsIndicators: false) {
                        VStack(alignment: .leading) {
                            ForEach(viewModel.results.filter { result in
                                !locationFilter.contains(where: {result.subtitle.contains($0)}) &&
                                !result.subtitle.isEmpty
                            }, id: \.self) { result in
                                LocationSearchResultCell(title: result.title, subtitle: result.subtitle)
                                    .onTapGesture {
                                        LocationServices.shared.trackUserLocation = false
                                        withAnimation(.spring()) {
                                            viewModel.selectLocation(result, froopData: froopData)
                                            mapState = .locationSelected
                                            showRec = true
                                        }
                                    }
                            }
                        }
                        .padding(.top, 15)
                    }
                    .frame(minWidth: 0, maxWidth: 335, minHeight: 0, maxHeight: 250)
                    .padding(.leading, 15)
                    .padding(.trailing, 15)
                }
            }
            .offset(y: isEditing ? -200 : 0)
        }
        Spacer()
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { _ in
                withAnimation {
                    self.isEditing = true
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
                withAnimation {
                    self.isEditing = false
                }
            }
    }
}
