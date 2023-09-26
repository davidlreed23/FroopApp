//
//  Login2.swift
//  FroopProof
//
//  Created by David Reed on 4/1/23.
//

import SwiftUI
import UIKit
import MapKit
import AuthenticationServices
import GoogleSignIn
import GoogleSignInSwift
import Firebase



struct Login: View {
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject var printControl = PrintControl.shared
    
    @StateObject var loginModel: LoginViewModel = .init()
    @State var isKeyboardOpen = false
    @State var isFocused: Bool = false
    @FocusState private var focusedField: FocusField?
    @State var keyboardOff = false
    @State var isKeyboardVisible = false
    
    
    
    enum FocusField: Hashable {
        case phoneNumberTextField
        case none
    }
    
    var body: some View {
        BackgroundView(isKeyboardOpen: $isKeyboardOpen, isKeyboardVisible: $isKeyboardVisible) {
            VStack {
                WelcomeText(isKeyboardVisible: $isKeyboardVisible)
                SignInButton(loginModel: loginModel)
            }
            .ignoresSafeArea(.keyboard)
            .offset(y: isKeyboardVisible ? 150 : 0)
            .animation(.easeInOut(duration: 0.3), value: isKeyboardVisible)
        }
    }
}

struct BackgroundView<Content: View>: View {
    let content: Content
    @Binding var isKeyboardOpen: Bool
    @Binding var isKeyboardVisible: Bool

    init(isKeyboardOpen: Binding<Bool>, isKeyboardVisible: Binding<Bool>, @ViewBuilder content: () -> Content) {
        self._isKeyboardOpen = isKeyboardOpen
        self._isKeyboardVisible = isKeyboardVisible
        self.content = content()
    }

    var body: some View {
        ZStack (alignment: .top) {
            ZStack {
                Image("Background_Froop")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .edgesIgnoringSafeArea(.all)
                    .ignoresSafeArea()
                    .frame(alignment: .center)
                Rectangle()
                    .foregroundColor(.black)
                    .opacity(0.5)
                    .frame(minWidth: 0,maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                    .edgesIgnoringSafeArea(.all)
                    .ignoresSafeArea()
                    .gesture(
                        TapGesture()
                            .onEnded {
                                isKeyboardOpen = false
                                isKeyboardVisible = false
                            }
                    )
            }
            content
        }
    }
}

struct WelcomeText: View {
    @Environment(\.colorScheme) var colorScheme
    @Binding var isKeyboardVisible: Bool
    
    var body: some View {
        VStack {
            Image("froopWhiteIcon")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: isKeyboardVisible ? 50 : 100, alignment: .center)
                .animation(.easeInOut(duration: 0.3), value: isKeyboardVisible)
            
            Text("Welcome to")
                .foregroundColor(colorScheme == .dark ? .white : .white)
                .font(.system(size: 42))
                .fontWeight(.light)
                .lineSpacing(5)
                .multilineTextAlignment(.center)
                .padding(.top, 25)
                .frame(width: 300, height: 40)
                .animation(.easeInOut(duration: 0.3), value: isKeyboardVisible)
            
            Text("Froop!")
                .foregroundColor(colorScheme == .dark ? .white : .white)
                .font(.system(size: 42))
                .fontWeight(.light)
                .lineSpacing(5)
                .multilineTextAlignment(.center)
                .padding(.top, 15)
                .frame(width: 300, height: 40)
                .animation(.easeInOut(duration: 0.3), value: isKeyboardVisible)
            
            (Text("Do Anything, with Anyone,")
                .foregroundColor(colorScheme == .dark ? .white : .white) +
             Text("\nAnywhere" )
                .foregroundColor(colorScheme == .dark ? .white : .white)
            )
            .font(.system(size: 18))
            .fontWeight(.light)
            .multilineTextAlignment(.center)
            .padding(.top, 25)
        }
        .padding(.top,  UIScreen.screenHeight * 0.075)
    }
}

struct SignInButton: View {
    @ObservedObject var loginModel: LoginViewModel
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .center){
            Spacer()
            // MARK: Custom Apple Sign in Button
            CustomButton()
                .overlay {
                    SignInWithAppleButton { (request) in
                        loginModel.nonce = randomNonceString()
                        request.requestedScopes = [.email,.fullName]
                        request.nonce = sha256(loginModel.nonce)
                        
                    } onCompletion: { (result) in
                        switch result{
                        case .success(let user):
                            PrintControl.shared.printLogin("success")
                            guard let credential = user.credential as? ASAuthorizationAppleIDCredential else{
                                PrintControl.shared.printLogin("error with firebase")
                                return
                            }
                            loginModel.appleAuthenticate(credential: credential)
                        case.failure(let error):
                            print(error.localizedDescription)
                        }
                    }
                    .signInWithAppleButtonStyle(.white)
                    .frame(height: 55)
                    .foregroundColor(colorScheme == .dark ? .white : .white)
                }
                .clipped()
            Spacer()
        }
        .padding(.bottom, UIScreen.screenHeight * 0.1)
    }
}

struct CustomButton: View {
    @Environment(\.colorScheme) var colorScheme
    var body: some View {
        HStack{
            Image(systemName: "applelogo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 25, height: 25)
                .frame(height: 45)
            
            Text("Apple Sign in")
                .font(.callout)
                .lineLimit(1)
        }
        .foregroundColor(colorScheme == .dark ? .white : .white)
        .padding(.horizontal,15)
        .background {
            RoundedRectangle(cornerRadius: 0, style: .continuous)
                .fill(.black)
                .opacity(0.5)
        }
        .border(Color.white, width: 0.25)
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }
}


