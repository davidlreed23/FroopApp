//
//  PhotoLibraryView.swift
//  FroopProof
//
//  Created by David Reed on 5/5/23.
//

import UIKit
import SwiftUI
import Photos
import PhotosUI
import FirebaseStorage
import Firebase
import FirebaseAuth
import FirebaseFirestore
import NavigationStack
import CommonCrypto

struct PhotoLibraryView: View {
    
    
    
    @ObservedObject var printControl = PrintControl.shared
    @ObservedObject var froopDataListener = FroopDataListener.shared
    
    @ObservedObject private var viewModel: ImageGridViewModel
    @ObservedObject var froopManager = FroopManager.shared
    var isPassiveMode: Bool {
        return AppStateManager.shared.inProgressFroop.froopId == ""
    }
    @State var uniqueID = UUID()
    @State private var uploading = false
    @Binding var uploadedImages: [ImageItem]
    
    let froopStartTime = AppStateManager.shared.inProgressFroop.froopStartTime.addingTimeInterval(-30 * 60)
    let froopEndTime = AppStateManager.shared.inProgressFroop.froopEndTime.addingTimeInterval(30 * 60)
    let validData = Data()
    let validString = ""
    
    
    public init(viewModel: ImageGridViewModel, uploadedImages: Binding<[ImageItem]>) {
        _viewModel = ObservedObject(wrappedValue: viewModel)
        _uploadedImages = uploadedImages
    }
    
    var body: some View {
        
        ZStack {
            
            VStack {
                if !isPassiveMode {
                    ImageGridView(onAddToFroop: { image, creationDate in
                        onAddToFroop(image: image, creationDate: creationDate)
                    }, uploadSelectedImages: uploadSelectedImages2, viewModel: viewModel, uploadedImages: $uploadedImages, uniqueID: $uniqueID)
                }
            }
            
            if uploading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                    .scaleEffect(2)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.blue.opacity(1))
                    .edgesIgnoringSafeArea(.all)
            }
            
        }
        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
        .onAppear {
            viewModel.loadImages(from: froopStartTime, to: froopEndTime, validData: validData, validString: validString)
        }
    }
    
    
    func onAddToFroop(image: UIImage, creationDate: Date) {
        guard let imageData = image.jpegData(compressionQuality: 0.7) else {
            print("Error: Could not convert image to JPEG data")
            return
        }
        
        let froopId = AppStateManager.shared.inProgressFroop.froopId
        let froopHost = AppStateManager.shared.inProgressFroop.froopHost
        
        let storage = Storage.storage()
        let storageRef = storage.reference()
        let froopMediaAssetsRef = storageRef.child("FroopMediaAssets/\(froopHost)/\(froopId)")
        let imageName = UUID().uuidString
        let imageRef = froopMediaAssetsRef.child("\(imageName).jpg")
        
        uploading = true
        
        _ = imageRef.putData(imageData, metadata: nil) { (metadata, error) in
            guard let _ = metadata else {
                print("Error: Failed to upload image to Firebase Storage")
                return
            }
            
            imageRef.downloadURL { (url, error) in
                guard let downloadURL = url else {
                    print("Error: Failed to get the download URL")
                    return
                }
                
                FroopManager.shared.addMediaURLToDocument(
                    froopHost: froopHost,
                    froopId: froopId,
                    mediaURL: downloadURL,
                    isImage: true
                )
                
                DispatchQueue.main.async {
                    uploading = false
                }
                AppStateManager.shared.mediaTimeStamp.append(creationDate)
                
            }
        }
    }
    
    func uploadSelectedImages(_ images: [ImageItem]) {
        uploading = true
        DispatchQueue.global(qos: .background).async {
            for imageItem in images {
                if let image = imageItem.image {
                    onAddToFroop(image: image, creationDate: Date())
                }
            }
            DispatchQueue.main.async {
                uploading = false
            }
        }
    }
    
    func uploadSelectedImages2(_ images: [ImageItem], onImageUploaded: @escaping (ImageItem) -> Void, onAllImagesUploaded: @escaping () -> Void) {
        let group = DispatchGroup()
        var imageUrls: [URL] = []
        
        for selectedImage in images {
            guard let image = selectedImage.image else { continue }
            group.enter()
            
            guard let fullsizeImageData = image.jpegData(compressionQuality: 1.0),
                  let displayImageData = image.resized(toWidth: 750)?.jpegData(compressionQuality: 0.7),
                  let thumbnailImageData = image.resized(toWidth: 200)?.jpegData(compressionQuality: 0.5) else {
                print("Error: Could not convert image to JPEG data")
                group.leave()
                continue
            }
            
            let froopId = AppStateManager.shared.inProgressFroop.froopId
            let froopHost = AppStateManager.shared.inProgressFroop.froopHost
            
            let storage = Storage.storage()
            let storageRef = storage.reference()
            let froopMediaAssetsRef = storageRef.child("FroopMediaAssets/\(froopHost)/\(froopId)")
            let imageName = UUID().uuidString
            
            let imageDirectoryRef = froopMediaAssetsRef.child(imageName)
            
            let fullsizeImageRef = imageDirectoryRef.child("fullsize.jpg")
            let displayImageRef = imageDirectoryRef.child("display.jpg")
            let thumbnailImageRef = imageDirectoryRef.child("thumbnail.jpg")
            
            let metaData = StorageMetadata()
            metaData.contentType = "image/jpeg"
            
            let uploadTasks = [
                fullsizeImageRef.putData(fullsizeImageData, metadata: metaData),
                displayImageRef.putData(displayImageData, metadata: metaData),
                thumbnailImageRef.putData(thumbnailImageData, metadata: metaData)
            ]
            
            let dispatchGroup = DispatchGroup()
            
            var fullsizeImageUrl: URL?
            var displayImageUrl: URL?
            var thumbnailImageUrl: URL?
            
            for (index, uploadTask) in uploadTasks.enumerated() {
                dispatchGroup.enter()
                uploadTask.observe(.success) { snapshot in
                    snapshot.reference.downloadURL { url, error in
                        if let url = url {
                            switch index {
                                case 0:
                                    fullsizeImageUrl = url
                                case 1:
                                    displayImageUrl = url
                                case 2:
                                    thumbnailImageUrl = url
                                default:
                                    break
                            }
                        }
                        dispatchGroup.leave()
                    }
                }
            }
            
            dispatchGroup.notify(queue: .main) {
                guard let fullsizeImageUrl = fullsizeImageUrl,
                      let displayImageUrl = displayImageUrl,
                      let thumbnailImageUrl = thumbnailImageUrl else {
                    print("Error: Failed to get the download URLs")
                    group.leave()
                    return
                }
                
                FroopManager.shared.addMediaURLsToDocument(
                    froopHost: froopHost,
                    froopId: froopId,
                    fullsizeImageUrl: fullsizeImageUrl,
                    displayImageUrl: displayImageUrl,
                    thumbnailImageUrl: thumbnailImageUrl,
                    isImage: true
                )
                
                imageUrls.append(fullsizeImageUrl)
                onImageUploaded(selectedImage)
                group.notify(queue: .main) {
                    print("All images uploaded, urls: \(imageUrls)")
                    // Call the onAllImagesUploaded closure
                    onAllImagesUploaded()
                }
            }
        }
        
        group.notify(queue: .main) {
            print("All images uploaded, urls: \(imageUrls)")
            // Do any additional processing with the image URLs here
        }
    }
}



