//
//  DetailsHostMessgeEditView.swift
//  FroopProof
//
//  Created by David Reed on 6/21/23.
//

//
//  DetailsHostMessageView.swift
//  Design_Layouts
//
//  Created by David Reed on 6/20/23.
//

import SwiftUI
import SwiftUIBlurView
import Kingfisher
import Firebase
import FirebaseAuth
import FirebaseStorage
import FirebaseFirestore
import Foundation
import MapKit
import EventKit
import FirebaseCrashlytics
import AVKit
import UIKit
import PhotosUI

struct DetailsHostMessageEditView: View {
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject var appStateManager = AppStateManager.shared
    @ObservedObject var printControl = PrintControl.shared
    @ObservedObject var locationServices = LocationServices.shared
    @ObservedObject var froopDataListener = FroopDataListener.shared
    @ObservedObject var myData = MyData.shared
    @ObservedObject var froopManager = FroopManager.shared
    @ObservedObject var friendViewController = FriendViewController.shared
    @ObservedObject var timeZoneManager: TimeZoneManager = TimeZoneManager()
    @ObservedObject var froopData: FroopData = FroopData()
    @ObservedObject var friendData: UserData = UserData()
    
    @State private var showingAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var videoPickerPresented = false
    @State private var videoURL: URL? = nil
    
    @Binding var messageEdit: Bool
    
    @State var froopHostMessage: String = ""
    
