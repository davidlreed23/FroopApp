//
//  SaveAnnotationView.swift
//  FroopProof
//
//  Created by David Reed on 7/19/23.
//


import SwiftUI
import UIKit
import CoreLocation
import MapKit
import SwiftUIBlurView
import FirebaseFirestore


struct SaveAnnotationView: View {
    @ObservedObject var annotation: FroopDropPin
    var appStateManager = AppStateManager.shared
    let db = FirebaseServices.shared.db
    @State private var title: String
    @State private var subtitle: String
    @State private var messageBody: String
    @State private var creatorUID: String
    @State private var profileImageUrl: String

    init(annotation: FroopDropPin) {
        self.annotation = annotation
        self._title = State(initialValue: annotation.title ?? "No Title")
        self._subtitle = State(initialValue: annotation.subtitle ?? "No Subtitle")
        self._messageBody = State(initialValue: annotation.messageBody ?? "Message Here")
        self._creatorUID = State(initialValue: annotation.creatorUID ?? FirebaseServices.shared.uid)
        self._profileImageUrl = State(initialValue: annotation.profileImageUrl ?? MyData.shared.profileImageUrl)
    }

    var body: some View {
        ZStack {
            VStack {
                Spacer()
                ZStack {
                    if appStateManager.isAnnotationMade {
                        BlurView(style: .light)
                            .edgesIgnoringSafeArea(.bottom)
                            .transition(.move(edge: .bottom))
                            .frame(height: 350)
                    }
                    
                    VStack {
                        Spacer()
                        Rectangle()
                            .fill(Color(.black).gradient)
                            .opacity(0.5)
                            .frame(height: 350)
                    }
                    VStack (alignment: .leading) {
                        HStack {
                            Text("Latitude: \(annotation.coordinate.latitude)")
                            Text("Longitude: \(annotation.coordinate.longitude)")
                        }
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                        .fontWeight(.light)
                        .padding(.top, 45)
                        .padding(.leading, 15)
                        
                        // Only the creator can edit the TextFields
                        if creatorUID == FirebaseServices.shared.uid {
                            TextField("Title", text: $title)
                                .font(.system(size: 16))
                                .foregroundColor(.white)
                                .fontWeight(.regular)
                                .padding(.top, 10)
                                .multilineTextAlignment(.leading)
                                .padding(.leading, 20)
                                .disabled(creatorUID != FirebaseServices.shared.uid)
                                
                            TextField("Subtitle", text: $subtitle)
                                .font(.system(size: 16))
                                .foregroundColor(.white)
                                .fontWeight(.light)
                                .multilineTextAlignment(.leading)
                                .padding(.leading, 20)
                                .disabled(creatorUID != FirebaseServices.shared.uid)

                            TextField("Message Here", text: $messageBody)
                                .font(.system(size: 16))
                                .foregroundColor(.white)
                                .fontWeight(.light)
                                .multilineTextAlignment(.leading)
                                .padding(.top, 1)
                                .padding(.leading, 20)
                                .disabled(creatorUID != FirebaseServices.shared.uid)
                        } else {
                            Text(title)
                                .font(.system(size: 16))
                                .foregroundColor(.white)
                                .fontWeight(.regular)
                                .padding(.top, 10)
                                .multilineTextAlignment(.leading)
                                .padding(.leading, 20)
                                .disabled(creatorUID != FirebaseServices.shared.uid)
                                
                            Text(subtitle)
                                .font(.system(size: 16))
                                .foregroundColor(.white)
                                .fontWeight(.light)
                                .multilineTextAlignment(.leading)
                                .padding(.leading, 20)
                                .disabled(creatorUID != FirebaseServices.shared.uid)

                            Text(messageBody)
                                .font(.system(size: 16))
                                .foregroundColor(.white)
                                .fontWeight(.light)
                                .multilineTextAlignment(.leading)
                                .padding(.top, 1)
                                .padding(.leading, 20)
                                .disabled(creatorUID != FirebaseServices.shared.uid)
                        }

                        Spacer()
                    }
                }
            }
            VStack {
                HStack {
                    Spacer()
                    Button(action: {
                        print(self.appStateManager.isAnnotationMade)
                        withAnimation {
                            self.appStateManager.isAnnotationMade = false
                            self.appStateManager.isFroopTabUp = true
                        }
                    }) {
                        Image(systemName: "xmark.square")
                            .fontWeight(.light)
                            .foregroundColor(.white)
                            .font(.system(size: 24))
                            .padding(.trailing, 10)
                            .padding(.top, 25)
                    }
                }
                Spacer()
                if creatorUID == FirebaseServices.shared.uid {
                    Button(action: saveAnnotation) {
                        ZStack {
                            Rectangle()
                                .foregroundColor(.clear)
                                .border(.gray, width: 0.5)
                                .frame(width: 150, height: 30)
                            Text("Save Pin")
                                .font(.system(size: 16))
                                .foregroundColor(.white)
                                .fontWeight(.light)
                        }
                    }
                    .padding(.bottom, 75)
                } else {
                    EmptyView()
                }
            }
        }
        .frame(minHeight: 350, maxHeight: 350)
    }

    func saveAnnotation() {
        annotation.title = title.isEmpty ? "No Title" : title
        annotation.subtitle = subtitle.isEmpty ? "No Subtitle" : subtitle
        annotation.messageBody = messageBody.isEmpty ? "Message Here" : messageBody
        annotation.creatorUID = creatorUID.isEmpty ? FirebaseServices.shared.uid : creatorUID
        annotation.profileImageUrl = profileImageUrl.isEmpty ? MyData.shared.profileImageUrl : profileImageUrl
        
        let froopHost = appStateManager.inProgressFroop.froopHost
        let froopId = appStateManager.inProgressFroop.froopId
        let collectionPath = "users/\(froopHost)/myFroops/\(froopId)/annotations"
        let docData: [String: Any] = [
            "title": annotation.title ?? "No Title",
            "subtitle": annotation.subtitle ?? "No Subtitle",
            "messageBody": annotation.messageBody ?? "Message Here",
            "coordinate": geoPoint(from: annotation.coordinate),
            "creatorUID": annotation.creatorUID ?? FirebaseServices.shared.uid,
            "profileImageUrl": annotation.profileImageUrl ?? MyData.shared.profileImageUrl
        ]
        
        db.collection(collectionPath).addDocument(data: docData) { err in
            if let err = err {
                print("Error adding document: \(err)")
            } else {
                annotation.lastUpdated = Date()
                print("Document added.")
            }
        }
    }

    func geoPoint(from coordinate: CLLocationCoordinate2D) -> GeoPoint {
        return GeoPoint(latitude: coordinate.latitude, longitude: coordinate.longitude)
    }
}

