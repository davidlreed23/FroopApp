//
//  FroopMapViewRepresentable.swift
//  FroopProof
//
//  Created by David Reed on 1/19/23.
//


import SwiftUI
import MapKit
import CoreLocation
import Combine
import Kingfisher
import FirebaseFirestore
import FirebaseFirestoreSwift




struct ActiveMapViewRepresentable: UIViewRepresentable {
    @Environment(\.colorScheme) var colorScheme
    @StateObject var viewModel = ActiveMapViewModel.shared
    @ObservedObject var appStateManager = AppStateManager.shared
    
    func makeUIView(context: Context) -> MKMapView {

        let longPress = UILongPressGestureRecognizer(target: context.coordinator, action: #selector(context.coordinator.addAnnotationOnLongPress(gesture:)))
        longPress.minimumPressDuration = 0.3
        
        viewModel.mapView.addGestureRecognizer(longPress)
        viewModel.mapView.delegate = context.coordinator
        viewModel.mapView.isRotateEnabled = false
        viewModel.mapView.showsUserLocation = false
        viewModel.mapView.userTrackingMode = .none

        let froopLocation = viewModel.froopLocation
        let region = MKCoordinateRegion(center: froopLocation, span: MKCoordinateSpan(latitudeDelta: viewModel.regLat, longitudeDelta: viewModel.regLon))
        viewModel.mapView.setRegion(region, animated: false)

        return viewModel.mapView
    }
    
    func updateUIView(_ uiView: MKMapView, context: UIViewRepresentableContext<ActiveMapViewRepresentable>) {
        if !viewModel.isMapViewInitialized {
            let froopLocation = viewModel.froopLocation
            let region = MKCoordinateRegion(center: froopLocation, span: MKCoordinateSpan(latitudeDelta: viewModel.regLat, longitudeDelta: viewModel.regLon))
            uiView.setRegion(region, animated: false)
        }
        
        // Remove any annotations from the map view that aren't in the viewModel.annotations array
        for annotation in uiView.annotations {
            if !viewModel.annotations.contains(where: { $0.coordinate.latitude == annotation.coordinate.latitude && $0.coordinate.longitude == annotation.coordinate.longitude }) {
                uiView.removeAnnotation(annotation)
            }
        }
        
        // Add any annotations from the viewModel.annotations array that aren't in the map view
        for annotation in viewModel.annotations {
            if !uiView.annotations.contains(where: { $0.coordinate.latitude == annotation.coordinate.latitude && $0.coordinate.longitude == annotation.coordinate.longitude }) {
                uiView.addAnnotation(annotation)
            }
        }
        
        if let polyline = viewModel.polyline {
            uiView.removeOverlays(uiView.overlays)
            uiView.addOverlay(polyline)
        }
        
        // Handle map state changes
        switch viewModel.mapState {
            case .noInput:
                PrintControl.shared.printMap("noInput")
            case .searchingForLocation: break
                // Handle searching for location state
            case .locationSelected:
                viewModel.configurePolyline(forGuests: appStateManager.activeInvitedFriends)
                
                // Handle location selected state
            default:
                break
        }
    }
    
    func makeCoordinator() -> ActiveMapViewModel.ActiveMapCoordinator {
        let defaultImageUrl = "https://firebasestorage.googleapis.com/v0/b/froop-proof.appspot.com/o/ProfilePic%2FJDgZUEkawWa2UbQib5PI63AM4bA2.jpg?alt=media&token=1387264e-efbc-447a-9a4c-ea6c6f036be9"
        let annotationImageUrl = defaultImageUrl
        return ActiveMapViewModel.ActiveMapCoordinator(viewModel: viewModel, annotationImageUrl: annotationImageUrl, mapView: MKMapView())
    }
    
    
}


class ActiveMapViewModel: ObservableObject {
    
    static let shared = ActiveMapViewModel(froopLocation: CLLocationCoordinate2D())
    
    @EnvironmentObject var locationSearchViewModel: LocationSearchViewModel
    @EnvironmentObject var homeViewModel: HomeViewModel
    
    @ObservedObject var appStateManager = AppStateManager.shared
    @ObservedObject var printControl = PrintControl.shared
    @ObservedObject var locationServices = LocationServices.shared
    @ObservedObject var froopDataListener = FroopDataListener.shared
    @ObservedObject var locationManager = LocationManager.shared
    @ObservedObject var froopManager = FroopManager.shared
    @ObservedObject var myData = MyData.shared
    @ObservedObject var pinArray = PinArray.shared
    let db = FirebaseServices.shared.db
    
