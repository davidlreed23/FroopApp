//
//  AlertManager.swift
//  FroopProof
//
//  Created by David Reed on 6/10/23.
//

import SwiftUI

class AlertManager {
    static let shared = AlertManager()

    private init() {}

    func showAlert(message: String) {
        let alert = UIAlertController(title: "Alert", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))

        if let windowScene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
            if let topController = windowScene.windows.first?.rootViewController {
                var presentedController = topController
                while let presented = presentedController.presentedViewController {
                    presentedController = presented
                }
                presentedController.present(alert, animated: true, completion: nil)
            }
        }
    }
}

//MARK: Usage

// place this property in view:

//  @State private var showAlert = false


// Add this gesture code:

//    .onTapGesture {
//        self.showAlert = true  // Update this line
//    }
//    .alert(isPresented: $showAlert) {  // Add this block
//        Alert(title: Text("Alert"), message: Text("This button is not active yet."), dismissButton: .default(Text("OK")))
//    }