class ImageGridViewModel: ObservableObject {
    @Published var imageItems: [ImageItem] = []
    
    private var lastFetchedIndex: Int = 0
    
    private var mediaManager = MediaManager()
    
    func sha256Data(_ data: Data) -> String {
        var hash = [UInt8](repeating: 0,  count: Int(CC_SHA256_DIGEST_LENGTH))
        data.withUnsafeBytes {
            _ = CC_SHA256($0.baseAddress, CC_LONG(data.count), &hash)
        }
        return Data(hash).map { String(format: "%02x", $0) }.joined()
    }
    
    func loadNextBatchOfImages() {
        let batchSize = 3
        
        let rangeStart = lastFetchedIndex
        let rangeEnd = min(lastFetchedIndex + batchSize, imageItems.count)
        
        for index in rangeStart..<rangeEnd {
            loadImage(for: imageItems[index]) { image in
                DispatchQueue.main.async {
                    self.imageItems[index].image = image
                }
            }
        }
        
        lastFetchedIndex = rangeEnd
    }
    
    func loadImages(from froopStartTime: Date, to froopEndTime: Date, validData: Data, validString: String) {
        mediaManager.requestPhotoLibraryAuthorization { success in
            if success {
                self.mediaManager.fetchMediaFromPhotoLibrary(froopStartTime: froopStartTime, froopEndTime: froopEndTime) { assets in
                    DispatchQueue.main.async {
                        // Filter out any assets that have a creation date that's already in the mediaTimeStamp array
                        let filteredAssets = assets.filter { asset in
                            guard let creationDate = asset.creationDate else {
                                return false
                            }
                            return !AppStateManager.shared.mediaTimeStamp.contains(creationDate)
                        }
                        
                        // Sort the assets in descending order of creation date
                        let sortedAssets = filteredAssets.sorted(by: { $0.creationDate ?? Date() > $1.creationDate ?? Date() })
                        self.imageItems = sortedAssets.map { asset -> ImageItem in
                            return ImageItem(asset: asset, image: nil, imageData: validData, hash: validString, show: false)
                        }
                    }
                }
            } else {
                print("Authorization failed")
            }
        }
    }
    