    var visualEffectView: UIVisualEffectView?
    
    let annotationModel = AnnotationModel()
    
    @Published var froopAnnotations = [FroopDropPin]()
    
    @Published var isMapViewInitialized = false
    @Published var centerCoordinate: CLLocationCoordinate2D?
    @Published var froopLocation: CLLocationCoordinate2D
    @Published var mapState: MapViewState = .locationSelected
    @Published var annotations: [MKAnnotation] = []
    @Published var polyline: MKPolyline?
    @Published var currentRegion: MKCoordinateRegion?
    @Published var regLon: Double = 0.01
    @Published var regLat: Double = 0.01
    @Published var annotationImage: String = ""
    @Published var overlay: MKOverlay?
    @Published var selectedAnnotation: FroopDropPin?
    @State private var showChatView = false
    
    private var cancellables = Set<AnyCancellable>()
    
    let mapView: MKMapView
    
    var guestAnnotations: [String: MovableAnnotation] = [:]
    
    init(froopLocation: CLLocationCoordinate2D) {
         self.mapView = MKMapView() // Initialize mapView
         self.froopLocation = AppStateManager.shared.inProgressFroop.froopLocationCoordinate ?? CLLocationCoordinate2D()
         isMapViewInitialized = true
         // Call updateMapView after setting froopLocation
         self.updateMapView()
         
         let froopLocationAnnotation = MKPointAnnotation()
         froopLocationAnnotation.coordinate = self.froopLocation
         froopLocationAnnotation.title = "Froop Location"
         self.mapView.addAnnotation(froopLocationAnnotation)
         
         appStateManager.onUpdateMapView = { [weak self] in
             self?.updateMapView()
         }
         pinArray.$froopDropPins
             .sink { [weak self] newPins in
                 guard let self = self else { return }
                 // Remove all current FroopDropPin annotations
                 let froopAnnotations = self.mapView.annotations.compactMap { $0 as? FroopDropPin }
                 self.mapView.removeAnnotations(froopAnnotations)
                 
                 // Add new annotations
                 self.mapView.addAnnotations(newPins)
                 self.annotations.append(contentsOf: newPins)
             }
             .store(in: &cancellables)
         // Listen for changes to the activeInvitedFriends array
         appStateManager.$activeInvitedFriends
             .sink { [weak self] (guests: [UserData]) in
                 guard let self = self else { return }
                 
                 // Add a new annotation for each guest
                 for guest in guests {
                     // If an annotation for this guest already exists, just update its coordinate
                     if let existingAnnotation = self.guestAnnotations[guest.froopUserID] as? GuestAnnotation {
                         // This will animate the movement of the annotation to the new location
                         self.moveAnnotation(existingAnnotation, to: guest.coordinate, duration: 1.0)
                     } else { // If an annotation for this guest doesn't exist, create a new one
                         let annotation = GuestAnnotation(guest: guest)
                         self.mapView.addAnnotation(annotation)
                         self.annotations.append(annotation)
                         self.guestAnnotations[guest.froopUserID] = annotation
                         
                         // Listen for changes to the guest's location
                         guest.$coordinate
                             .sink { [weak self] newCoordinate in
                                 guard let self = self else { return }
                                 if let annotation = self.guestAnnotations[guest.froopUserID] as? GuestAnnotation {
                                     self.moveAnnotation(annotation, to: newCoordinate, duration: 1.0)
                                 }
                             }
                             .store(in: &self.cancellables)
                     }
                 }
                 self.configurePolyline(forGuests: guests)
             }
             .store(in: &cancellables)
         loadAnnotations()
     }
    
