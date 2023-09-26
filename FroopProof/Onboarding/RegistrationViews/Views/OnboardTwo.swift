//
//  OnboardOne.swift
//  Design_Layouts
//
//  Created by David Reed on 9/21/23.
//

import SwiftUI

struct OnboardTwo: View {
    @ObservedObject var myData = MyData.shared
    @State var firstName: String = ""
    @State var lastName: String = ""
    @State private var isKeyboardShown: Bool = false
    @State private var keyboardHeight: CGFloat = 0
    @Binding var selectedTab: OnboardingTab

    let imageW: Font.Weight = .thin
    let fontS = Font.system(size: 35)
    var body: some View {
        ZStack {
            VStack {
                
                Rectangle()
                    .fill(Color(red: 235/255, green: 235/255, blue: 250/255))
                    .frame(height: UIScreen.main.bounds.height / 2)
                Spacer()
            }

            VStack {
                Text("LET'S CREATE YOUR PROFILE")
                    .font(.system(size: 18))
                    .fontWeight(.semibold)
                    .foregroundColor(Color(red: 249/255, green: 0/255, blue: 98/255))
                    .padding(.top, UIScreen.main.bounds.height / 2 + 10)
                
                Text("Your information is private, and can only be seen by friends you choose to share your information with.")
                    .font(.system(size: 24))
                    .fontWeight(.light)
                    .foregroundColor(.black)
                    .opacity(/*@START_MENU_TOKEN@*/0.8/*@END_MENU_TOKEN@*/)
                    .padding(.leading, 35)
                    .padding(.trailing, 35)
                    .padding(.top, 25)
                    .multilineTextAlignment(.center)
                
                Spacer()
            }

            VStack (spacing: 25){
                VStack (alignment: .leading){
                    Text("FIRST NAME")
                        .font(.system(size: 14))
                        .fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/)
                        .foregroundColor(.black)
                        .opacity(0.25)
                        .offset(y: 8)
                    
                    TextField("Jane", text: $myData.firstName)
                        .font(.system(size: 30))
                        .fontWeight(.thin)
                        .padding(.leading, 15)
                        .padding(.top, 2)
                        .padding(.bottom, 2)
                        .padding(.trailing, 10)
                        .background(.white)
                        .border(.gray, width: 0.25)
                }
                VStack (alignment: .leading){
                    Text("LAST NAME")
                        .font(.system(size: 14))
                        .fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/)
                        .foregroundColor(.black)
                        .opacity(0.25)
                        .offset(y: 8)
                    
                    TextField("Doe", text: $myData.lastName)
                        .font(.system(size: 30))
                        .fontWeight(.thin)
                        .padding(.leading, 15)
                        .padding(.top, 2)
                        .padding(.bottom, 2)
                        .padding(.trailing, 10)
                        .background(.white)
                        .border(.gray, width: 0.25)
                    
                }
                
                
                Button () {
                    
                } label: {
                    HStack {
                        Spacer()
                        Button {
                            selectedTab = .third
                        } label: {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10)
                                    .frame(width: 75, height: 35)
                                    .foregroundColor(Color(red: 249/255, green: 0/255, blue: 98/255))
                                Text("Save")
                                    .font(.system(size: 18))
                                    .fontWeight(.regular)
                                    .foregroundColor(.white)
                            }
                        }
                    }
                }
                Spacer()
            }
            .ignoresSafeArea(.keyboard)
            .frame(width: UIScreen.main.bounds.width - 100)
            .padding(.top, 120)
            
        }
        .onReceive(
            NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)
                .merge(
                    with: NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)
                )
        ) { notification in
            guard let userInfo = notification.userInfo else { return }
            
            let endFrame = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue
            
            let duration = (userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue ?? 0.0
            
            withAnimation(.easeInOut(duration: duration)) {
                if notification.name == UIResponder.keyboardWillShowNotification {
                    keyboardHeight = endFrame?.height ?? 0
                } else {
                    keyboardHeight = 0
                }
            }
        }
        //.offset(y: isKeyboardShown ? 0 : keyboardHeight / 2)
        .ignoresSafeArea()
    }
}

