//
//  ContactPicker.swift
//  FroopProof
//
//  Created by David Reed on 4/5/23.
//

import SwiftUI
import Contacts
import Combine
import Foundation
import ContactsUI

struct ContactPicker: UIViewControllerRepresentable {
    
    @ObservedObject var appStateManager = AppStateManager.shared
    @ObservedObject var printControl = PrintControl.shared
    @ObservedObject var locationServices = LocationServices.shared
    @ObservedObject var froopDataListener = FroopDataListener.shared
 
    
    typealias UIViewControllerType = EmbeddedContactPickerViewController
    @Environment(\.presentationMode) var presentationMode
    
    @Binding var selectedContact: HashableCNContact?
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }
    
    final class Coordinator: NSObject, EmbeddedContactPickerViewControllerDelegate {
        let parent: ContactPicker
        @Environment(\.presentationMode) var presentationMode

        init(_ parent: ContactPicker) {
            self.parent = parent
        }
        
        func embeddedContactPickerViewController(_ viewController: EmbeddedContactPickerViewController, didSelect contact: CNContact) {
            parent.selectedContact = HashableCNContact(contact: contact)
            viewController.dismiss(animated: true, completion: nil)
        }

        func embeddedContactPickerViewControllerDidCancel(_ viewController: EmbeddedContactPickerViewController) {
            presentationMode.wrappedValue.dismiss()
            print("Cancelled")
        }
    }

    func makeUIViewController(context: UIViewControllerRepresentableContext<ContactPicker>) -> ContactPicker.UIViewControllerType {
        let result = ContactPicker.UIViewControllerType()
        result.delegate = context.coordinator
        result.selectedContact = selectedContact
        return result
    }

    func updateUIViewController(_ uiViewController: EmbeddedContactPickerViewController, context: Context) {
        // Removed the assignment of predicateForEnablingContact
    }
}


class EmbeddedContactPickerViewController: UIViewController, CNContactPickerDelegate {
    weak var delegate: EmbeddedContactPickerViewControllerDelegate?
    var selectedContact: HashableCNContact?

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.open(selectedContact: selectedContact, animated: animated)
    }
    
    private func open(selectedContact: HashableCNContact?, animated: Bool) {
        let viewController = CNContactPickerViewController()
        viewController.delegate = self
        self.present(viewController, animated: false)
    }
    
    func contactPickerDidCancel(_ picker: CNContactPickerViewController) {
        self.dismiss(animated: false) {
            self.delegate?.embeddedContactPickerViewControllerDidCancel(self)
        }
    }

    func contactPicker(_ picker: CNContactPickerViewController, didSelect contact: CNContact) {
        self.dismiss(animated: false) {
            self.delegate?.embeddedContactPickerViewController(self, didSelect: contact)
        }
    }
}