    func loadAnnotations() {
        guard appStateManager.appState != .passive else {
                print("Application is in passive mode, skipping loadAnnotations")
                return
            }
        print("loadAnnotations Function Firing!")
        // Setup the listener
        let froopHost = appStateManager.inProgressFroop.froopHost
        print("froopHost: \(froopHost)")
        let froopId = appStateManager.inProgressFroop.froopId
        print("froopId: \(froopId)")
        let annotationsCollection = db.collection("users").document(froopHost).collection("myFroops").document(froopId).collection("annotations")
        print("annotationsCollection: \(String(describing: annotationsCollection))")
        
        annotationsCollection.getDocuments() { [weak self] (querySnapshot, err) in
            guard let self = self else { return }
            
            if let err = err {
                print("Error getting documents: \(err)")
            } else {
                for document in querySnapshot!.documents {
                    print("\(document.documentID) => \(document.data())")
                    
                    let data = document.data()
                    
                    // This assumes your annotation documents have field named "coordinate"
                    if let coordinateData = data["coordinate"] as? GeoPoint {
                        // Convert the GeoPoint to CLLocationCoordinate2D
                        let coordinate = FirebaseServices.shared.convertToCoordinate(geoPoint: coordinateData)
                        
                        let title = data["title"] as? String
                        let subtitle = data["subtitle"] as? String
                        let messageBody = data["messageBody"] as? String
                        let colorString = data["color"] as? String
                        let creatorUID = data["creatorUID"] as? String
                        let profileImageUrl = data["profileImageUrl"] as? String
                        
                        // Try to convert color string to UIColor, default to white if conversion fails
                        let color = UIColor(hexString: colorString ?? "") ?? UIColor.white
                        
                        // Check if an annotation with the same coordinate already exists
                        if !self.annotations.contains(where: { $0.coordinate.latitude == coordinate.latitude && $0.coordinate.longitude == coordinate.longitude }) {
                            let newPin = FroopDropPin(coordinate: coordinate, title: title, subtitle: subtitle, messageBody: messageBody, color: color, creatorUID: creatorUID, profileImageUrl: profileImageUrl)
                            
                            // Add the annotation to the array
                            self.annotations.append(newPin)
                            
                            // Add the annotation to the map
                            self.mapView.addAnnotation(newPin)
                            self.adjustMapViewToFitAnnotations()
                        }
                    }
                }
            }
        }
    }
    
    func adjustMapViewToFitAnnotations() {
        print("ADJUSTING MAP TO FIT ANNOTATIONS")
        guard let boundingRect = boundingMapRectForAnnotations() else { return }
        
        let fittingRect = mapView.mapRectThatFits(boundingRect, edgePadding: UIEdgeInsets(top: 150, left: 32, bottom: 150, right: 32))
        mapView.setVisibleMapRect(fittingRect, animated: true)
    }
    
    func boundingMapRectForAnnotations() -> MKMapRect? {
        var rect: MKMapRect?
        
        for annotation in mapView.annotations {
            let annotationPoint = MKMapPoint(annotation.coordinate)
            let pointRect = MKMapRect(x: annotationPoint.x, y: annotationPoint.y, width: 0.1, height: 0.1) // Slight size to the point
            
            if let currentRect = rect {
                rect = currentRect.union(pointRect)
            } else {
                rect = pointRect
            }
        }
        
        return rect
    }
    
    func moveAnnotation(_ annotation: GuestAnnotation, to coordinate: CLLocationCoordinate2D, duration: TimeInterval) {
        UIView.animate(withDuration: duration) {
            annotation.coordinate = coordinate
        }
    }
    
    func updateGuestLocation(_ guest: UserData, withCoordinate newCoordinate: CLLocationCoordinate2D) {
        // Check if the annotation for this guest exists in the dictionary
        if let annotation = self.guestAnnotations[guest.froopUserID] {
            // If it does, update its coordinate to the new one
            annotation.coordinate = newCoordinate
        }
    }
    
    func updateBlurEffect(for view: MKMapView, selected: Bool) {
        //        if selected {
        //            let blurEffect = UIBlurEffect(style: .light)
        //            self.visualEffectView = UIVisualEffectView(effect: blurEffect)
        //            self.visualEffectView?.frame = view.bounds
        //            self.visualEffectView?.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        //            view.addSubview(self.visualEffectView!)
        //        } else {
        self.visualEffectView?.removeFromSuperview()
        self.visualEffectView = nil
    }
    
    func centerMapOnLocation(coordinate: CLLocationCoordinate2D, latMultiple: Double, lonMultiple: Double) {
        print("center map function called")
        print("Coordinate Received: \(coordinate)")
        let regionRadius: CLLocationDistance = 1000
        let coordinateRegion = MKCoordinateRegion(center: coordinate,
                                                  latitudinalMeters: regionRadius * latMultiple,
                                                  longitudinalMeters: regionRadius * lonMultiple)
        mapView.setRegion(coordinateRegion, animated: true)
        DispatchQueue.main.async {
            self.currentRegion = coordinateRegion
            
        }
    }
    
