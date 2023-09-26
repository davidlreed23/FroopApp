//
//  LoginViewModel.swift
//  FroopProof
//
//  Created by David Reed on 1/18/23.
//

import SwiftUI
import UIKit
import Foundation
import FirebaseAuth
import Firebase
import CryptoKit
import AuthenticationServices
import GoogleSignInSwift
import GoogleSignIn


class LoginViewModel: ObservableObject {
    // MARK: View Properties
    @Published var mobileNo: String = ""
    @Published var otpCode: String = ""
    
    @Published var CLIENT_CODE: String = ""
    @Published var showOTPField: Bool = false
    
    // MARK: Error Properties
    @Published var showError: Bool = false
    @Published var errorMessage: String = ""
    
    // MARK: App Log Status
    @AppStorage("log_status") var logStatus: Bool = false
    
    // MARK: Apple Sign in Properties
    @Published var nonce: String = ""
    
    // MARK: Firebase API's
    func getOTPCode(){
        PrintControl.shared.printLogin("-LoginViewModel: Function: getOTPCode firing")
        UIApplication.shared.closeKeyboard()
        PrintControl.shared.printLogin("Getting OTP Code")
        Task{
            do{
                // MARK: Disable it when testing with Real Device
                Auth.auth().settings?.isAppVerificationDisabledForTesting = true
                
                PrintControl.shared.printLogin("+1\(mobileNo)")
                let formattedMobileNo = self.mobileNo.replacingOccurrences(of: "[()\\- ]", with: "", options: .regularExpression)
                PrintControl.shared.printLogin("Before calling verifyPhoneNumber")
                let code = try await PhoneAuthProvider.provider().verifyPhoneNumber("+1\(formattedMobileNo)", uiDelegate: nil)
                PrintControl.shared.printLogin("After calling verifyPhoneNumber")
                await MainActor.run(body: {
                    CLIENT_CODE = code
                    // MARK: Enabling OTP Field When It's Success
                    withAnimation(.easeInOut){showOTPField = true}
                    PrintControl.shared.printLogin("OTP Code Success")
                })
            }catch{
                await handleError(error: error)
            }
        }
    }
    
    func verifyOTPCode(){
        PrintControl.shared.printLogin("-LoginView: Function: verifyOTPCode firing")
        UIApplication.shared.closeKeyboard()
        PrintControl.shared.printLogin("verifying OTP Code")
        Task{
            do{
                let credential = PhoneAuthProvider.provider().credential(withVerificationID: CLIENT_CODE, verificationCode: otpCode)
                
                try await Auth.auth().signIn(with: credential)
                
                // MARK: User Logged in Successfully
                PrintControl.shared.printLogin("Success!")
                await MainActor.run(body: {
                    withAnimation(.easeInOut){logStatus = true}
                })
            }catch{
                await handleError(error: error)
            }
        }
    }
    
    // MARK: Handling Error
    private func handleError(error: Error)async{
        PrintControl.shared.printLogin("-LoginView: Function: handleError firing")
        await MainActor.run(body: {
            errorMessage = error.localizedDescription
            PrintControl.shared.printErrorMessages("Error in handleError: \(errorMessage)")
            showError = true
        })
    }

    // MARK: Apple Sign in API
    func appleAuthenticate(credential: ASAuthorizationAppleIDCredential){
        PrintControl.shared.printLogin("-LoginView: Function: appleAuthenticate firing")
        
        // getting Token....
        guard let token = credential.identityToken else{
            PrintControl.shared.printLogin("Error with firebase: identity token is missing")
            return
        }
        
        // Token String...
        guard let tokenString = String(data: token, encoding: .utf8) else{
            PrintControl.shared.printLogin("Error with Token: unable to convert token to string")
            return
        }
        
        let firebaseCredential = OAuthProvider.credential(withProviderID: "apple.com", idToken: tokenString,rawNonce: nonce)
        
        Auth.auth().signIn(with: firebaseCredential) { [weak self] (result, err) in
            if let error = err{
                PrintControl.shared.printLogin(error.localizedDescription)
                Crashlytics.crashlytics().record(error: error) // Log error to Crashlytics
                return
            }
            
            // User Successfully Logged Into Firebase...
            PrintControl.shared.printLogin("Logged In Success")
            
            // After user has been authenticated, call your function
            if let uid = Auth.auth().currentUser?.uid {
                self?.createUserAndCollections(uid: uid, completion: { (error) in
                    if let error = error {
                        // Handle any errors here if you need to
                        PrintControl.shared.printErrorMessages("Error creating user and collections: \(error.localizedDescription)")
                        return
                    }

                    // Once the collections and user data are set/updated, proceed to the next view
                    DispatchQueue.main.async {
                        self?.logStatus = true
                    }
                })
            }
        }
    }
    
