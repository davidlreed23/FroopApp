//
//  PhotoPicker.swift
//  FroopProof
//
//  Created by David Reed on 2/3/23.
//

import SwiftUI

struct PhotoPicker: UIViewControllerRepresentable {
  
    
    @Binding var avatarImage: UIImage

    
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        PrintControl.shared.printPhotoPicker("-PhotoPicker: Function: makeUIViewController is firing!")
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.allowsEditing = true
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {
        PrintControl.shared.printPhotoPicker("-PhotoPicker: Function: updateUIViewController is firing!")
    }
    
    func makeCoordinator() -> Coordinator {
        PrintControl.shared.printPhotoPicker("-PhotoPicker: Function: makeCoordinator is firing!")
        return Coordinator(photoPicker: self)
    }
    
    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        
       
        let photoPicker: PhotoPicker
        
        init(photoPicker: PhotoPicker) {
            self.photoPicker = photoPicker
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            PrintControl.shared.printPhotoPicker("-PhotoPicker: Function: imagePickerController is firing!")
            if let image = info[.editedImage] as? UIImage {
                guard let data = image.jpegData(compressionQuality: 0.5), let compressedImage = UIImage(data: data) else {
                    //something
                    return
                }
                photoPicker.avatarImage = compressedImage
            } else {
                //alert user they messed up
            }
            picker.dismiss(animated: true)
        }
    }
}