    func updateMapView() {
        // Remove all existing annotations from the map view
        mapView.removeAnnotations(mapView.annotations)
        
        // Add annotation for the froop location
        let froopAnnotation = MKPointAnnotation()
        froopAnnotation.coordinate = froopLocation
        print("Froop Location: \(froopLocation)")
        froopAnnotation.title = appStateManager.inProgressFroop.froopName
        mapView.addAnnotation(froopAnnotation)
        mapView.selectAnnotation(froopAnnotation, animated: true)
        
        // Add froopAnnotation to annotations array
        annotations.append(froopAnnotation)
        
        // Add new annotations for each guest
        for guest in AppStateManager.shared.activeInvitedFriends {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                let annotation = MKPointAnnotation()
                annotation.coordinate = guest.coordinate
                annotation.title = "\(guest.firstName) \(guest.lastName)"
                self.mapView.addAnnotation(annotation)
            }
        }
    }
    
    func updatePolyline(for froop: Froop) {
        // Create a polyline that connects the froop location with the locations of its guests
        guard let froopLocation = appStateManager.inProgressFroop.froopLocationCoordinate else { return }
        
        var polylines: [MKPolyline] = []
        
        for guest in appStateManager.activeInvitedFriends {
            let polyline = makePolyline(from: froopLocation, to: guest.coordinate)
            polylines.append(polyline)
            
            
            self.polyline = polyline
            // Update customOverlayRenderer with the new polyline and the guest's profile picture
            
        }
        
        DispatchQueue.main.async {
            self.polyline = MKPolyline()
            // Update customOverlayRenderer with the new polyline
            
        }
    }
    
    func configurePolyline(forGuests guests: [UserData]) {
        PrintControl.shared.printMap("-FroopMapViewRepresentable: Function: configurePolyline is firing!")
        PrintControl.shared.printMap("DAVID - CONFIGURE POLY LINE STARTED")
        
        mapView.removeOverlays(mapView.overlays)
        
        if let froopLocation = appStateManager.inProgressFroop.froopLocationCoordinate {
            for guest in guests {
                let guestLocation = guest.coordinate
                
                let coordinates = [froopLocation, guestLocation]
                let polyline = MKPolyline(coordinates: coordinates, count: coordinates.count)
                
                mapView.addOverlay(polyline)
            }
        } else {
            // Handle the case where froopLocation is nil
            print("froopLocation is nil")
        }
        
        //self.mapState = .polylineAdded
    }
    
    private func makePolyline(from froopLocation: CLLocationCoordinate2D, to guestLocation: CLLocationCoordinate2D) -> MKPolyline {
        let coordinates = [froopLocation, guestLocation]
        return MKPolyline(coordinates: coordinates, count: coordinates.count)
    }
    
    func calculateDistance(to location: FroopData) -> Double {
        PrintControl.shared.printLocationServices("-ActiveMapViewRepresentable: Function: calculateDistance is firing!")
        guard let userLocation = locationManager.userLocation else { return 0 }
        let froopData = CLLocation(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
        return userLocation.distance(from: froopData)
    }
    
    class ActiveMapCoordinator: NSObject, MKMapViewDelegate {
        @ObservedObject var viewModel = ActiveMapViewModel.shared
        @ObservedObject var appStateManager = AppStateManager.shared
        @ObservedObject var notificationsManager = NotificationsManager.shared
        let uid = FirebaseServices.shared.uid
        var selectedAnnotationView: MKAnnotationView?
        
        var parentView: UIView?
        var duplicatedImageView: UIImageView?
        var backgroundView: UIView?
        var backgroundView2: UIView?
        var duplicatedAnnotation: MKAnnotationView?
        var callAnnotation: MKAnnotationView?
        var textAnnotation: MKAnnotationView?
        
        var visualEffectView: UIVisualEffectView?
        
        var userLocationCoordinate: CLLocationCoordinate2D?
        
        private var isDarkStyleCancellable: AnyCancellable?

        
        init(viewModel: ActiveMapViewModel, annotationImageUrl: String, mapView: MKMapView) {
            self.viewModel = viewModel
            super.init()
            
            // Subscribe to changes in isDarkStyle
            isDarkStyleCancellable = AppStateManager.shared.$isDarkStyle.sink { [weak self] newValue in
                guard let self = self else { return }
                if !newValue {
                    UIView.animate(withDuration: 0.5, animations: {
                        self.visualEffectView?.alpha = 0.0
                        self.parentView?.alpha = 0.0
                        self.backgroundView?.alpha = 0.0
                        self.backgroundView2?.alpha = 0.0
                    }, completion: { _ in
                        self.visualEffectView?.removeFromSuperview()
                        self.parentView?.removeFromSuperview()
                        self.backgroundView?.removeFromSuperview()
                        self.backgroundView2?.removeFromSuperview()
                    })
                }
            }
            
            // Add a tap gesture recognizer to the map view
            let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleMapTap(_:)))
            viewModel.mapView.addGestureRecognizer(tapGestureRecognizer)
        }
        
