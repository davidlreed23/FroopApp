//
//  CustomTextField.swift
//  FroopProof
//
//  Created by David Reed on 1/18/23.
//
import SwiftUI

struct CustomTextField: View {
    var hint: String
    @Binding var keyboardOff: Bool
    @Binding var text: String
    @Binding var isKeyboardVisible: Bool
    
    enum FocusField: Hashable {
        case field
        case nofield
    }
    
    @FocusState private var focusedField: FocusField?
    
    var body: some View {
        ZStack(alignment: .center) {
            VStack {
                Spacer()
                PhoneNumberTextField(text: $text) { isEditing in
                    isKeyboardVisible = isEditing
                }
                .frame(width: 300, height: 40)
                .focused($focusedField, equals: .field)
                Spacer()
            }
        }
        .onChange(of: keyboardOff, initial: !keyboardOff) { oldValue, newValue in
            if newValue {
                isKeyboardVisible = false
                focusedField = .nofield
                hideKeyboard()
            }
        }

    }
    
    private func hideKeyboard() {
        PrintControl.shared.printLogin("-CustomTextField: Function: hideKeyboard firing")
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}


