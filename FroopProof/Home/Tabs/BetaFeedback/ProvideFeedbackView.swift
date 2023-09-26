//
//  ProvideFeedbackView.swift
//  FroopProof
//
//  Created by David Reed on 2/10/23.
//
//
import SwiftUI
import Firebase
import FirebaseFirestore
import MapKit

struct ProvideFeedbackView: View {
    
    
    
    @ObservedObject var printControl = PrintControl.shared
   
    @ObservedObject var froopDataListener = FroopDataListener.shared
   
 
    
    var db = FirebaseServices.shared.db
    let uid = FirebaseServices.shared.uid
    @ObservedObject var myData = MyData.shared
    @State private var topic: String = ""
    @State private var bodyText: String = ""
    @State private var showingSuccessAlert = false
    @ObservedObject private var keyboard = KeyboardResponder()
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack {
                Text("Date & Time: \(Date())")
                    .font(.system(size: 20))
                    .fontWeight(.thin)
                    .foregroundColor(.black)
                    .padding(.leading, 20)
                    .padding(.trailing, 20)
                    .padding(.top, 20)
                
                Text("Please provide your feedback.")
                    .font(.system(size: 24))
                    .fontWeight(.light)
                    .foregroundColor(.black)
                    .padding(.leading, 20)
                    .padding(.trailing, 20)
                    .padding(.top, 25)
                
                TextField("Topic", text: $topic)
                    .frame(height: 50)
                    .border(Color.gray, width: 0.5)
                    .font(.system(size: 20))
                    .fontWeight(.light)
                    .foregroundColor(.black)
                    .padding(.leading, 20)
                    .padding(.trailing, 20)
                    .padding(.top, 5)
                
                
                Text("Please describe your experience.")
                    .font(.system(size: 24))
                    .fontWeight(.light)
                    .foregroundColor(.black)
                    .padding(.leading, 20)
                    .padding(.trailing, 20)
                    .padding(.top, 15)
                
                TextEditor(text: $bodyText)
                    .frame(minHeight: 175, maxHeight: .infinity)
                    .border(Color.gray, width: 0.5)
                    .font(.system(size: 20))
                    .fontWeight(.thin)
                    .foregroundColor(.black)
                    .padding(.top, 5)
                    .padding(.leading, 20)
                    .padding(.trailing, 20)
            }
            Button(action: {
                saveFeedbackToFirestore()
                self.showingSuccessAlert = true
                self.topic = ""
                self.bodyText = ""
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil) // Add this line to dismiss the keyboard
            }) {
                Text("Send Feedback")
                    .font(.headline)
                    .foregroundColor(.black)
                    .font(.system(size: 24))
                    .fontWeight(.medium)
                    .padding()
                    .cornerRadius(5)
                    .border(.gray, width: 0.25)
                    .padding(.bottom, 60)
                    .alert(isPresented: $showingSuccessAlert) {
                        Alert(title: Text("Success"), message: Text("Your feedback has been sent successfully."), dismissButton: .default(Text("Ok")))
                    }
            }
        }
        Spacer()
        
        
            .padding(.bottom, keyboard.currentHeight)
        //.animation(.easeOut(duration: 0.16))
            .navigationBarTitle("Feedback", displayMode: .inline)
    }
    
    
    func saveFeedbackToFirestore() {
        let feedbackId = UUID().uuidString
        let froopId = AppStateManager.shared.appState == .active ? AppStateManager.shared.inProgressFroop.froopId : ""
        let froopHost = AppStateManager.shared.appState == .active ? AppStateManager.shared.inProgressFroop.froopHost : ""
        let userLocation = FirebaseServices.shared.userLocation ?? CLLocationCoordinate2D()
        let feedbackData = FeedbackDataModel(
            id: feedbackId,
            froopId: froopId,
            froopHost: froopHost,
            type: "",
            userLatitude: userLocation.latitude,
            userLongitude: userLocation.longitude,
            createdAt: Date(),
            topic: self.topic,
            bodyText: self.bodyText,
            fromUser: self.uid
        )
        db.collection("feedback").document(feedbackId).setData(feedbackData.dictionary) { error in
            if let error = error {
                print("Error writing feedback to Firestore: \(error)")
            }
        }
    }
}



class KeyboardResponder: ObservableObject {
    @Published var currentHeight: CGFloat = 0
    var _center: NotificationCenter
    
    init(center: NotificationCenter = .default) {
        _center = center
        _center.addObserver(self, selector: #selector(keyBoardWillShow(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        _center.addObserver(self, selector: #selector(keyBoardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    deinit {
        _center.removeObserver(self)
    }
    @objc func keyBoardWillShow(notification: Notification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            currentHeight = keyboardSize.height
        }
    }
    
    @objc func keyBoardWillHide(notification: Notification) {
        currentHeight = 0
    }
}