    func loadImage(for imageItem: ImageItem, completion: @escaping (UIImage?) -> Void) {
        let manager = PHImageManager.default()
        let requestOptions = PHImageRequestOptions()
        requestOptions.deliveryMode = .opportunistic
        requestOptions.isSynchronous = false
        let targetSize = CGSize(width: imageItem.asset.pixelWidth, height: imageItem.asset.pixelHeight)
        
        manager.requestImage(for: imageItem.asset, targetSize: targetSize, contentMode: .aspectFit, options: requestOptions) { (image, info) in
            DispatchQueue.main.async {
                completion(image)
            }
        }
    }
}

struct ImageGridView: View {
    let onAddToFroop: ((UIImage, Date) -> Void)? // Modify the type of onAddToFroop
    let uploadSelectedImages: ((_ images: [ImageItem], _ onImageUploaded: @escaping (ImageItem) -> Void, _ onAllImagesUploaded: @escaping () -> Void) -> Void)?
    @ObservedObject var viewModel: ImageGridViewModel
    @State var showingFullScreenImageView = false
    @State var selectedImageIndex: Int?
    @State var selectedImageItem: ImageItem?
    @State var selectedImages: [ImageItem] = []
    @State var numColumns = 3
    @Binding var uploadedImages: [ImageItem]
    @Binding var uniqueID: UUID
    
    init(onAddToFroop: ((UIImage, Date) -> Void)?, uploadSelectedImages: ((_ images: [ImageItem], _ onImageUploaded: @escaping (ImageItem) -> Void, _ onAllImagesUploaded: @escaping () -> Void) -> Void)?, viewModel: ImageGridViewModel, uploadedImages: Binding<[ImageItem]>, uniqueID: Binding<UUID>) {
        self.onAddToFroop = onAddToFroop
        self.uploadSelectedImages = uploadSelectedImages
        self.viewModel = viewModel
        _uploadedImages = uploadedImages
        _uniqueID = uniqueID
    }
    
    var body: some View {
        ZStack {
            
            GeometryReader { geometry in
                if numColumns == 3 {
                    ScrollView(showsIndicators: false) {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: numColumns), spacing: 3) {
                            ForEach(viewModel.imageItems.indices, id: \.self) { index in
                                let imageItem = viewModel.imageItems[index]
                                ImageWithCheckmarkOverlay(imageItem: imageItem, index: index, geometry: geometry)
                            }
                            .id(uniqueID)
                        }
                        //                        .padding(.top, 75)
                    }
                } else {
                    FroopPhotoSelectView(selectedImageIndex: selectedImageItem.map { viewModel.imageItems.firstIndex(of: $0) ?? 0 } ?? 0, filteredImages: $viewModel.imageItems, viewModel: viewModel, selectedImages: $selectedImages, uploadedImages: $uploadedImages)
                }
            }
            
            VStack {
                Spacer()
                HStack {
                    Button(action: {
                        // Save selected images to the Froop
                        if let uploadSelectedImages = uploadSelectedImages {
                            print("uploadedImages before removeall \(uploadedImages)")
                            uploadSelectedImages(selectedImages, { uploadedImage in
                                uploadedImages.append(uploadedImage)
                                selectedImages.removeAll { $0 == uploadedImage }
                            }, {
                                // Clear the selectedImages array after all images have been uploaded
                                selectedImages.removeAll()
                            })
                            print("selectedImages after removeall \(selectedImages)")
                            print("uploadedImages after removeall \(uploadedImages)")
                        }
                    }, label: {
                        Text("Save to Froop!")
                            .font(.system(size: 36))
                            .fontWeight(.thin)
                            .foregroundColor(.black)
                    })
                    .buttonStyle(FroopButtonStyle())
                    .frame(width: 250, height: 40 )
                    .cornerRadius(10)
                    .border(.gray, width: 0.5)
                    .background(.ultraThinMaterial)
                    .opacity(selectedImages.isEmpty ? 0.05 : 1)
                    .padding(.bottom, 40)
                    .padding(.leading, 35)
                    .padding(.trailing, 35)
                    
                }
            }
            .padding(.bottom, 90)
            
