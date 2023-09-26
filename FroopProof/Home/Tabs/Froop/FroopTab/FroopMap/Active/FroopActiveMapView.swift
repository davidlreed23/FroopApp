//
//  FroopActiveMapView.swift
//  FroopProof
//
//  Created by David Reed on 5/5/23.
//


import Combine
import SwiftUI
import MapKit
import FirebaseFirestore
import Kingfisher
import CoreLocation
import SwiftUIBlurView


struct FroopActiveMapView: View {
    @ObservedObject var printControl = PrintControl.shared
    @ObservedObject var locationManager = LocationManager.shared
    @ObservedObject var appStateManager = AppStateManager.shared
    @ObservedObject var myData = MyData.shared
    @ObservedObject var pinArray = PinArray.shared

    @State private var cancellable: AnyCancellable?
    @State var myCoordinate: CLLocationCoordinate2D = CLLocationCoordinate2D()
    @State var guestCoordinate: CLLocationCoordinate2D = CLLocationCoordinate2D()
    @State var centerCoordinate: CLLocationCoordinate2D = CLLocationCoordinate2D() {
        didSet {
            ActiveMapViewModel.shared.centerMapOnLocation(coordinate: centerCoordinate, latMultiple: 2.0, lonMultiple: 2.0)
        }
    }
    @State var mapButtonHelp = false
    @State var mapState = MapViewState.locationSelected
    @State var froopLocation: CLLocationCoordinate2D
    @State private var currentIndex = 0
    @EnvironmentObject var locationViewModel: LocationSearchViewModel
    let uid = FirebaseServices.shared.uid
    
    
    var body: some View {
        
        ZStack {
            ActiveMapViewRepresentable()
                .ignoresSafeArea(.keyboard)
            ZStack {
                if appStateManager.isDarkStyle {
                    VStack {
                        HStack (spacing: 20 ) {
                            ZStack (alignment: .leading) {
                                Image(systemName: "phone.arrow.up.right.circle")
                                    .font(.system(size: 40))
                                    .fontWeight(.thin)
                                    .foregroundColor(.white)
                                Text("Call")
                                    .font(.system(size: 14))
                                    .fontWeight(.thin)
                                    .foregroundColor(.white)
                                    .offset(x: 50)
                                    .offset(y: 15)
                            }
                            .frame(width: 100
                            )
                            ZStack (alignment: .leading) {
                                Image(systemName: "message.circle")
                                    .font(.system(size: 40))
                                    .fontWeight(.thin)
                                    .foregroundColor(.white)
                                Text("iMessage")
                                    .font(.system(size: 14))
                                    .fontWeight(.thin)
                                    .foregroundColor(.white)
                                    .offset(x: 50)
                                    .offset(y: 15)
                            }
                            Spacer()
                        }
                        .padding(.leading, 85)
                        .padding(.top, 40)
                        Spacer()
                    }
                } else {
                    EmptyView()
                }
                
                if appStateManager.isDarkStyle {
                    EmptyView()
                } else {
                    VStack {
                        HStack (alignment: .top, spacing: 0) {
                            
                            //MARK:  MapView Annotation Navigation
                            VStack (alignment: .center, spacing: 15) {
                                
                                Image(appStateManager.isDarkStyle ? "" : "pinkLogo")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(minHeight: 30, maxHeight:30)
                                    .onTapGesture {
                                        print("Sending coordinate \(appStateManager.inProgressFroop.froopLocationCoordinate ?? CLLocationCoordinate2D())")
                                        centerCoordinate = appStateManager.inProgressFroop.froopLocationCoordinate ?? CLLocationCoordinate2D()
                                    }
                                    .padding(.top, 10)
                                
                                Image(systemName:"location.north.circle.fill")
                                    .font(.system(size: 30))
                                    .fontWeight(.light)
                                    .foregroundColor(appStateManager.isDarkStyle ? .clear : Color(red: 249/255, green: 0/255, blue: 98/255 ))
                                    .clipShape(RoundedRectangle(cornerRadius: 10)) // Adjust cornerRadius as needed
                                    .onTapGesture {
                                        print("Sending coordinate \(myData.coordinate)")
                                        centerCoordinate = myData.coordinate
                                    }
                                
                                Image(systemName: "person.crop.circle.dashed")
                                    .font(.system(size: 30))
                                    .fontWeight(.light)
                                    .foregroundColor(appStateManager.isDarkStyle ? .clear : Color(red: 249/255, green: 0/255, blue: 98/255 ))
                                    .onTapGesture {
                                        print("Sending coordinate \(appStateManager.activeInvitedFriends[0].coordinate)")
                                        centerCoordinate = appStateManager.activeInvitedFriends[0].coordinate
                                        
                                    }
                                
                                Image(systemName: "person.fill.and.arrow.left.and.arrow.right")
                                    .font(.system(size: 30))
                                    .fontWeight(.light)
                                    .foregroundColor(appStateManager.isDarkStyle ? .clear : Color(red: 249/255, green: 0/255, blue: 98/255 ))
                                    .onTapGesture {
                                        // Move to the next user
                                        let user = appStateManager.activeInvitedFriends[currentIndex]
                                        
                                        // Cancel the previous subscription if it exists
                                        cancellable?.cancel()
                                        
                                        // Create a new subscription for the user's coordinate
                                        cancellable = user.$coordinate.sink { newCoordinate in
                                            centerCoordinate = newCoordinate
                                        }
                                        
                                        currentIndex += 1
                                        if currentIndex >= appStateManager.activeInvitedFriends.count {
                                            currentIndex = 0 // reset to the beginning of the array when reaching the end
                                        }
                                    }
                                
                                
                                Image(systemName: "questionmark.circle")
                                    .font(.system(size: 30))
                                    .fontWeight(.light)
                                    .foregroundColor(mapButtonHelp == false ? appStateManager.isDarkStyle ? .clear : Color(.gray) : Color(.blue))
                                    .onTapGesture {
                                        mapButtonHelp.toggle()
                                        print("Button Help: \(mapButtonHelp)")
                                        if let firstAnnotation = ActiveMapViewModel.shared.froopAnnotations.first {
                                            print("Coordinate: \(firstAnnotation.coordinate)")
                                            print("Title: \(firstAnnotation.title ?? "")")
                                            print("Subtitle: \(firstAnnotation.subtitle ?? "")")
                                            print("Message: \(firstAnnotation.messageBody ?? "")")
                                            print("Color: \(firstAnnotation.color?.description ?? "No Color")")
                                        } else {
                                            print("No Annotations")
                                        }
                                    }
                                    .padding(.bottom, 10)
                            }
                            .frame(minWidth: 45, maxWidth: 45, minHeight: 250, maxHeight: 250)
                            .background(appStateManager.isDarkStyle ? .clear : Color(.white).opacity(0.6))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            
                            
                            //MARK: MapView Annotaition Help Descriptions
                            VStack (alignment: .leading, spacing: 17) {
                                
                                Text("Center On Froop Location")
                                    .background(.ultraThinMaterial)
                                    .foregroundColor(.black)
                                    .font(.system(size: 14))
                                    .fontWeight(.medium)
                                    .padding(.leading, 5)
                                    .frame(minHeight: 30, maxHeight:30)
                                
                                
                                Text("Center On Me")
                                    .background(.ultraThinMaterial)
                                    .foregroundColor(.black)
                                    .font(.system(size: 14))
                                    .fontWeight(.medium)
                                    .padding(.leading, 5)
                                    .frame(minHeight: 30, maxHeight:30)
                                
                                
                                Text("Center On Host")
                                    .background(.ultraThinMaterial)
                                    .foregroundColor(.black)
                                    .font(.system(size: 14))
                                    .fontWeight(.medium)
                                    .padding(.leading, 5)
                                    .frame(minHeight: 30, maxHeight:30)
                                    .offset(y: 3)
                                
                                
                                Text("Cycle Through Guests")
                                    .background(.ultraThinMaterial)
                                    .foregroundColor(.black)
                                    .font(.system(size: 14))
                                    .fontWeight(.medium)
                                    .padding(.leading, 5)
                                    .frame(minHeight: 30, maxHeight:30)
                                    .offset(y: 6)
                                
                                
                                Text("Help")
                                    .background(.ultraThinMaterial)
                                    .foregroundColor(.black)
                                    .font(.system(size: 14))
                                    .fontWeight(.medium)
                                    .padding(.leading, 5)
                                    .frame(minHeight: 30, maxHeight:30)
                                    .offset(y: 6)
                                
                            }
                            .padding(.top, 20)
                            .offset(y: -10)
                            .frame(minWidth: 200, maxWidth: 200)
                            .opacity(mapButtonHelp == false ? 0.0 : 1.0)
                            .animation(.easeInOut(duration: 0.3), value: mapButtonHelp)
                            
                            Spacer()
                            
                            //MARK: Annotation View Close Button
                      
                        }
                        .padding(.top, 20)
                        .padding(.trailing, 15)
                        .padding(.leading, 15)
                        Spacer()
                    }
                    .onReceive(NotificationCenter.default.publisher(for: .init("TextButtonTapped")), perform: { _ in
                        self.appStateManager.isMessageViewPresented = true
                    })
                }
                HStack {
                    Spacer()
                    VStack (alignment: .trailing, spacing: 15) {
                        
                        if appStateManager.isDarkStyle {
                            
                            Button (action: {
                                print(appStateManager.isDarkStyle)
                                if let selectedAnnotation = ActiveMapViewModel.shared.mapView.selectedAnnotations.first {
                                    ActiveMapViewModel.shared.mapView.deselectAnnotation(selectedAnnotation, animated: true)
                                    appStateManager.isDarkStyle = false
                                    self.appStateManager.isFroopTabUp = true
                                    self.appStateManager.showChatView = false
                                    self.appStateManager.chatWith = UserData()
                                }
                                UIApplication.shared.endEditing(true) // Close keyboard
                            }) {
                                VStack (spacing: 0) {
                                    Image(systemName: "xmark.circle")
                                        .font(.system(size: 24))
                                        .fontWeight(.thin)
                                        .foregroundColor(.white)
                                        .padding(.bottom, 1)
                                    Text("close")
                                        .font(.system(size: 12))
                                        .fontWeight(.thin)
                                        .foregroundColor(.white)
                                }
                            }
                            .padding(.trailing, 15)
                            .padding(.top, 15)
                           
                        } else {
                            
                            Button(action: {
                                let latitude: Double = appStateManager.inProgressFroop.froopLocationCoordinate?.latitude ?? 0.0
                                let longitude: Double = appStateManager.inProgressFroop.froopLocationCoordinate?.longitude ?? 0.0
                                
                                // Check if Waze is installed
                                if UIApplication.shared.canOpenURL(URL(string: "waze://")!) {
                                    // Waze is installed. Launch Waze and start navigation
                                    let urlStr = String(format: "waze://?ll=%f,%f&navigate=yes", latitude, longitude)
                                    UIApplication.shared.open(URL(string: urlStr)!)
                                } else {
                                    // Waze is not installed. Launch AppStore to install Waze app
                                    UIApplication.shared.open(URL(string: "http://itunes.apple.com/us/app/id323229106")!)
                                }
                            }) {
                                Image("wazeLogo")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(minWidth: 60, maxWidth:60)
                                    .padding(.bottom, 15)
                            }
                            .padding(.trailing, 15)
                            .padding(.top, 15)
                        }
                        
                        Spacer()
                    }
                   
                }
                
                ChatView()
                    .opacity(appStateManager.showChatView ? 1.0 : 0.0)
                    //.keyboardAdaptive()
                    .animation(.easeInOut(duration: 0.5), value: appStateManager.showChatView)

                
                .sheet(isPresented: $appStateManager.isMessageViewPresented, content: {
                    GenericMessageView(isPresented: self.$appStateManager.isMessageViewPresented, phoneNumber: appStateManager.guestPhoneNumber)
                })
                VStack {
                    Spacer()
                    if appStateManager.isAnnotationMade, let annotation = ActiveMapViewModel.shared.annotationModel.annotation {
                        SaveAnnotationView(annotation: annotation)
                            .transition(.move(edge: .bottom))
                    }
                }
                .onChange(of: ActiveMapViewModel.shared.annotationModel.annotation, initial: (ActiveMapViewModel.shared.annotationModel.annotation != nil)) { oldValue, newValue in
                    withAnimation {
                        appStateManager.isAnnotationMade = newValue != nil
                    }
                }

                .animation(.default, value: appStateManager.isAnnotationMade)
            }
        }
    }
}