        @objc func addAnnotationOnLongPress(gesture: UILongPressGestureRecognizer) {
            if gesture.state == .began {
                print("Gesture state is .began")

                let point = gesture.location(in: viewModel.mapView)
                let coordinate = viewModel.mapView.convert(point, toCoordinateFrom: viewModel.mapView)
                print("Coordinate: \(coordinate.latitude), \(coordinate.longitude)")

                // Fetch or define the creatorUID and profileImageUrl values
                let creatorUID = FirebaseServices.shared.uid
                let profileImageUrl = MyData.shared.profileImageUrl
                
                let annotation = FroopDropPin(coordinate: coordinate, title: "Title Here.", subtitle: "SubTitle Here", messageBody: "Message Here", color: UIColor.purple, creatorUID: creatorUID, profileImageUrl: profileImageUrl)
                
                viewModel.mapView.addAnnotation(annotation)
                appStateManager.isAnnotationMade = true
                appStateManager.isFroopTabUp = false
                viewModel.annotationModel.annotation = annotation
                
                viewModel.annotations.append(annotation) // Add the new annotation to viewModel.annotations
            }
        }
        
        
        @objc func handleMapTap(_ gesture: UITapGestureRecognizer) {
            // Get the point that was tapped
            let point = gesture.location(in: viewModel.mapView)
            
            // Convert that point to a coordinate
            let coordinate = viewModel.mapView.convert(point, toCoordinateFrom: viewModel.mapView)
            
            // Define the map rect to search within
            let mapPoint = MKMapPoint(coordinate)
            let searchRect = MKMapRect(x: mapPoint.x, y: mapPoint.y, width: 1, height: 1)
            
            // Filter the map's annotations to find those within the search rect
            let tappedAnnotations = viewModel.mapView.annotations.filter { annotation in
                searchRect.contains(MKMapPoint(annotation.coordinate))
            }
            
            // If no annotations were tapped
            if tappedAnnotations.isEmpty {
                // Deselect all currently selected annotations
                for annotation in viewModel.mapView.selectedAnnotations {
                    viewModel.mapView.deselectAnnotation(annotation, animated: true)
                }
            }
        }
        
        func configurePolyline(forGuests guests: [UserData])  {
            PrintControl.shared.printMap("-FroopMapViewRepresentable: Function: configurePolyline is firing!")
            PrintControl.shared.printMap("DAVID - CONFIGURE POLY LINE STARTED")
            
            viewModel.mapView.removeOverlays(viewModel.mapView.overlays)
            
            if let froopLocation = appStateManager.inProgressFroop.froopLocationCoordinate {
                for guest in guests {
                    let guestLocation = guest.coordinate
                    
                    let coordinates = [froopLocation, guestLocation]
                    let polyline = MKPolyline(coordinates: coordinates, count: coordinates.count)
                    
                    viewModel.mapView.addOverlay(polyline)
                }
            } else {
                // Handle the case where froopLocation is nil
                print("froopLocation is nil")
            }
            
            //self.mapState = .polylineAdded
        }
        
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            if let froopDropPin = annotation as? FroopDropPin {
                let identifier = "FroopDropPin"
                
                // Reuse or create an MKPinAnnotationView
                var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView
                if annotationView == nil {
                    annotationView = MKMarkerAnnotationView(annotation: froopDropPin, reuseIdentifier: identifier)
                    annotationView?.canShowCallout = true
                } else {
                    annotationView?.annotation = froopDropPin
                }
                
                // Set the pin color
                annotationView?.markerTintColor = froopDropPin.color
                
                return annotationView
            }
            
            if let annotation = annotation as? GuestAnnotation {
                let identifier = "GuestAnnotation"
                var view: MKAnnotationView
                if let dequeuedView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) {
                    dequeuedView.annotation = annotation
                    view = dequeuedView
                } else {
                    view = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                    view.canShowCallout = false
                }
                
                // Download the image from the URL and set it as the annotation view's image
                if let url = URL(string: annotation.guest.profileImageUrl) {
                    let processor = DownsamplingImageProcessor(size: CGSize(width: 50, height: 50))
                    |> RoundCornerImageProcessor(cornerRadius: 20)
                    KingfisherManager.shared.retrieveImage(with: url, options: [
                        .processor(processor),
                        .scaleFactor(UIScreen.main.scale),
                        .transition(.fade(1)),
                        .cacheOriginalImage
                    ]) { result in
                        switch result {
                            case .success(let value):
                                view.image = value.image
                            case .failure(let error):
                                print("Error: \(error)") // Handle the error
                        }
                    }
                }
                
