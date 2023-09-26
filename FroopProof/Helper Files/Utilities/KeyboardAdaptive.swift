//
//  KeyboardAdaptive.swift
//  FroopProof
//
//  Created by David Reed on 4/1/23.
//

import SwiftUI

struct KeyboardAdaptive: ViewModifier {
    @State private var bottomPadding: CGFloat = 0

    func body(content: Content) -> some View {
        GeometryReader { geometry in
            content
                .padding(.bottom, self.bottomPadding)
                .onAppear {
                    NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: .main) { notification in
                        guard let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else { return }
                        let keyboardTop = keyboardSize.origin.y
                        let padding = geometry.frame(in: .global).maxY - keyboardTop
                        self.bottomPadding = max(0, padding)
                    }

                    NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: .main) { _ in
                        self.bottomPadding = 0
                    }
                }
        }
    }
}