    func createUserAndCollections(uid: String, completion: @escaping (Error?) -> Void) {
        let batch = db.batch()
        
        // Get FCM token
        let fcmToken = getUserFcmToken() ?? ""
        
        // Creating the user document
        let userDocRef = RefPath.userDocRef(uid: Auth.auth().currentUser?.uid ?? "")
        
        // Check if the document already exists
        userDocRef.getDocument { (documentSnapshot, error) in
            if let error = error {
                completion(error)
                return
            }
            
            if let documentSnapshot = documentSnapshot, documentSnapshot.exists {
                // If the document exists, update it
                let data = ["froopUserID": Auth.auth().currentUser?.uid ?? "", "fcmToken": fcmToken]
                batch.updateData(data, forDocument: userDocRef)
            } else {
                // If the document does not exist, set it
                var data = MyData.shared.dictionary
                data["froopUserID"] = Auth.auth().currentUser?.uid ?? ""
                data["fcmToken"] = fcmToken
                batch.setData(data, forDocument: userDocRef)
            }
            
            // Creating collections inside the user document
            let collectionsInsideUser = ["myFroops", "froopDecisions", "friends"]
            for collection in collectionsInsideUser {
                let newDocRef = userDocRef.collection(collection).document("placeholder")
                batch.setData(["placeholder": "placeholder"], forDocument: newDocRef)
            }
            
            // Creating collections inside the froopDecisions document
            let froopDecisionsDocRef = RefPath.froopDecisionsColRef(uid: uid).document("froopLists")
            batch.setData(["placeholder": "placeholder"], forDocument: froopDecisionsDocRef)
            
            let collectionsInsideFroopLists = ["myArchivedList", "myConfirmedList", "myDeclinedList", "myInvitesList"]
            for collection in collectionsInsideFroopLists {
                let newCollectionRef = froopDecisionsDocRef.collection(collection).document("placeholder")
                batch.setData(["placeholder": "placeholder"], forDocument: newCollectionRef)
            }
            
            // Committing the batch
            batch.commit() { err in
                completion(err)
            }
        }
    }
    
    func getUserFcmToken() -> String? {
        // Check if the user is authenticated
        guard let uid = Auth.auth().currentUser?.uid, !uid.isEmpty else {
            PrintControl.shared.printErrorMessages("User is not authenticated. Unable to retrieve fcmToken.")
            let error = NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "User is not authenticated. Unable to retrieve fcmToken."])
            Crashlytics.crashlytics().record(error: error) // Log error to Crashlytics
            return nil
        }
        
        // Get the FCM token from user defaults
        let fcmToken = UserDefaults.standard.value(forKey: "FCMTokenNotification") as? String
        return fcmToken
    }
    
    //MARK: Logging Google User into Firebase
//    func signInWithGoogle() {
//        PrintControl.shared.printLogin("-LoginView: Function: signInWithGoogle firing")
//        guard let clientID = FirebaseApp.app()?.options.clientID else { return }
//
//        let config = GIDConfiguration(clientID: clientID)
//
//        GIDSignIn.sharedInstance.configuration = config
//
//        GIDSignIn.sharedInstance.signIn(withPresenting: Application_utility.rootViewController) { user, error in
//            if let error = error {
//                PrintControl.shared.printLogin(error.localizedDescription)
//                return
//            }
//
//            guard
//                let user = user?.user,
//                let idToken = user.idToken else { return }
//
//            let accessToken = user.accessToken
//            
//            let credential = GoogleAuthProvider.credential(withIDToken: idToken.tokenString, accessToken: accessToken.tokenString)
//
//            Auth.auth().signIn(with: credential) { [self] res, error in
//                if let error = error {
//                    PrintControl.shared.printErrorMessages(error.localizedDescription)
//                    Crashlytics.crashlytics().record(error: error) // Log error to Crashlytics
//                    return
//                }
//
//                guard res != nil else { return }
//
//                // MARK: User Logged in Successfully
//                PrintControl.shared.printLogin("Success!")
//
//                // Transition to a new view
//                withAnimation(.easeInOut) {
//                    logStatus = true
//                }
//            }
//        }
//    }
}



final class Application_utility {
    static var rootViewController: UIViewController {
        guard let screen = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
            fatalError("Unable to get UIWindowScene")
        }
        
        guard let root = screen.windows.first?.rootViewController else {
            fatalError("Unable to get rootViewController")
        }
        
        return root
    }
}

// MARK: Apple Sign in Helpers
func sha256(_ input: String) -> String {
    print("-LoginViewModel: Function: sha256 firing")
    let inputData = Data(input.utf8)
    let hashedData = SHA256.hash(data: inputData)
    let hashString = hashedData.compactMap {
        return String(format: "%02x", $0)
    }.joined()
    
    return hashString
}

func randomNonceString(length: Int = 32) -> String {
    print("-LoginViewModel: Function randomNonceString firing")
    precondition(length > 0)
    let charset: Array<Character> =
    Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
    var result = ""
    var remainingLength = length
    
    while remainingLength > 0 {
        let randoms: [UInt8] = (0 ..< 16).map { _ in
            var random: UInt8 = 0
            let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
            if errorCode != errSecSuccess {
                fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
            }
            return random
        }
        
        randoms.forEach { random in
            if remainingLength == 0 {
                return
            }
            
            if random < charset.count {
                result.append(charset[Int(random)])
                remainingLength -= 1
            }
        }
    }
    
    return result
}
