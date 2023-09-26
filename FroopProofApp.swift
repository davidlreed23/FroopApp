//
//  FroopProofApp.swift
//  FroopProof
//
//  Created by David Reed on 1/18/23.
//

import Foundation
import UIKit
import SwiftUI
import Firebase
import FirebaseFirestore
import FirebaseStorage
import GoogleSignIn
import UserNotifications
import FirebaseCrashlytics
import FirebaseMessaging
import UserNotifications


class AppDelegate: NSObject, ObservableObject, UIApplicationDelegate, UNUserNotificationCenterDelegate, FroopNotificationDelegate, MessagingDelegate {
    
    static private(set) var instance: AppDelegate! = nil
    
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        FirebaseApp.configure()
        Messaging.messaging().delegate = self
        
        Crashlytics.crashlytics().setCrashlyticsCollectionEnabled(true)
        
        PrintControl.shared.printAppDelegate("-AppDelegate: Function: application2 firing")
        // Request user authorization for notifications
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                PrintControl.shared.printErrorMessages("Failed to request authorization for remote notifications with error: \(error.localizedDescription)")
                Crashlytics.crashlytics().record(error: error) // Log error to Crashlytics
            } else if granted {
                DispatchQueue.main.async {
                    application.registerForRemoteNotifications()
                }
            } else {
                let error = NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "User denied notification permissions."])
                Crashlytics.crashlytics().record(error: error) // Log error to Crashlytics
            }
        }
        
        UIApplication.shared.registerForRemoteNotifications()
        
        
        FirebaseServices.requestBadgePermission { granted in
            if granted {
                PrintControl.shared.printNotifications("Badge permission granted")
            } else {
                PrintControl.shared.printNotifications("Badge permission denied")
            }
        }
        saveUserFcmToken()
        return true
    }
    
    //MARK: Reset Badge Count
    func applicationDidBecomeActive(_ application: UIApplication) {
        PrintControl.shared.printNotifications("--> applicatoinDidBecomeActive firing")
        
        // Reset application badge count
        UNUserNotificationCenter.current().setBadgeCount(0) { error in
            if let error = error {
                PrintControl.shared.printNotifications("Error setting badge count: \(error)")
            } else {
                PrintControl.shared.printNotifications("--> application.applicationsIconBadgeNumber = 0 is firing")
                PrintControl.shared.printNotifications("badge number is now reset to 0")
            }
        }

        UserDefaults.standard.set(0, forKey: "badgeCount")
        
        // Assuming you have a reference to the currently logged in user's Firestore document
        let db = Firestore.firestore()
        if let user = Auth.auth().currentUser {
            db.collection("users").document(user.uid).updateData([
                "badgeCount": 0
            ]) { err in
                if let err = err {
                    PrintControl.shared.printNotifications("Error updating document: \(err)")
                } else {
                    PrintControl.shared.printNotifications("Document successfully updated")
                }
            }
        }
    }
    
    
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let fcmToken = fcmToken else { return }
        print(">> FCM TOKEN:", fcmToken)
        let dataDict: [String: String] = ["fcmToken": fcmToken]
        NotificationCenter.default.post(name: Notification.Name("FCMTokenNotification"), object: fcmToken, userInfo: dataDict)
        UserDefaults.standard.set(fcmToken, forKey: "fcmToken")
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        PrintControl.shared.printAppDelegate("-function application firing")
        UNUserNotificationCenter.current().delegate = self
        
        Messaging.messaging().apnsToken = deviceToken
        // Get FCM token
        Messaging.messaging().token { fcmToken, error in
            if let error = error {
                PrintControl.shared.printErrorMessages("Error fetching FCM registration token: \(error)")
                Crashlytics.crashlytics().record(error: error) // Log error to Crashlytics
            } else if let fcmToken = fcmToken {
                PrintControl.shared.printAppDelegate("FCM registration token: \(fcmToken)")
                
                // Save the fcmToken to the user's profile
                let db = Firestore.firestore()
                
                // Check if the user is authenticated
                if let uid = Auth.auth().currentUser?.uid, !uid.isEmpty {
                    let docRef = db.collection("users").document(uid)
                    
                    // Update the user document with the fcmToken
                    docRef.updateData(["fcmToken": fcmToken]) { error in
                        if let error = error {
                            PrintControl.shared.printErrorMessages("Error updating user document with fcmToken: \(error)")
                            Crashlytics.crashlytics().record(error: error) // Log error to Crashlytics
                        } else {
                            PrintControl.shared.printAppDelegate("fcmToken saved to user document successfully")
                        }
                    }
                } else {
                    PrintControl.shared.printErrorMessages("User is not authenticated. fcmToken not saved to user document.")
                    let error = NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "User is not authenticated. fcmToken not saved to user document."])
                    Crashlytics.crashlytics().record(error: error) // Log error to Crashlytics
                }
            }
        }
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification notification: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        PrintControl.shared.printAppDelegate("-function application firing")
        PrintControl.shared.printAppDelegate("\(#function)")
        if Auth.auth().canHandleNotification(notification) {
            completionHandler(.noData)
            return
        }
        
        // Handle your custom navigation here
        if let data = notification["data"] as? [String: Any] {
            if let selectedTab = data["selectedTab"] as? String,
               let selectedFroopTabString = data["selectedFroopTab"] as? String,
               let selectedFroopTabInt = Int(selectedFroopTabString) {
                LocationServices.shared.selectedTab = Tab(rawValue: selectedTab) ?? .froop
                LocationServices.shared.selectedFroopTab = FroopTab(rawValue: selectedFroopTabInt) ?? .map
            }
        }
        
        completionHandler(.newData)
    }
    
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        PrintControl.shared.printAppDelegate("-AppDelegate: Function: application1 firing")
        PrintControl.shared.printErrorMessages("Failed to register for remote notifications with error: \(error.localizedDescription)")
    }
    
    // MARK: - FroopNotificationDelegate
    func froopParticipantsChanged(_ froop: Froop) {
        PrintControl.shared.printAppDelegate("-AppDelegate: Function: froopParticipantsChanged is firing")
        // Handle participants change event
    }
    
    func froopStatusChanged(_ froop: Froop) {
        // Handle status change event
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        PrintControl.shared.printAppDelegate("-AppDelegate: Function: userNotificationCenter firing")
        let userInfo = response.notification.request.content.userInfo
        let notificationIdentifier = response.notification.request.identifier
        
        // Check if the notification is the location tracking notification
        if notificationIdentifier == "LocationTrackingNotification" {
            // Present the alert asking for location sharing permission
            DispatchQueue.main.async {
                guard let window = self.window,
                      let rootViewController = window.rootViewController
                else {
                    completionHandler()
                    return
                }
                
                let alertController = UIAlertController(title: "Share Your Location", message: "Would you like to share your location to receive accurate arrival time notifications?", preferredStyle: .alert)
                alertController.addAction(UIAlertAction(title: "Share Location", style: .default, handler: { _ in
                    // Enable location sharing and start tracking
                    // ...
                }))
                alertController.addAction(UIAlertAction(title: "Not Now", style: .cancel, handler: nil))
                
                rootViewController.present(alertController, animated: true, completion: nil)
            }
        }
        
        // Check if the notification is related to user arrival
        if notificationIdentifier == "UserArrivalNotification" {
            // Extract relevant information from the notification payload
            let arrivedUserName = userInfo["arrivedUserName"] as? String ?? "Unknown user"
            let froopName = userInfo["froopName"] as? String ?? "Unknown Froop event"
            
            // Display an alert or update the UI with the arrival information
            DispatchQueue.main.async {
                guard let window = self.window,
                      let rootViewController = window.rootViewController
                else {
                    completionHandler()
                    return
                }
                
                let alertController = UIAlertController(title: "User Arrived", message: "\(arrivedUserName) has arrived at \(froopName).", preferredStyle: .alert)
                alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                
                rootViewController.present(alertController, animated: true, completion: nil)
            }
        }
        
        
        completionHandler()
    }
    
    
    
    @available(iOS 9.0, *)
    func application(_ application: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        PrintControl.shared.printAppDelegate("-AppDelegate: Function: application3 firing")
        if !GIDSignIn.sharedInstance.handle(url) {
            let error = NSError(domain: "", code: 0,userInfo: [NSLocalizedDescriptionKey: "Google sign-in failed or was cancelled by the user."])
            Crashlytics.crashlytics().record(error: error) // Log error to Crashlytics
            return false
        }
        return true
    }
    
    func saveUserFcmToken() {
        // Check if the user is authenticated
        guard let uid = Auth.auth().currentUser?.uid, !uid.isEmpty else {
            PrintControl.shared.printErrorMessages("User is not authenticated. fcmToken not saved to user document.")
            let error = NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "User is not authenticated. fcmToken not saved to user document."])
            Crashlytics.crashlytics().record(error: error) // Log error to Crashlytics
            return
        }
        
        // Get the FCM token form user defaults
        guard let fcmToken = UserDefaults.standard.value(forKey: "FCMTokenNotification") else {
            return
        }
        
        let db = Firestore.firestore()
        let docRef = db.collection("users").document(uid)
        
        // Update the user document with the fcmToken
        docRef.updateData(["fcmToken": fcmToken]) { error in
            if let error = error {
                PrintControl.shared.printErrorMessages("Error updating user document with fcmToken: \(error)")
                Crashlytics.crashlytics().record(error: error) // Log error to Crashlytics
            } else {
                PrintControl.shared.printAppDelegate("fcmToken saved to user document successfully")
            }
        }
    }
}

