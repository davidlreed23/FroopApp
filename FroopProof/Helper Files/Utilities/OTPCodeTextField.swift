//
//  OTPCodeTextField.swift
//  FroopProof
//
//  Created by David Reed on 4/3/23.
//

//
//  PhoneNumberTextField.swift
//  FroopProof
//
//  Created by David Reed on 4/3/23.
//

import SwiftUI
import UIKit

struct OTPCodeTextField: UIViewRepresentable {
    @Binding var text: String
    var onEditingChanged: (Bool) -> Void = { _ in }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: Context) -> UITextField {
        let textField = UITextField()
        textField.delegate = context.coordinator
        textField.keyboardType = .phonePad
        textField.textColor = .white
        textField.font = UIFont.systemFont(ofSize: 24, weight: .thin)
        textField.clearButtonMode = .whileEditing
        textField.attributedPlaceholder = NSAttributedString(string: "000000", attributes: [NSAttributedString.Key.foregroundColor: UIColor.white.withAlphaComponent(0.5)])
        textField.addTarget(context.coordinator, action: #selector(Coordinator.textFieldDidChange), for: .editingChanged)
        textField.textAlignment = .center
        
        return textField
    }
    
    func updateUIView(_ textField: UITextField, context: Context) {
        textField.text = text
    }
    
    class Coordinator: NSObject, UITextFieldDelegate {
        var parent: OTPCodeTextField // This line was changed
        
        init(_ parent: OTPCodeTextField) { // This line was added
            self.parent = parent
        }
        
        @objc func textFieldDidChange(_ textField: UITextField) {
            guard let text = textField.text else { return }
            parent.text = (text)
        }
        
        func textFieldDidBeginEditing(_ textField: UITextField) {
            parent.onEditingChanged(true)
        }
        
        func textFieldDidEndEditing(_ textField: UITextField) {
            parent.onEditingChanged(false)
        }
    }
}
