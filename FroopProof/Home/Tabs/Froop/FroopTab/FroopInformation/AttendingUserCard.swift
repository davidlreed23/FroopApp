//
//  AttendingUserCard.swift
//  FroopProof
//
//  Created by David Reed on 5/12/23.
//

import SwiftUI
import Kingfisher
import MapKit



struct AttendingUserCard: View {
    
    @ObservedObject var appStateManager = AppStateManager.shared
    @ObservedObject var printControl = PrintControl.shared
    @ObservedObject var locationServices = LocationServices.shared
    @ObservedObject var froopDataListener = FroopDataListener.shared
 
    
    @State var guestFirstName: String = ""
    @State var guestLastName: String = ""
    @State var guestURL: String = ""
    @State var guestLocation: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 0.0, longitude: 0.0)
    @State var froopLocation: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 0.0, longitude: 0.0)
    @State var distance: Double = 0.0
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .frame(height: 75)
                .padding(.leading, 20)
                .padding(.trailing, 20)
                .foregroundColor(.white)
                .opacity(0.8)
                .onAppear {
                    LocationManager.shared.calculateTravelTime(from: guestLocation,
                                                        to: froopLocation) { travelTime in
                        if let travelTime = travelTime {
                            // convert travel time to minutes
                            let travelTimeMinutes = Double(travelTime / 60)
                            distance = travelTimeMinutes
                        }
                    }
                }
            
            HStack {
                ZStack {
                    Circle()
                        .frame(width: 65, height: 65)
                    KFImage(URL(string: guestURL))
                        .resizable()
                        .scaledToFit()
                        .frame(width: 65, height: 65)
                        .clipShape(Circle())
                        .padding(.top, 3)
                        .padding(.bottom, 3)
                        .padding(.leading, 3)
                       
                }
                .padding(.leading, 20)
                .padding(.trailing, 15)
                
                VStack (alignment: .leading) {
                    Text("\(guestFirstName) \(guestLastName)")
                        .font(.system(size: 18))
                        .fontWeight(.medium)
                        .foregroundColor(.black)
                        .multilineTextAlignment(.leading)
                    Text("Arriving in \(String(format: "%.0f", distance)) minutes")
                        .font(.system(size: 14))
                        .fontWeight(.regular)
                        .foregroundColor(.black)
                        .multilineTextAlignment(.leading)
                        
                }
                .offset(x: -10)
                Spacer()
                ZStack {
                    Rectangle()
                        .frame(width: 50, height: 50)
                        .foregroundColor(.black)
                        .opacity(0.5)
                        
                    Image(systemName: "car.rear.road.lane.dashed")
                        .foregroundColor(.white)
                        .font(.system(size: 24))
                        .fontWeight(.semibold)
                        .clipShape(RoundedRectangle(cornerRadius: 5))
                }
                .padding(.trailing, 30)
                .background(Color.clear)
            }
            .background(Color.clear)
        }
        .background(Color.clear)
     
    }
}

