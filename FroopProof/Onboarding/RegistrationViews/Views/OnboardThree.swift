//
//  OnboardTwo.swift
//  FroopProof
//
//  Created by David Reed on 9/21/23.
//

//
//  OnboardOne.swift
//  Design_Layouts
//
//  Created by David Reed on 9/21/23.
//

import SwiftUI
import MapKit
import Firebase
import FirebaseStorage
import Kingfisher

struct OnboardThree: View {
    @ObservedObject var myData = MyData.shared
    @State var phoneNumber: String = ""
    @State var OTPCode: String = ""
    @State private var OTPSent: Bool = false
    @State private var isKeyboardShown: Bool = false
    @State private var keyboardHeight: CGFloat = 0
    @State private var isShowingOTPAlert = false
    @State private var formattedPhoneNumber: String = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var enteredOTP: String = ""
    @State private var OTPVerified: Bool = false
    @Binding var selectedTab: OnboardingTab

    var otpAlert: Alert {
        Alert(title: Text("Enter OTP"),
              message: Text("Please enter the received OTP code:"),
              primaryButton: .default(Text("Verify"), action: {
            verifyOTP(enteredOTP: enteredOTP)
        }),
              secondaryButton: .cancel()
        )
    }
    
    @AppStorage("ProfileCompletionCurrentPage") var ProfileCompletionCurrentPage = 4
    
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
            .onAppear {
                formattedPhoneNumber = formatPhoneNumber(myData.phoneNumber)
                //                if myData.phoneNumber != "" {
                //                    ProfileCompletionCurrentPage = 2
                //                }
            }
            
            VStack {
                Text("VERIFY YOUR MOBILE NUMBER")
                    .font(.system(size: 18))
                    .fontWeight(.semibold)
                    .foregroundColor(Color(red: 249/255, green: 0/255, blue: 98/255))
                    .padding(.top, UIScreen.main.bounds.height / 2 + 10)
                
                Text("Your Mobile Number serves as your 2 factor authentication. ")
                    .font(.system(size: 24))
                    .fontWeight(.light)
                    .foregroundColor(.black)
                    .opacity(/*@START_MENU_TOKEN@*/0.8/*@END_MENU_TOKEN@*/)
                    .padding(.leading, 35)
                    .padding(.trailing, 35)
                    .padding(.top, 25)
                    .multilineTextAlignment(.center)
                
                Text("It is also how users on the platform can look you up or send out invitations.")
                    .font(.system(size: 24))
                    .fontWeight(.light)
                    .foregroundColor(.black)
                    .opacity(0.8)
                    .padding(.leading, 35)
                    .padding(.trailing, 35)
                    .padding(.top, 25)
                    .multilineTextAlignment(.center)
                Spacer()
            }
            VStack (spacing: 40){
                VStack {
                    VStack (alignment: .leading){
                        Text("PHONE NUMBER")
                            .font(.system(size: 14))
                            .fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/)
                            .foregroundColor(.black)
                            .opacity(0.25)
                            .offset(y: 8)
                        
                        TextField("(123) 456-7890", text: $formattedPhoneNumber)
                            .keyboardType(.numberPad)
                            .font(.system(size: 30))
                            .fontWeight(.thin)
                            .padding(.leading, 15)
                            .padding(.top, 2)
                            .padding(.bottom, 2)
                            .padding(.trailing, 10)
                            .background(.white)
                            .border(.gray, width: 0.25)
                            .keyboardType(.numberPad)
                        
                            .onChange(of: formattedPhoneNumber) { oldValue, newValue in
                                formattedPhoneNumber = newValue.formattedPhoneNumber
                                myData.phoneNumber = removePhoneNumberFormatting(newValue)
                            }
                    }
                    
                    Button {
                        if isValidPhoneNumber(formattedPhoneNumber) {
                            sendOTP(phoneNumber: formattedPhoneNumber)
                           

                        } else {
                            showAlert = true
                        }
                    } label: {
                        HStack {
                            Spacer()
                            ZStack {
                                RoundedRectangle(cornerRadius: 10)
                                    .frame(width: 100, height: 35)
                                    .foregroundColor(Color(red: 249/255, green: 0/255, blue: 98/255))
                                Text(OTPSent ? "Resend" : "Get Code")
                                    .font(.system(size: 18))
                                    .fontWeight(.regular)
                                    .foregroundColor(.white)
                            }
                            .opacity(myData.OTPVerified ? 0 : 1)
                        }
                    }
                    
                }
                
