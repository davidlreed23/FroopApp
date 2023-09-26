//
//  CustomTextFieldOTP.swift
//  FroopProof
//
//  Created by David Reed on 2/14/23.
//

import SwiftUI

struct CustomTextFieldOTP: View {
    var hint: String
    @Binding var text: String
    @Binding var isKeyboardOpen: Bool
    
    enum FocusField: Hashable {
        case field
        case nofield
    }
    
    @FocusState private var focusedField: FocusField?
    
    var body: some View {
        ZStack(alignment: .center) {
            VStack {
                Spacer()
                OTPCodeTextField(text: $text) { isEditing in
                    isKeyboardOpen = isEditing
                }
                .frame(width: 300, height: 40)
                .focused($focusedField, equals: .field)
                Spacer()
            }
        }
        .onChange(of: isKeyboardOpen, initial: isKeyboardOpen) { oldValue, newValue in
            if !newValue {
                focusedField = .nofield
                hideKeyboard()
            }
        }

    }
    
    private func hideKeyboard() {
        PrintControl.shared.printLogin("-CustomTextFieldOTP: Function: hideKeyboard firing")
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