            VStack{
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
                    .padding(.trailing, 15)
                    .padding(.top, 15)
                }
                Spacer()
            }
        }
    }
    
    func toggleImageSelection(imageItem: ImageItem, index: Int) {
        // Ignore if the image is already in the uploadedImages array
        if uploadedImages.contains(where: { $0.id == imageItem.id }) {
            return
        }
        print("toggleImageSelection Function Firing!")
        if let itemIndex = viewModel.imageItems.firstIndex(where: { $0.id == imageItem.id }) {
            var updatedImage = viewModel.imageItems[itemIndex]
            updatedImage.isSelected.toggle()
            viewModel.imageItems[itemIndex] = updatedImage
            
            if updatedImage.isSelected {
                selectedImages.append(updatedImage)
            } else {
                selectedImages.removeAll { $0.id == updatedImage.id }
            }
        }
    }
    
    @ViewBuilder
    private func ImageWithCheckmarkOverlay(imageItem: ImageItem, index: Int, geometry: GeometryProxy) ->some View {
        
        ZStack {
            if let image = imageItem.image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: (geometry.size.width / CGFloat(numColumns)) - 0, height: (geometry.size.width / CGFloat(numColumns)) - 0)
                    .clipped()
                    .opacity(uploadedImages.contains(where: { $0.id == imageItem.id }) ? 0.5 : 1.0)
            } else {
                Color.gray
                    .frame(width: (geometry.size.width / CGFloat(numColumns)) - 0, height: (geometry.size.width / CGFloat(numColumns)) - 0)
                    .onAppear {
                        viewModel.loadImage(for: imageItem) { image in
                            if let image = image {
                                if let index = viewModel.imageItems.firstIndex(where: { $0.id == imageItem.id }) {
                                    viewModel.imageItems[index].image = image
                                }
                            }
                        }
                    }
            }
            
            if imageItem.isSelected {
                ZStack (alignment: .center){
                    Circle()
                        .frame(width: 32, height: 32)
                        .foregroundColor(.white)
                    Image(systemName: "checkmark.circle.fill")
                        .resizable()
                        .frame(width: 28, height: 28)
                        .foregroundColor(uploadedImages.contains(where: { $0.id == imageItem.id }) ? .green : .blue)
                }
                .offset(x: 45, y: 45)
            }
        }
        .onTapGesture(count: 2) {
            print("DoubleTap Firing!")
            selectedImageIndex = index
            selectedImageItem = imageItem
            showingFullScreenImageView = true
            numColumns = 1
        }
        .simultaneousGesture(TapGesture().onEnded {
            withAnimation {
                toggleImageSelection(imageItem: imageItem, index: index)
            }
        })
    }
}


enum ImageShape {
    case square
    case rectangleTwoToOne
    case rectangleOneToTwo
}


struct ImageItem: Identifiable, Hashable {
    let id = UUID()
    let owner = FirebaseServices.shared.uid
    let asset: PHAsset
    var image: UIImage?
    var show: Bool
    var isSelected: Bool = false
    let imageData: Data
    let hash: String
    
    static func == (lhs: ImageItem, rhs: ImageItem) -> Bool {
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    init(asset: PHAsset, image: UIImage? = nil, imageData: Data, hash: String, show: Bool) {
        self.asset = asset
        self.image = image
        self.show = false
        self.imageData = imageData
        self.hash = hash
    }
    
    enum ImageShape {
        case square
        case rectangleTwoToOne
        case rectangleOneToTwo
        case unknown
    }
    
    var shape: ImageShape {
        guard let image = image else {
            return .unknown
        }
        
        let aspectRatio = image.size.width / image.size.height
        
        if abs(aspectRatio - 1) < 0.1 {
            return .square
        } else if abs(aspectRatio - 2) < 0.1 {
            return .rectangleTwoToOne
        } else {
            return .rectangleOneToTwo
        }
    }
}

class MediaGridViewModel: ObservableObject {
    @Published var mediaItems: [MediaData] = []
    
    private var lastFetchedIndex: Int = 0
    
    private var mediaManager = MediaManager()
    
    
}