                VStack {
                    ZStack {
                        VStack (alignment: .leading){
                            Text("VERIFICATION CODE")
                                .font(.system(size: 14))
                                .fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/)
                                .foregroundColor(.black)
                                .opacity(0.25)
                                .offset(y: 8)
                            
                            TextField(
                                myData.OTPVerified ? "Verification Confirmed." :
                                (OTPVerified ? "Verification Confirmed." : "Enter OTP Code Here."),
                                text: $OTPCode
                            )
                                .font(.system(size: 30))
                                .fontWeight(.thin)
                                .padding(.leading, 15)
                                .padding(.top, 2)
                                .padding(.bottom, 2)
                                .padding(.trailing, 10)
                                .background(.white)
                                .border(.gray, width: 0.25)
                        }
                        .opacity(myData.OTPVerified ? 1 : OTPSent ? 0.0 : 0.25)
                        
                        
                        VStack {
                            VStack (alignment: .leading){
                                Text("VERIFICATION CODE")
                                    .font(.system(size: 14))
                                    .fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/)
                                    .foregroundColor(.black)
                                    .opacity(0.25)
                                    .offset(y: 8)
                                
                                TextField(
                                    myData.OTPVerified ? "Verification Confirmed." :
                                    (OTPVerified ? "Already Verified." : "Enter OTP Code Here."),
                                    text: $OTPCode
                                )
                                .font(.system(size: 30))
                                .fontWeight(.thin)
                                .padding(.leading, 15)
                                .padding(.top, 2)
                                .padding(.bottom, 2)
                                .padding(.trailing, 10)
                                .background(.white)
                                .border(.gray, width: 0.25)
                                
                            }
                            .opacity(OTPSent ? 1.0 : 0.0)
                        }
                    }
                    Button () {
                        
                    } label: {
                        HStack {
                            Spacer()
                            Button {
                                if myData.OTPVerified {
                                    selectedTab = .fourth
                                } else {
                                    if OTPVerified {
                                        selectedTab = .fourth
                                    } else {
                                        verifyOTP(enteredOTP: OTPCode)
                                    }
                                }
                            } label: {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 10)
                                        .frame(width: 75, height: 35)
                                        .foregroundColor(Color(red: 249/255, green: 0/255, blue: 98/255))
                                    Text(myData.OTPVerified ? "Next" : (OTPVerified ? "Verify" : "Save"))
                                        .font(.system(size: 18))
                                        .fontWeight(.regular)
                                        .foregroundColor(.white)
                                }
                            }
                        }
                    }
                    
                    
                }
                Spacer()
            }
            .frame(width: UIScreen.main.bounds.width - 100)
            .padding(.top, 120)
            
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Phone Number is invalid, please enter a valid phone number."),
                  message: Text(alertMessage),
                  dismissButton: .default(Text("OK")))
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
    
    func sendOTP(phoneNumber: String) {
        // Remove non-numeric characters
        let cleanedPhoneNumber = phoneNumber.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        
        // Prepend the country code to get it in E.164 format. Assume 1 as the country code for the USA.
        let e164FormattedNumber = "+1" + cleanedPhoneNumber
        
        PhoneAuthProvider.provider().verifyPhoneNumber(e164FormattedNumber, uiDelegate: nil) { (verificationID, error) in
            if let error = error {
                // Handle the error
                print(error.localizedDescription)
                return
            }
            // If there's no error, save the verificationID
            UserDefaults.standard.set(verificationID, forKey: "authVerificationID")
            OTPSent = true
            isShowingOTPAlert = true
        }
    }
    
    func verifyOTP(enteredOTP: String) {
        guard let verificationID = UserDefaults.standard.string(forKey: "authVerificationID") else { return }
        let credential = PhoneAuthProvider.provider().credential(withVerificationID: verificationID, verificationCode: enteredOTP)
        
        Auth.auth().signIn(with: credential) { (authResult, error) in
            if let error = error {
                // Handle the error
                print(error.localizedDescription)
                return
            }
            OTPVerified = true
            myData.OTPVerified = true
            OTPCode = "Verification Confirmed."
        }
    }
    
    func removePhoneNumberFormatting(_ phoneNumber: String) -> String {
        let cleanedPhoneNumber = phoneNumber.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        return cleanedPhoneNumber
    }
    
    func formatPhoneNumber(_ phoneNumber: String) -> String {
        let cleanedPhoneNumber = phoneNumber.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        let mask = "(XXX) XXX-XXXX"
        var result = ""
        var index = cleanedPhoneNumber.startIndex
        for ch in mask where index < cleanedPhoneNumber.endIndex {
            if ch == "X" {
                result.append(cleanedPhoneNumber[index])
                index = cleanedPhoneNumber.index(after: index)
            } else {
                result.append(ch)
            }
        }
        return result
    }
    
    func isValidPhoneNumber(_ phoneNumber: String) -> Bool {
        PrintControl.shared.printLogin("-Login: Function: isValidPhoneNumber firing")
        
        // Strip out non-numeric characters
        let numericOnlyString = phoneNumber.filter { $0.isNumber }
        
        // Ensure there are exactly 10 digits
        guard numericOnlyString.count == 10 else {
            return false
        }
        
        // Now, verify if the input format matches any of the desired formats
        let phoneNumberPatterns = [
            "^\\(\\d{3}\\) \\d{3}-\\d{4}$",  // (123) 999-9999
            "^\\d{10}$",                    // 1239999999
            "^\\d{3}\\.\\d{3}\\.\\d{4}$",  // 123.999.9999
            "^\\d{3} \\d{3} \\d{4}$"       // 123 999 9999
        ]
        
        return phoneNumberPatterns.contains { pattern in
            let predicate = NSPredicate(format: "SELF MATCHES %@", pattern)
            return predicate.evaluate(with: phoneNumber)
        }
    }
}