                return view
                
            }
            return nil
        }
        

        
        func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
            
        }
        
        func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
            if let annotation = view.annotation as? MovableAnnotation {
                if control == view.rightCalloutAccessoryView {
                    // Handle the detail disclosure button being tapped
                    let alert = UIAlertController(title: "Edit Annotation", message: nil, preferredStyle: .alert)
                    alert.addTextField { textField in
                        textField.text = annotation.title
                    }
                    alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                        if let newTitle = alert.textFields?.first?.text {
                            annotation.title = newTitle
                        }
                    })
                    alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
                    
                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                        windowScene.windows.first?.rootViewController?.present(alert, animated: true)
                    }
                } else if control == view.leftCalloutAccessoryView {
                    // Handle the delete button being tapped
                    mapView.removeAnnotation(annotation as! MKAnnotation)
                }
            }
        }
        
        func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
            
            if LocationServices.shared.trackActiveUserLocation == false {
                return
            }
            let newCoordinate = userLocation.coordinate
            guard let previousCoordinate = self.userLocationCoordinate else {
                // This is the first location update, so we don't have a previous location to compare with
                self.userLocationCoordinate = newCoordinate
                return
            }
            
            let distance = sqrt(pow(newCoordinate.latitude - previousCoordinate.latitude, 2) + pow(newCoordinate.longitude - previousCoordinate.longitude, 2))
            if distance < 0.00001 { // Adjust this threshold as needed
                                    // The location hasn't changed significantly, so we ignore this update
                return
            }
            
            // The location has changed significantly, so we process this update
            self.userLocationCoordinate = newCoordinate
            
            PrintControl.shared.printLocationServices("Previous Location: \(String(describing: previousCoordinate.latitude)), \(String(describing: previousCoordinate.longitude))")
            print("New Location: \(newCoordinate.latitude), \(newCoordinate.longitude)")
            
            let region = MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: newCoordinate.latitude, longitude: newCoordinate.longitude),
                span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
            )
            
            PrintControl.shared.printLocationServices("updating userLocation TOMMY")
            PrintControl.shared.printLocationServices((String(describing: appStateManager.appState)))
            self.viewModel.currentRegion = region
            
            viewModel.mapView.setRegion(region, animated: false)
        }
        
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            PrintControl.shared.printLocationServices("-ActiveMapViewRepresentable: Function: mapView2 is firing!")
            let polyline = MKPolylineRenderer(overlay: overlay)
            polyline.strokeColor = (UIColor(red: 249/255, green: 0/255, blue: 98/255, alpha: 0.75))
            polyline.lineWidth = 1
            return polyline
        }
        
        @objc func handleAnnotationTap(_ sender: UITapGestureRecognizer) {
            guard let view = sender.view else { return }
            
            // Animate the removal of the parent view and blur effect
            UIView.animate(withDuration: 0.5, animations: {
                view.alpha = 0.0 // Fade out the parent view
                self.visualEffectView?.alpha = 0.0 // Fade out the blur effect
            }, completion: { _ in
                // Remove the parent view and blur effect from the superview
                view.removeFromSuperview()
                self.visualEffectView?.removeFromSuperview()
                self.visualEffectView = nil
            })
        }
        
        @objc func handleBlurTap(_ sender: UITapGestureRecognizer) {
            if let selectedAnnotation = viewModel.mapView.selectedAnnotations.first {
                viewModel.mapView.deselectAnnotation(selectedAnnotation, animated: true)
                appStateManager.isDarkStyle = false
                appStateManager.isFroopTabUp = true
                appStateManager.showChatView = false
                appStateManager.chatWith = UserData()
                
            }
            
            UIView.animate(withDuration: 0.5, animations: {
                self.visualEffectView?.alpha = 0.0
                self.parentView?.alpha = 0.0
            }, completion: { _ in
                self.visualEffectView?.removeFromSuperview()
                self.parentView?.removeFromSuperview()
            })
        }
        
        
        func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
            selectedAnnotationView = view

            if view.annotation is FroopDropPin {
                appStateManager.isAnnotationMade = true
                appStateManager.isFroopTabUp = false
                appStateManager.isDarkStyle = false
                ActiveMapViewModel.shared.annotationModel.annotation = view.annotation as? FroopDropPin
            }
            
            if let annotation = view.annotation as? GuestAnnotation {
                appStateManager.isDarkStyle = true
                appStateManager.isFroopTabUp = false
                appStateManager.showChatView = true
                appStateManager.chatWith = annotation.guest

                // search for matching conversation in notificationsManager's messages
                let matchingConversations = notificationsManager.conversationsAndMessages.filter {
                    ($0.conversation.userId == uid && $0.conversation.guestId == annotation.guest.froopUserID) ||
                    ($0.conversation.userId == annotation.guest.froopUserID && $0.conversation.guestId == uid)
                }

                if let firstMatchingConversation = matchingConversations.first {
                    // if found, assign the id of the first matching conversation
                    appStateManager.chatViewId = firstMatchingConversation.conversation.id
                    print("didSelect assignment of chatViewId: \(String(describing: appStateManager.chatViewId))")
                    notificationsManager.conversationExists = true
                } else {
                    // handle case where no matching conversation was found
                    print("No matching conversation found for guest with id: \(annotation.guest.froopUserID)")
                }
                
                // Prepare blur effect
                let blurEffect = UIBlurEffect(style: appStateManager.isDarkStyle ? .dark : .light)
                self.visualEffectView = UIVisualEffectView(effect: blurEffect)
                self.visualEffectView?.frame = mapView.bounds
                self.visualEffectView?.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                self.visualEffectView?.alpha = 0.0 // Start transparent
                mapView.addSubview(self.visualEffectView!)
                //let tapBlurGesture = UITapGestureRecognizer(target: self, action: #selector(handleBlurTap(_:)))
                //self.visualEffectView?.addGestureRecognizer(tapBlurGesture)
                
                // Create a background view
                backgroundView = UIView(frame: CGRect(x: 0, y: 0, width: mapView.bounds.width, height: 100))
                backgroundView?.backgroundColor = UIColor.black.withAlphaComponent(0.7) // Semi-transparent black
                backgroundView?.center.x = mapView.bounds.midX
                backgroundView?.center.y = backgroundView?.bounds.midY ?? 0 // center it vertically
                mapView.addSubview(backgroundView!)

                backgroundView2 = UIView(frame: CGRect(x: 0, y: 0, width: mapView.bounds.width, height: 113))
                backgroundView2?.backgroundColor = UIColor.black.withAlphaComponent(0.7) // Semi-transparent black
                backgroundView2?.center.x = mapView.bounds.midX
                backgroundView2?.center.y = mapView.bounds.height - (backgroundView2?.bounds.midY ?? 0) // place it at the bottom
                mapView.addSubview(backgroundView2!)
                
              
                let xPosition = (90)
                
                // Create first name label
                let firstNameLabel = UILabel()
                firstNameLabel.text = annotation.guest.firstName // Replace this with the actual first name
                firstNameLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
                firstNameLabel.textColor = .white
                firstNameLabel.sizeToFit()

                // Create last name label
                let lastNameLabel = UILabel()
                lastNameLabel.text = annotation.guest.lastName // Replace this with the actual last name
                lastNameLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
                lastNameLabel.textColor = .white
                lastNameLabel.sizeToFit()

            
                
                firstNameLabel.frame.origin = CGPoint(x: xPosition, y: 0)
                lastNameLabel.frame.origin = CGPoint(x: firstNameLabel.frame.maxX + 5, y: 0)
                

                
                
                // Create a parent UIView for grouping
                self.parentView = UIView()
                self.parentView?.clipsToBounds = true // To ensure all subviews stay within its bounds
                
                let parentViewFrame = CGRect(x: 0, y: 0, width: 60, height: 60) // Adjust the size as needed
                self.parentView = UIView(frame: parentViewFrame)
                self.parentView?.center = view.center
                
                
                
                // Position the parentView at the annotation
                self.parentView?.center.x = mapView.bounds.midX

                // Add parentView to the mapView
                mapView.addSubview(self.parentView!)
                
                // Calculate centers after parentView is created
                let centerX = self.parentView!.frame.width / 2
                let centerY = self.parentView!.frame.height / 2
                duplicatedImageView?.center = CGPoint(x: centerX, y: centerY + 75)
                
                // Create a duplicate of the selected annotation
                
//                let duplicateSize: CGFloat = 30 // Define a proper size for your annotation
                self.duplicatedImageView = UIImageView(image: view.image)
                let scaleFactor: CGFloat = 1.5
                duplicatedImageView?.frame.size = CGSize(width: view.bounds.width * scaleFactor,
                                                         height: view.bounds.height * scaleFactor)
                
                // Add the duplicatedImageView to the parentView
                self.parentView?.addSubview(self.duplicatedImageView!)
                // Add labels to the parent view
                self.parentView?.addSubview(firstNameLabel)
                self.parentView?.addSubview(lastNameLabel)
               
                
                // Add a tap gesture recognizer to the parentView to handle tap events
                let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleAnnotationTap(_:)))
                self.parentView?.addGestureRecognizer(tapGesture)
                
                // Animate the parent view to the top center
                UIView.animate(withDuration: 0.5, delay: 0.0, options: .curveEaseInOut, animations: {
                    self.visualEffectView?.alpha = 1.0 // Fade in
                    let leadingCenter = CGPoint(x: self.parentView!.bounds.width / 2 + 20,
                                                y: self.parentView!.frame.height / 2 + 10) // This will put the center of parentView 20 points from the top and 20 points from the leading edge of the mapView
                    self.parentView?.center = leadingCenter
                })
            }
        }
        
        @objc func callButtonTapped(_ sender: PhoneNumberButton) {
            guard let number = URL(string: "tel://" + (sender.phoneNumber ?? "")) else { return }
            UIApplication.shared.open(number)
        }
        
        @objc func textButtonTapped(_ sender: PhoneNumberButton) {
            // Implement the function to initiate a text conversation
            NotificationCenter.default.post(name: .init("TextButtonTapped"), object: nil, userInfo: ["phoneNumber": sender.phoneNumber ?? ""])
            appStateManager.guestPhoneNumber = sender.phoneNumber ?? "DefaultPhoneNumber"
            appStateManager.isMessageViewPresented = true
            print("Text button was tapped") // Temporary placeholder
        }
        
        
        func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) {
            
            if view == selectedAnnotationView {
                selectedAnnotationView = nil
            }
            print("didDeselect called")
            if view.annotation is FroopDropPin {
                appStateManager.isAnnotationMade = false
                appStateManager.isFroopTabUp = true
            }
            
            if view.annotation is GuestAnnotation, let visualEffectView = self.visualEffectView, let duplicatedAnnotation = self.duplicatedAnnotation {
                print("GuestAnnotation selected, visualEffectView and duplicatedAnnotation are not nil")
                for subview in mapView.subviews {
                    if subview is UIButton {
                        subview.removeFromSuperview()
                    }
                }
                // Animate the blur effect and the duplicated annotation
                UIView.animate(withDuration: 0.5, animations: {
                    print("Removing Blur Effect")
                    visualEffectView.alpha = 0.0 // Fade out
                    duplicatedAnnotation.transform = CGAffineTransform(scaleX: 1.0, y: 1.0) // Resize
                }, completion: { _ in
                    // Remove the blur effect
                    visualEffectView.removeFromSuperview()
                    self.visualEffectView = nil
                    
                    // Remove the duplicated annotation
                    duplicatedAnnotation.removeFromSuperview()
                    self.duplicatedAnnotation = nil
                    
                    // Update isDarkStyle on the main thread
                    DispatchQueue.main.async {
                        print(AppStateManager.shared.isDarkStyle)
                        AppStateManager.shared.isDarkStyle = false
                        print(AppStateManager.shared.isDarkStyle)
                    }
                })
            }
        }
        
        // MARK: - Helpers
        
        func addAndSelectAnnotation(withCoordinate coordinate: CLLocationCoordinate2D) {
            PrintControl.shared.printLocationServices("-ActiveMapViewRepresentable: Function: addAndSelectAnnotation is firing!")
            viewModel.mapView.removeAnnotations(viewModel.mapView.annotations)
            viewModel.annotations.removeAll()   // Remove all annotations from viewModel.annotations
            
            let anno = MKPointAnnotation()
            anno.coordinate = viewModel.froopLocation
            viewModel.mapView.addAnnotation(anno)
            viewModel.annotations.append(anno)   // Add the annotation to viewModel.annotations
            viewModel.mapView.selectAnnotation(anno, animated: true)
        }
    }
}

class MovableAnnotationView: MKAnnotationView {
    var newCenter: CGPoint?
}

protocol MovableAnnotation: AnyObject {
    var coordinate: CLLocationCoordinate2D { get set }
    var title: String? { get set }
    var guest: UserData { get set }
}

class GuestAnnotation: NSObject, MKAnnotation, MovableAnnotation {
    var guest: UserData
    @objc dynamic var coordinate: CLLocationCoordinate2D
    var title: String?
    
    init(guest: UserData) {
        self.guest = guest
        self.coordinate = guest.coordinate
        self.title = "\(guest.firstName) \(guest.lastName)"
        super.init()
    }
}

class PhoneNumberButton: UIButton {
    var phoneNumber: String?
}

class AnnotationModel: ObservableObject {
    @Published var annotation: FroopDropPin?
}