    var body: some View {
        ZStack {
            
            Rectangle()
                .foregroundColor(colorScheme == .dark ? .black : .black)
                .opacity(0.7)
                .ignoresSafeArea()
                .onTapGesture {
                    messageEdit = false
                    UIApplication.shared.endEditing()
                }
            
            RoundedRectangle(cornerRadius: 10)
                .frame(height: 235)
                .foregroundColor(colorScheme == .dark ? Color(red: 230/255 , green: 230/255, blue: 235/255) : Color(red: 230/255 , green: 230/255, blue: 235/255))
                .padding(.leading, 15)
                .padding(.trailing, 15)
            
            VStack (spacing: 0){
                ZStack {
                    
                    VStack {
                        ZStack {
                            HStack (alignment: .bottom){
                                Text("Editing: Message from the Host")
                                    .font(.system(size: 14))
                                    .foregroundColor(.black)
                                    .opacity(0.7)
                                    .fontWeight(.semibold)
                                    .offset(y: 10)
                                Spacer()
                                
                            }
                            HStack {
                                Spacer()
                                Text("Save Message")
                                    .foregroundColor(.blue)
                                    .font(.system(size: 14))
                                    .fontWeight(.semibold)
                                    .opacity(0.7)
                                    .multilineTextAlignment(.center)
                                    .padding(.bottom, 10)
                                    .padding(.trailing, 15)
                                    .offset(x: 25, y: -15)
                                    .onTapGesture {
                                        messageEdit = true
                                        saveMessage()
                                    }
                            }
                        }
                        
                        .padding(.trailing, 25)
                        .padding(.leading, 25)
                    }
                    .frame(maxHeight: 50)
                }
                .padding(.leading, 15)
                .padding(.trailing, 15)
                
                Divider()
                    .padding(.bottom, 15)
                    .padding(.leading, 15)
                    .padding(.trailing, 15)
                
                
                ZStack {
                    
                    HStack (alignment: .top) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 5)
                                .frame(maxWidth: 50, maxHeight:75)
                                .foregroundColor(.blue)
                            VStack {
                                Text("Upload")
                                    .foregroundColor(.white)
                                    .font(.system(size: 14))
                                    .fontWeight(.medium)
                                Text("Video")
                                    .foregroundColor(.white)
                                    .font(.system(size: 14))
                                    .fontWeight(.medium)
                            }
                        }
                        .offset(y: 15)
                        
                        .onTapGesture {
                            videoPickerPresented = true
                        }
                        .padding(.trailing, 10)
                        VStack (alignment: .center, spacing: 0){
                            TextEditor(text: $froopHostMessage)
                                .onChange(of: froopHostMessage, initial: false) { _, newValue in
                                    if newValue.count > 150 {
                                        froopHostMessage = String(newValue.prefix(150))
                                    }
                                }
                                .lineLimit(4)
                                .frame(height: 100)
                                .padding(.bottom, 10)
                            HStack {
                                Text("Done")
                                    .font(.system(size: 16))
                                    .foregroundColor(.blue)
                                    .onTapGesture {
                                        UIApplication.shared.endEditing()
                                    }
                                    .padding(.leading, 5)
                                Spacer()
                                Text("\(150 - froopHostMessage.count)")
                                    .font(.system(size: 12))
                                    .foregroundColor(froopHostMessage.count > 140 ? .red : .gray)
                                    .padding(.trailing, 15)
                            }
                        }
                        .padding(.top, 15)
                        Spacer()
                        
                    }
                    .frame(maxHeight: 125)
                    .padding(.trailing, 25)
                    .padding(.leading, 25)
                }
                .padding(.leading, 10)
                .padding(.trailing, 10)
                Divider()
                    .padding(.top, 15)
            }
        }
        
    }
    
    func uploadVideo() {
        guard let videoURL = videoURL else { return }
        uploadTOFireBaseVideo(url: videoURL, success: { (downloadURLString) in
            print("Video uploaded with URL: \(downloadURLString)")
            // Add the URL to your Froop data
            // For example: froopManager.selectedFroop.froopVideos.append(downloadURLString)
        }, failure: { (error) in
            print("Failed to upload video: \(error)")
        })
    }
    
    func convertVideo(toMPEG4FormatForVideo inputURL: URL, outputURL: URL, handler: @escaping (AVAssetExportSession) -> Void) {
        try! FileManager.default.removeItem(at: outputURL as URL)
        let asset = AVURLAsset(url: inputURL as URL, options: nil)
        
        let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHighestQuality)!
        exportSession.outputURL = outputURL
        exportSession.outputFileType = .mp4
        exportSession.exportAsynchronously(completionHandler: {
            handler(exportSession)
        })
    }
    
    func uploadTOFireBaseVideo(url: URL,
                               success : @escaping (String) -> Void,
                               failure : @escaping (Error) -> Void) {
        
        let name = "\(Int(Date().timeIntervalSince1970)).mp4"
        let path = NSTemporaryDirectory() + name
        
        let dispatchgroup = DispatchGroup()
        
        dispatchgroup.enter()
        
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let outputurl = documentsURL.appendingPathComponent(name)
        var ur = outputurl
        self.convertVideo(toMPEG4FormatForVideo: url as URL, outputURL: outputurl) { (session) in
            
            ur = session.outputURL!
            dispatchgroup.leave()
            
        }
        dispatchgroup.wait()
        
        let data = NSData(contentsOf: ur as URL)
        
        do {
            
            try data?.write(to: URL(fileURLWithPath: path), options: .atomic)
            
        } catch {
            
            print(error)
        }
        
        let storageRef = Storage.storage().reference().child("Videos").child(name)
        if let uploadData = data as Data? {
            storageRef.putData(uploadData, metadata: nil) { (metadata, error) in
                if let error = error {
                    failure(error)
                } else {
                    storageRef.downloadURL { (url, error) in
                        if let error = error {
                            failure(error)
                        } else if let url = url {
                            success(url.absoluteString)
                        }
                    }
                }
            }
        }
    }
    
    func saveMessage() {
        guard let uid = Auth.auth().currentUser?.uid else {
            print("No user ID found")
            return
        }
        
        let froopDocRef = Firestore.firestore().collection("users").document(uid).collection("myFroops").document(froopManager.selectedFroop.froopId)
        
        froopDocRef.updateData([
            "froopMessage": froopHostMessage
        ]) { err in
            if let err = err {
                print("Error updating document: \(err)")
            } else {
                print("Document successfully updated")
                showAlert(title: "Success", message: "Message was saved successfully.")
            }
        }
    }
    
    func showAlert(title: String, message: String) {
        alertTitle = title
        alertMessage = message
        showingAlert = true
    }
}



struct VideoPicker: UIViewControllerRepresentable {
    @Binding var selectedVideoURL: URL?
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var configuration = PHPickerConfiguration()
        configuration.selectionLimit = 1
        configuration.filter = .videos
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {
        // Not used
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: VideoPicker
        
        init(_ parent: VideoPicker) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            if let result = results.first {
                result.itemProvider.loadFileRepresentation(forTypeIdentifier: UTType.movie.identifier) { (url, error) in
                    if let error = error {
                        print("Failed to load video: \(error)")
                    } else if let url = url {
                        self.parent.selectedVideoURL = url
                    }
                }
            }
        }
    }
}