@main
struct MyApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject var authState = AuthState()
    @StateObject var myData = MyData.shared
    @Environment(\.scenePhase) var scenePhase
    
    var body: some Scene {
        WindowGroup {
            if authState.isFirebaseAuthDone {
                if authState.isAuthenticated {
                    RootView(friendData: UserData(), photoData: PhotoData(), appDelegate: AppDelegate(), confirmedFroopsList: ConfirmedFroopsList())
                        .environmentObject(authState)
                        .onAppear { print("LOADING ROOT VIEW") }
                } else {
                    Login().environmentObject(authState)
                }
            } else {
                Text("Authenticating...")
            }
        }
    }
}



class AuthState: ObservableObject {
    @Published var isAuthenticated = false
    @Published var isFirebaseAuthDone: Bool = false
    @ObservedObject var myData = MyData.shared
    private var authHandle: AuthStateDidChangeListenerHandle?
    
    init() {
        authHandle = Auth.auth().addStateDidChangeListener { (auth, user) in
            self.isFirebaseAuthDone = true

            if let user = user, !user.uid.isEmpty {
                self.isAuthenticated = true
            } else {
                self.isAuthenticated = false
                let error = NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "User became unauthenticated or UID is missing."])
                Crashlytics.crashlytics().record(error: error)
            }
        }
    }
    
    func signOut() {
        PrintControl.shared.printStartUp("-AuthState: Function: signOut firing")
        let firebaseAuth = Auth.auth()
        do {
            try firebaseAuth.signOut()
            if let uid = firebaseAuth.currentUser?.uid, !uid.isEmpty {
                // Perform Firestore operations here with the non-empty user ID.
            } else {
                PrintControl.shared.printErrorMessages("User ID is empty or nil.")
                let error = NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "User ID is empty or nil."])
                Crashlytics.crashlytics().record(error: error) // Log error to Crashlytics
            }
        } catch let signOutError as NSError {
            print("Error signing out: %@", signOutError)
            Crashlytics.crashlytics().record(error: signOutError) // Log error to Crashlytics
        }
    }
    
    deinit {
        if let handle = authHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }
}


class VersionChecker: ObservableObject {
    static let shared = VersionChecker()
    @Published var versionCheck: Int = 0
    @Published var isLoadingVersion: Bool = true
    @Published var version = 17
    
    init() {
        checkVersion { [weak self] fetchedVersion in
            if let version = fetchedVersion {
                DispatchQueue.main.async {
                    self?.versionCheck = version
                    self?.isLoadingVersion = false
                }
            }
        }
    }
    
    func checkVersion(completion: @escaping (Int?) -> Void) {
        let docRef = Firestore.firestore().collection("versionControl").document("versionId")
            
        docRef.getDocument { (document, error) in
            if let error = error {
                print("Error fetching version: \(error.localizedDescription)")
                completion(nil)
            } else if let document = document, document.exists {
                let version = document.data()?["currentVersion"] as? Int
                print("Successfully fetched version: \(String(describing: version))") // Debug print
                completion(version)
            } else {
                print("Document does not exist")
                completion(nil)
            }
        }
    }
}
