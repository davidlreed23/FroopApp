//
//  FroopMediaFeedView.swift
//  FroopProof
//
//  Created by David Reed on 5/5/23.
//



import SwiftUI
import Photos
import FirebaseStorage
import Firebase
import FirebaseAuth
import FirebaseFirestore
import Kingfisher
import SwiftUIBlurView

enum ImageType {
    case original, display, thumbnail
}

struct FroopMediaFeedView: View {
    
    @Environment(\.colorScheme) var colorScheme

    @ObservedObject var appStateManager = AppStateManager.shared
    @ObservedObject var printControl = PrintControl.shared
    @ObservedObject var locationServices = LocationServices.shared
    @ObservedObject var froopDataListener = FroopDataListener.shared
    @ObservedObject var froopManager = FroopManager.shared
    @ObservedObject var timeZoneManager:TimeZoneManager = TimeZoneManager()

    @StateObject private var viewModel = FroopMediaFeedViewModel()
    
    
    var db = FirebaseServices.shared.db
    let imageItemskfs: [ImageItemkf] = []
    var isPassiveMode: Bool {
        return AppStateManager.shared.inProgressFroop.froopId == ""
    }
    
    @State private var uploading = false
    
    var body: some View {
        ZStack {
            VStack {
                if AppStateManager.shared.inProgressFroop.froopId != "" {
                    DownloadedImageGridView(imageItems: viewModel.displayImageItems, imageItemskfs: imageItemskfs, onAddToFroop: nil)
                } else {
                    Text("No active Froop ID available.")
                }
            }
        }
        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
        .onAppear {
            if !isPassiveMode {
                viewModel.startListening(froopHost: AppStateManager.shared.inProgressFroop.froopHost)
            }
        }
        .onDisappear {
            viewModel.stopListening()
        }
    }
}

class FroopMediaFeedViewModel: ObservableObject {
    @Published var originalImageItems: [ImageItemkf] = []
    @Published var displayImageItems: [ImageItemkf] = []
    @Published var thumbnailImageItems: [ImageItemkf] = []
    
    private var listener: ListenerRegistration?
    
    func startListening(froopHost: String) {
        print("startListening Function Firing!")
        let froopsRef = db.collection("users").document(froopHost).collection("myFroops")
        
        froopsRef.getDocuments { (querySnapshot, err) in
            if let err = err {
                print("Error getting documents: \(err)")
            } else {
                // Sort documents by froopStartTime in descending order (most recent first)
                let sortedDocuments = querySnapshot!.documents.sorted { (doc1, doc2) -> Bool in
                    let startTime1 = doc1.data()["froopStartTime"] as! Timestamp
                    let startTime2 = doc2.data()["froopStartTime"] as! Timestamp
                    return startTime1.dateValue() > startTime2.dateValue()
                }
                
                // Now, you can loop through sortedDocuments and fetch & load images for each froop sequentially
                for doc in sortedDocuments {
                    let froopId = doc.documentID
                    self.loadFroopContent(froopHost: froopHost, froopId: froopId)
                }
            }
        }
    }

    func loadFroopContent(froopHost: String, froopId: String) {
        let froopRef = db.collection("users").document(froopHost).collection("myFroops").document(froopId)

        froopRef.getDocument { (documentSnapshot, error) in
            guard let document = documentSnapshot else {
                print("Error fetching document: \(String(describing: error))")
                return
            }

            guard let data = document.data() else {
                print("Document data was empty.")
                return
            }

            if let froopImages = data["froopImages"] as? [String] {
                print("Froop original image URLs: \(froopImages)")
                self.downloadImages(from: froopImages, type: .original)
            }

            if let froopDisplayImages = data["froopDisplayImages"] as? [String] {
                print("Froop display image URLs: \(froopDisplayImages)")
                self.downloadImages(from: froopDisplayImages, type: .display)
            }

            if let froopThumbNailImages = data["froopThumbNailImages"] as? [String] {
                print("Froop thumbnail image URLs: \(froopThumbNailImages)")
                self.downloadImages(from: froopThumbNailImages, type: .thumbnail)
            }
        }
    }
    
    func stopListening() {
        listener?.remove()
    }
    
    func downloadImages(from urls: [String], type: ImageType, currentIndex: Int = 0) {
        guard currentIndex < urls.count else { return }

        if let url = URL(string: urls[currentIndex]) {
            KingfisherManager.shared.retrieveImage(with: url) { result in
                switch result {
                case .success(let imageResult):
                    let image = imageResult.image
                    DispatchQueue.main.async {
                        print("Downloaded image successfully: \(urls[currentIndex])")
                        let imageItem = ImageItemkf(image: image, imageUrl: urls[currentIndex])
                        switch type {
                        case .original:
                            self.originalImageItems.insert(imageItem, at: 0)
                        case .display:
                            self.displayImageItems.insert(imageItem, at: 0)
                        case .thumbnail:
                            self.thumbnailImageItems.insert(imageItem, at: 0)
                        }

                        // Continue to the next image
                        self.downloadImages(from: urls, type: type, currentIndex: currentIndex + 1)
                    }
                case .failure(let error):
                    print("Error downloading image: \(error)")
                    // Continue to the next image even if there was an error
                    self.downloadImages(from: urls, type: type, currentIndex: currentIndex + 1)
                }
            }
        }
    }
}

struct ImageItemkf: Identifiable {
    let id = UUID()
    let image: UIImage
    let imageUrl: String
}

struct DownloadedImageGridView: View {
    let imageItems: [ImageItemkf]
    let imageItemskfs: [ImageItemkf]
    let onAddToFroop: ((UIImage) -> Void)?
    
    @State private var showFullScreen = false
    @State private var selectedImage: UIImage?
    @State private var selectedImageIndex: Int?
    @State private var numColumns = 3
    
    var body: some View {
        ZStack {
            GeometryReader { geometry in
                ScrollView(showsIndicators: false) {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: numColumns), spacing: 3) {
                        ForEach(imageItems.indices, id: \.self) { index in
                            let imageItem = imageItems[index]
                            ImageWithCheckmarkOverlay(imageItem: imageItem, index: index, geometry: geometry)
                        }
                    }
                    .padding(.top, 75)
                }
            }
            VStack { 
                HStack {
                    Spacer()
                    Button(action: {
                        if numColumns == 1 {
                            numColumns = 3
                        } else {
                            numColumns = 1
                        }
                        
                    }, label: {
                        Image(systemName: numColumns == 1 ? "square.grid.3x3.square" : "arrow.left.and.right.square.fill" )
                            .font(.system(size: 42))
                            .fontWeight(.thin)
                            .foregroundColor(Color(red: 249/255, green: 0/255, blue: 95/255))
                    })
                    .background(.ultraThinMaterial)
                    .padding(.trailing, 15)
                    .padding(.top, 15)
                }
                Spacer()
            }
        }
    }
    
    @ViewBuilder
    private func ImageWithCheckmarkOverlay(imageItem: ImageItemkf, index: Int, geometry: GeometryProxy) -> some View {
        
        Image(uiImage: imageItem.image)
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(width: (geometry.size.width / CGFloat(numColumns)) - 0, height: (geometry.size.width / CGFloat(numColumns)) - 0)
            .clipped()
            .onTapGesture {
                selectedImage = imageItem.image
                showFullScreen = true
            }
    }
}
