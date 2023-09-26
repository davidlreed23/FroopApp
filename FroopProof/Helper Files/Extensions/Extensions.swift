//
//  Extensions+View.swift
//  FroopProof
//
//  Created by David Reed on 1/19/23.
//

import SwiftUI
import UIKit
import Foundation
import MapKit
import Combine


public extension Int {
    func daySuffix() -> String {
        switch self {
        case 11...13: return "th"
        default:
            switch self % 10 {
            case 1: return "st"
            case 2: return "nd"
            case 3: return "rd"
            default: return "th"
            }
        }
    }
}

extension String {
    
    var formattedPhoneNumber: String {
        let cleanedPhoneNumber = self.filter { "0"..."9" ~= $0 }
        let formattedPhoneNumber: String
        
        if cleanedPhoneNumber.count == 10 {
            let startIndex1 = cleanedPhoneNumber.index(cleanedPhoneNumber.startIndex, offsetBy: 3)
            let endIndex1 = cleanedPhoneNumber.index(cleanedPhoneNumber.startIndex, offsetBy: 5)
            let startIndex2 = cleanedPhoneNumber.index(cleanedPhoneNumber.startIndex, offsetBy: 6)
            let endIndex2 = cleanedPhoneNumber.index(cleanedPhoneNumber.startIndex, offsetBy: 9)
            
            let part1 = cleanedPhoneNumber.prefix(3)
            let part2 = cleanedPhoneNumber[startIndex1...endIndex1]
            let part3 = cleanedPhoneNumber[startIndex2...endIndex2]
            
            formattedPhoneNumber = "(\(part1)) \(part2)-\(part3)"
        } else {
            formattedPhoneNumber = self
        }
        
        return formattedPhoneNumber
    }
    
    var formattedPhoneNumberC: String {
        let cleanedPhoneNumber = self.filter { "0"..."9" ~= $0 }
        
        // Assuming that the country code is only 1 digit. Adjust the `countryCodeLength` as needed.
        let countryCodeLength = 1
        let startIndex = cleanedPhoneNumber.index(cleanedPhoneNumber.startIndex, offsetBy: countryCodeLength)
        let phoneNumberWithoutCountryCode = String(cleanedPhoneNumber[startIndex...])
        
        let formattedPhoneNumber: String
        
        if phoneNumberWithoutCountryCode.count == 10 {
            let startIndex1 = phoneNumberWithoutCountryCode.index(phoneNumberWithoutCountryCode.startIndex, offsetBy: 3)
            let endIndex1 = phoneNumberWithoutCountryCode.index(phoneNumberWithoutCountryCode.startIndex, offsetBy: 5)
            let startIndex2 = phoneNumberWithoutCountryCode.index(phoneNumberWithoutCountryCode.startIndex, offsetBy: 6)
            let endIndex2 = phoneNumberWithoutCountryCode.index(phoneNumberWithoutCountryCode.startIndex, offsetBy: 9)
            
            let part1 = phoneNumberWithoutCountryCode.prefix(3)
            let part2 = phoneNumberWithoutCountryCode[startIndex1...endIndex1]
            let part3 = phoneNumberWithoutCountryCode[startIndex2...endIndex2]
            
            formattedPhoneNumber = "(\(part1)) \(part2)-\(part3)"
        } else {
            formattedPhoneNumber = self
        }
        
        return formattedPhoneNumber
    }
}
extension Date {
    func diff(numDays: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: numDays, to: self)!
    }
    
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }
}
extension Double {
    
    private var currencyFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter
    }
    
    func toCurrency() -> String {
        return currencyFormatter.string(for: self) ?? ""
    }
    
}
extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}

extension UIApplication {
    func endEditing(_ force: Bool) {
        self.connectedScenes
            .filter({$0.activationState == .foregroundActive})
            .map({$0 as? UIWindowScene})
            .compactMap({$0})
            .first?.windows
            .filter({$0.isKeyWindow})
            .first?.endEditing(force)
    }
}
extension UIApplication{
    func closeKeyboard(){
        print("-Application_utility: Function: closeKeyboard firing")
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    // Root Controller
    func rootController()->UIViewController{
        print("-Application_utility: Function: rootController firing")
        guard let window = connectedScenes.first as? UIWindowScene else{
            fatalError("Unable to get UIWindowScene")
        }
        guard let viewcontroller = window.windows.last?.rootViewController else{
            fatalError("Unable to get rootViewController")
        }
        
        return viewcontroller
    }
}
extension UIApplication {
    func endEditing() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

extension UIScreen{
    static let screenWidth = UIScreen.main.bounds.size.width
    static let screenHeight = UIScreen.main.bounds.size.height
    static let screenSize = UIScreen.main.bounds.size
}

extension View{
    //MARK: Custom View Modifier
    func blurredSheet<Content: View>(_ style: AnyShapeStyle, show: Binding<Bool>, onDismiss: @escaping ()->(), @ViewBuilder content: @escaping ()->Content)-> some View{
        self
            .fullScreenCover(isPresented: show, onDismiss: onDismiss) {
                content()
                    .background(RemovebackgroundColor())
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background {
                        Rectangle()
                            .fill(style)
                            .ignoresSafeArea(.container, edges: .all)
                    }
            }
    }
}
extension View {
    
    func myMoveText(_ progress: CGFloat, _ headerHeight: CGFloat, _ headerWidth: CGFloat, _ minimumHeaderHeight: CGFloat, _ minimumHeaderWidth: CGFloat) -> some View {
        self
            .hidden()
            .overlay {
                GeometryReader { proxy in
                    let rect = proxy.frame(in: .global)
                    //let minX = rect.minX
                    let midY = rect.midY
                    // let midTarget = 0
                    // let delta = rect.width - 125
                    // let adjustededX = rect.width - delta
                    /// Half Scaled Text Height (Since Text Scaling will be 0.85 (1 - 0.15))
                    let halfScaledTextHeight = (rect.height * 0.85) / 2
                    // let halfScaledTextWidth = (rect.width * 0.85) / 2
                    /// Profile Image
                    let profileImageHeight = (headerHeight * 0.9)
                    //                    let profileImageWidth = (headerWidth * 0.9)
                    /// Since Image Scaling will be 0.3 (1 - 0.7)
                    let scaledImageHeight = profileImageHeight * 0.3
                    //let scaledImageWidth = profileImageWidth * 0.3
                    // let halfScaledImageHeight = scaledImageHeight / 2
                    // let halfScaledImageWidth = scaledImageWidth / 2
                    /// Applied VStack Spacing is 15
                    /// 15 / 0.3 = 4.5 (0.3 -> Image Scaling)
                    let vStackSpacing: CGFloat = 4.5
                    let resizedOffsetY = (midY - ((minimumHeaderHeight / 3) - (halfScaledTextHeight * 2) - vStackSpacing - scaledImageHeight))
                    //let resizedOffsetX = (minX - 10)
                    
                    self
                        .scaleEffect(1 - (progress * 0.15))
                        .offset(y: -resizedOffsetY * progress)
                    //.offset(x: -resizedOffsetX * progress)
                        .onAppear {
                            printProperties(midY: midY,
                                            minimumHeaderHeight: minimumHeaderHeight,
                                            halfScaledTextHeight: halfScaledTextHeight,
                                            vStackSpacing: vStackSpacing,
                                            scaledImageHeight: scaledImageHeight,
                                            resizedOffsetY: resizedOffsetY)
                        }
                }
                
            }
        
    }
    
    private func printProperties(midY: CGFloat, minimumHeaderHeight: CGFloat, halfScaledTextHeight: CGFloat, vStackSpacing: CGFloat, scaledImageHeight: CGFloat, resizedOffsetY: CGFloat) {
        print("midY: \(midY)")
        print("minimumHeaderHeight: \(minimumHeaderHeight)")
        print("halfScaledTextHeight: \(halfScaledTextHeight)")
        print("vStackSpacing: \(vStackSpacing)")
        print("scaledImageHeight: \(scaledImageHeight)")
        print("resizedOffsetY: \(resizedOffsetY)")
    }
    
    func myMoveSymbols(_ progress: CGFloat, _ headerHeight: CGFloat, _ headerWidth: CGFloat, _ minimumHeaderHeight: CGFloat, _ minimumHeaderWidth: CGFloat) -> some View {
        self
            .hidden()
            .overlay {
                GeometryReader { proxy in
                    let rect = proxy.frame(in: .global)
                    let minX = rect.minX
                    let midY = rect.midY
                    /// Half Scaled Text Height (Since Text Scaling will be 0.85 (1 - 0.15))
                    let halfScaledTextHeight = (rect.height * 1) / 2
                    // let halfScaledTextWidth = (rect.width * 1) / 2
                    /// Profile Image
                    let profileImageHeight = (headerHeight * 0.9)
                    //                let profileImageWidth = (headerWidth * 0.9)
                    /// Since Image Scaling will be 0.3 (1 - 0.7)
                    let scaledImageHeight = profileImageHeight * 0.3
                    //let scaledImageWidth = profileImageWidth * 0.3
                    // let halfScaledImageHeight = scaledImageHeight / 2
                    // let halfScaledImageWidth = scaledImageWidth / 2
                    /// Applied VStack Spacing is 15
                    /// 15 / 0.3 = 4.5 (0.3 -> Image Scaling)
                    let vStackSpacing: CGFloat = 4.5
                    let resizedOffsetY = (midY - ((minimumHeaderHeight / 2) - halfScaledTextHeight - vStackSpacing - scaledImageHeight))
                    let resizedOffsetX = (minX)
                    
                    self
                        .scaleEffect(1 - (progress * 1))
                        .offset(y: -resizedOffsetY * progress / 2)
                        .offset(x: -resizedOffsetX * progress)
                        .opacity(1 - progress)
                        .onAppear {
                            printProperties(midY: midY,
                                            minimumHeaderHeight: minimumHeaderHeight,
                                            halfScaledTextHeight: halfScaledTextHeight,
                                            vStackSpacing: vStackSpacing,
                                            scaledImageHeight: scaledImageHeight,
                                            resizedOffsetY: resizedOffsetY)
                        }
                }
            }
    }
    
    func myMoveMenu(_ progress: CGFloat, _ headerHeight: CGFloat, _ headerWidth: CGFloat, _ minimumHeaderHeight: CGFloat, _ minimumHeaderWidth: CGFloat) -> some View {
        self
            .hidden()
            .overlay {
                GeometryReader { proxy in
                    let rect = proxy.frame(in: .global)
                    //let minX = rect.minX
                    //                    let midX = rect.midX
                    let midY = rect.midY
                    /// Half Scaled Text Height (Since Text Scaling will be 0.85 (1 - 0.15))
                    let halfScaledTextHeight = (rect.height * 1) / 2
                    /// Profile Image
                    let profileImageHeight = (headerHeight * 0.9)
                    //                    let profileImageWidth = (headerWidth * 0.9)
                    /// Since Image Scaling will be 0.3 (1 - 0.7)
                    let scaledImageHeight = profileImageHeight * 0.3
                    //                     let scaledImageWidth = profileImageWidth * 0.3
                    /// Applied VStack Spacing is 15
                    /// 15 / 0.3 = 4.5 (0.3 -> Image Scaling)
                    let vStackSpacing: CGFloat = 4.5
                    let resizedOffsetY = (midY - ((minimumHeaderHeight / 2) - (halfScaledTextHeight * 2) - vStackSpacing - scaledImageHeight + 65))
                    //let resizedOffsetX = (minX - 80)
                    
                    self
                        .scaleEffect(1)
                        .offset(y: -resizedOffsetY * progress / 2)
                    //.offset(x: -resizedOffsetX * progress)
                        .onAppear {
                            printProperties(midY: midY,
                                            minimumHeaderHeight: minimumHeaderHeight,
                                            halfScaledTextHeight: halfScaledTextHeight,
                                            vStackSpacing: vStackSpacing,
                                            scaledImageHeight: scaledImageHeight,
                                            resizedOffsetY: resizedOffsetY)
                        }
                }
            }
    }
}
extension View {
    func moveText(_ progress: CGFloat, _ headerHeight: CGFloat, _ headerWidth: CGFloat, _ minimumHeaderHeight: CGFloat, _ minimumHeaderWidth: CGFloat) -> some View {
        self
            .hidden()
            .overlay {
                GeometryReader { proxy in
                    let rect = proxy.frame(in: .global)
                    //let minX = rect.minX
                    let midY = rect.midY
                    // let midTarget = 0
                    // let delta = rect.width - 125
                    // let adjustededX = rect.width - delta
                    /// Half Scaled Text Height (Since Text Scaling will be 0.85 (1 - 0.15))
                    let halfScaledTextHeight = (rect.height * 0.85) / 2
                    // let halfScaledTextWidth = (rect.width * 0.85) / 2
                    /// Profile Image
                    let profileImageHeight = (headerHeight * 0.9)
//                    let profileImageWidth = (headerWidth * 0.9)
                    /// Since Image Scaling will be 0.3 (1 - 0.7)
                    let scaledImageHeight = profileImageHeight * 0.3
                    //let scaledImageWidth = profileImageWidth * 0.3
                    // let halfScaledImageHeight = scaledImageHeight / 2
                    // let halfScaledImageWidth = scaledImageWidth / 2
                    /// Applied VStack Spacing is 15
                    /// 15 / 0.3 = 4.5 (0.3 -> Image Scaling)
                    let vStackSpacing: CGFloat = 4.5
                    let resizedOffsetY = (midY - (minimumHeaderHeight - halfScaledTextHeight - vStackSpacing - scaledImageHeight))
                    // let resizedOffsetX = ((125) - (rect.width / 2))
                    
                    self
                        .scaleEffect(1 - (progress * 0.15))
                        .offset(y: -resizedOffsetY * progress)
                    //.offset(x: -resizedOffsetX * progress)
                }
            }
    }
    func moveSymbols(_ progress: CGFloat, _ headerHeight: CGFloat, _ headerWidth: CGFloat, _ minimumHeaderHeight: CGFloat, _ minimumHeaderWidth: CGFloat) -> some View {
        self
            .hidden()
            .overlay {
                GeometryReader { proxy in
                    let rect = proxy.frame(in: .global)
                    let minX = rect.minX
                    let midY = rect.midY
                    /// Half Scaled Text Height (Since Text Scaling will be 0.85 (1 - 0.15))
                    let halfScaledTextHeight = (rect.height * 1) / 2
                    // let halfScaledTextWidth = (rect.width * 1) / 2
                    /// Profile Image
                    let profileImageHeight = (headerHeight * 0.9)
//                    let profileImageWidth = (headerWidth * 0.9)
                    /// Since Image Scaling will be 0.3 (1 - 0.7)
                    let scaledImageHeight = profileImageHeight * 0.3
                    //let scaledImageWidth = profileImageWidth * 0.3
                    // let halfScaledImageHeight = scaledImageHeight / 2
                    // let halfScaledImageWidth = scaledImageWidth / 2
                    /// Applied VStack Spacing is 15
                    /// 15 / 0.3 = 4.5 (0.3 -> Image Scaling)
                    let vStackSpacing: CGFloat = 4.5
                    let resizedOffsetY = (midY - (minimumHeaderHeight - halfScaledTextHeight - vStackSpacing - scaledImageHeight))
                    let resizedOffsetX = (minX)
                    
                    self
                        .scaleEffect(1 - (progress * 1))
                        .offset(y: -resizedOffsetY * progress / 2)
                        .offset(x: -resizedOffsetX * progress)
                        .opacity(1 - progress)
                }
            }
    }
    
    func moveMenu(_ progress: CGFloat, _ headerHeight: CGFloat, _ headerWidth: CGFloat, _ minimumHeaderHeight: CGFloat, _ minimumHeaderWidth: CGFloat) -> some View {
        self
            .hidden()
            .overlay {
                GeometryReader { proxy in
                    let rect = proxy.frame(in: .global)
                    //let minX = rect.minX
                    let midY = rect.midY
                    /// Half Scaled Text Height (Since Text Scaling will be 0.85 (1 - 0.15))
                    let halfScaledTextHeight = (rect.height * 1) / 2
                    /// Profile Image
                    let profileImageHeight = (headerHeight * 0.9)
//                    let profileImageWidth = (headerWidth * 0.9)
                    /// Since Image Scaling will be 0.3 (1 - 0.7)
                    let scaledImageHeight = profileImageHeight * 0.3
                    // let scaledImageWidth = profileImageWidth * 0.3
                    /// Applied VStack Spacing is 15
                    /// 15 / 0.3 = 4.5 (0.3 -> Image Scaling)
                    let vStackSpacing: CGFloat = 4.5
                    let resizedOffsetY = (midY - (minimumHeaderHeight - halfScaledTextHeight - vStackSpacing - scaledImageHeight + 65))
                    // let resizedOffsetX = 0
                    
                    self
                        .scaleEffect(1)
                        .offset(y: -resizedOffsetY * progress)
                    //.offset(x: -resizedOffsetX * progress)
                }
            }
    }
}
extension View {
    func keyboardAdaptive() -> some View {
        ModifiedContent(content: self, modifier: KeyboardAdaptive())
    }
}
extension View {
    @ViewBuilder
    func showCase(order: Int, title: String, cornerRadius: CGFloat, style: RoundedCornerStyle = .continuous, scale: CGFloat = 1) -> some View {
        self
            .anchorPreference(key: HighlightAnchorKey.self, value: .bounds) { anchor in
                let highlight = Highlight(anchor: anchor, title: title, cornerRadius: cornerRadius, style: style, scale: scale)
                return [order: highlight]
            }
    }
}

fileprivate struct HighlightAnchorKey: PreferenceKey {
    static var defaultValue: [Int: Highlight] = [:]

    static func reduce(value: inout [Int : Highlight], nextValue: () -> [Int : Highlight]) {
        value.merge(nextValue()) { $1 }
    }
}

struct ShowCaseRoot: ViewModifier {
    var showHighlights: Bool
    var onFinished: () -> ()
    
    @State private var highlightOrder: [Int] = []
    @State private var currentHighlight: Int = 0
    @State private var showView: Bool = false
    
    func body(content: Content) -> some View {
        content
            .onPreferenceChange(HighlightAnchorKey.self) { value in
                highlightOrder = Array(value.keys)
            }
            .overlayPreferenceValue(HighlightAnchorKey.self) { preferences in
                if highlightOrder.indices.contains(currentHighlight), showHighlights, showView {
                    if let highlight = preferences[highlightOrder[currentHighlight]] {
                        HighlightView(highlight)
                    }
                }
            }
    }
    
    @ViewBuilder
    func HighlightView(_ highlight: Highlight) -> some View {
        GeometryReader { proxy in
            ZStack {
                let highlightRect = proxy[highlight.anchor]
                let safeArea = proxy.safeAreaInsets
                
                Rectangle()
                    .fill(.black.opacity(0.5))
                    .reverseMask {
                        Rectangle()
                            .frame(width: highlightRect.width + 5, height: highlightRect.height + 5)
                            .clipShape(RoundedRectangle(cornerRadius: highlight.cornerRadius, style: highlight.style))
                            .offset(x: highlightRect.minX - 2.5, y: highlightRect.minY - 2.5)
                        
                    }
                    .onTapGesture {
                        if currentHighlight >= highlightOrder.count - 1 {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                
                            }
                            
                        } else {
                            withAnimation(.interactiveSpring(response: 0.3, dampingFraction: 0.7, blendDuration: 0.7)) {
                                currentHighlight += 1
                            }
                        }
                    }
            }
            .ignoresSafeArea()
        }
    }
}

extension View {
    @ViewBuilder
    func reverseMask<Content: View>(alignment: Alignment = .topLeading, @ViewBuilder content: @escaping () -> Content) ->
    some View {
        self
            .mask {
            Rectangle()
                .overlay(alignment: .topLeading) {
                    content()
                        .blendMode(.destinationOut)
                }
        }
    }
}

extension UIView {
    func makeFirstResponder(_ view: UIView) {
        for subview in subviews {
            if subview.isFirstResponder {
                subview.resignFirstResponder()
            }
            subview.makeFirstResponder(view)
        }
    }
}

extension UIViewController {
    func topMostViewController() -> UIViewController {
        if let presentedViewController = self.presentedViewController {
            return presentedViewController.topMostViewController()
        } else if let navigationController = self as? UINavigationController {
            return navigationController.visibleViewController?.topMostViewController() ?? navigationController
        } else if let tabBarController = self as? UITabBarController {
            return tabBarController.selectedViewController?.topMostViewController() ?? tabBarController
        } else {
            return self
        }
    }
}

extension UIImage {
    func resize(to size: CGSize) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        self.draw(in: CGRect(origin: .zero, size: size))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage
    }
}
extension UIImage {
    func resized(toWidth width: CGFloat) -> UIImage? {
        let canvasSize = CGSize(width: width, height: CGFloat(ceil(width/size.width * size.height)))
        UIGraphicsBeginImageContextWithOptions(canvasSize, false, scale)
        defer { UIGraphicsEndImageContext() }
        draw(in: CGRect(origin: .zero, size: canvasSize))
        return UIGraphicsGetImageFromCurrentImageContext()
    }
}
extension UIImage {
    convenience init(color: UIColor, size: CGSize = CGSize(width: 1, height: 1)) {
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        color.setFill()
        UIRectFill(CGRect(origin: .zero, size: size))
        let image = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        self.init(cgImage: image.cgImage!)
    }
}

extension Text {
    func customTitleText() -> Text {
        PrintControl.shared.printProfile("-TitleView2: Function: customTitleText firing")
        return self
            .foregroundColor(.primary)
            .fontWeight(.light)
            .font(.system(size: 36))
    }
}
extension Text {
    func CcustomTitleText() -> Text {
        self
            .fontWeight(.light)
            .font(.system(size: 36))
    }
}

extension UIColor {
    func toHexString() -> String {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0

        getRed(&r, green: &g, blue: &b, alpha: &a)

        return String(format: "%02lX%02lX%02lX", Int(r * 0xff), Int(g * 0xff), Int(b * 0xff))
    }

    convenience init?(hexString: String) {
        let r, g, b: CGFloat
        let a: CGFloat = 1.0

        if hexString.hasPrefix("#") {
            let start = hexString.index(hexString.startIndex, offsetBy: 1)
            let hexColor = String(hexString[start...])

            if hexColor.count == 6 {
                let scanner = Scanner(string: hexColor)
                var hexNumber: UInt64 = 0

                if scanner.scanHexInt64(&hexNumber) {
                    r = CGFloat((hexNumber & 0xff0000) >> 16) / 255
                    g = CGFloat((hexNumber & 0x00ff00) >> 8) / 255
                    b = CGFloat(hexNumber & 0x0000ff) / 255

                    self.init(red: r, green: g, blue: b, alpha: a)
                    return
                }
            }
        }

        return nil
    }
}
 
extension Color {
    static var mainColor = Color(UIColor.systemIndigo)
}
extension Color {
    static let theme = ColorTheme()
}
extension Color {
    static var CmainColor = Color(UIColor.systemIndigo)
}
extension Color {
    
    static let offWhite = Color(red: 225 / 255, green: 225 / 255, blue: 235 / 255 )
    
    func luminosity(_ value: Double) -> Color {
        let uiColor = UIColor(self)
        
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0
        
        uiColor.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
        
        return Color(UIColor(hue: hue, saturation: saturation, brightness: CGFloat(value), alpha: alpha))
    }
}

extension KeyboardReadable {
    var keyboardPublisher: AnyPublisher<Bool, Never> {
        Publishers.Merge(
            NotificationCenter.default
                .publisher(for: UIResponder.keyboardWillShowNotification)
                .map { _ in true },
            
            NotificationCenter.default
                .publisher(for: UIResponder.keyboardWillHideNotification)
                .map { _ in false }
        )
        .eraseToAnyPublisher()
    }
}

extension FroopHistory {
    func determineFroopStatus() {
        let froopId = self.froop.froopId

        if FroopDataController.shared.myArchivedList.contains(where: { $0.froopId == froopId }) {
            self.froopStatus = .archived
        } else if FroopDataController.shared.myInvitesList.contains(where: { $0.froopId == froopId }) {
            self.froopStatus = .invited
        } else if FroopDataController.shared.myConfirmedList.contains(where: { $0.froopId == froopId }) {
            self.froopStatus = .confirmed
        } else {
            self.froopStatus = .none
        }
    }
    
    func textForStatus() -> String {
        switch self.froopStatus {
            case .invited:
                return "Invite Pending"
            case .confirmed:
                return "Confirmed"
            case .archived:
                return "Archived"
            case .none:
                return "Error"
        }
    }
    
    func cardForStatus(openFroop: Binding<Bool>) -> AnyView {
        switch self.froopStatus {
            case .invited:
                return AnyView(FroopInvitesCardView(openFroop: openFroop, froopHostAndFriends: self, invitedFriends: friends))
            case .confirmed:
                return AnyView(FroopConfirmedCardView(
                    openFroop: openFroop, froopHostAndFriends: self,
                    invitedFriends: friends
                ))
            case .archived:
                return AnyView(FroopArchivedCardView(openFroop: openFroop))
            case .none:
                return AnyView(EmptyView())
        }
    }
    
    func colorForStatus() -> Color {
           switch self.froopStatus {
           case .invited:
               return Color(red: 249/255, green: 0/255, blue: 98/255)
           case .confirmed:
               return Color.blue
           case .archived:
               return Color.black
           case .none:
               return Color.red
           }
       }
    
}

extension AppStateManager {
    func setupCountdownTimer() {
        timerCancellable = Timer.publish(every: 60, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.now = Date()
                if let timeUntilNextFroop = self.timeUntilNextFroop(), timeUntilNextFroop <= 1800 {
                    self.setupListener { _ in
                        // Handle the UserData or whatever you want in this closure
                    }
                    self.timerCancellable?.cancel() // Optionally, stop the timer after calling the function.
                }
            }
    }

    // This assumes that the logic to determine the next Froop is part of AppStateManager.
    // If it isn't, you'll need to adjust where this logic is pulled from.
    private func timeUntilNextFroop() -> TimeInterval? {
        let nextFroops = FroopDataListener.shared.myConfirmedList.filter { $0.froopStartTime > now }
        guard let nextFroop = nextFroops.min(by: { $0.froopStartTime < $1.froopStartTime }) else {
            return nil
        }
        return nextFroop.froopStartTime.timeIntervalSince(now)
    }
}

extension LocationManager: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard FirebaseServices.shared.isAuthenticated else {
            // If the user is not authenticated, return early
            return
        }
        PrintControl.shared.printLocationServices("-LocationManager: Function:  locationManager is firing!")
        guard let location = locations.first else { return }
        self.userLocation = location
        
        locationCount += 1
        self.locations.append((count: locationCount, latitude: location.coordinate.latitude, longitude: location.coordinate.longitude))
        updateUserLocationInFirestore()

//        locationManager.stopUpdatingLocation()
//        stopUpdating()
        
        getCurrentLocationAddress(location) { (address) in
            self.userLocationAddress = address
        }
        
        // Calculate travel time to Froops and reschedule the notifications
        for froopData in froopDataArray {
            calculateTravelTime(from: location.coordinate, to: froopData.froopLocationCoordinate) { travelTime in
                if let travelTime = travelTime {
                    self.rescheduleLocalNotification(for: froopData, travelTime: travelTime)
                } else {
                    PrintControl.shared.printErrorMessages("Could not calculate travel time.")
                }
            }
        }
        let uid = FirebaseServices.shared.uid
        // Update user's location in Firestore
        let db = FirebaseServices.shared.db
        
        let userDocRef = db.collection("users").document(uid)
        PrintControl.shared.printLocationServices("updating user's location in firestore")
        let geoPoint = FirebaseServices.shared.convertToGeoPoint(coordinate: location.coordinate)
        userDocRef.updateData([
            "coordinate": geoPoint
        ]) { error in
            if let error = error {
                PrintControl.shared.printErrorMessages("Error updating location: \(error)")
            } else {
                self.updateUserLocationInFirestore()
                PrintControl.shared.printLocationServices("Location successfully updated")
            }
        }
        
        // Check if user has arrived
        if let froopLocation = froopDataArray.first?.froopLocationCoordinate {
            let froopLocation = CLLocation(latitude: froopLocation.latitude, longitude: froopLocation.longitude)
            if location.distance(from: froopLocation) <= 25 {
                stopUpdating()
                userDocRef.updateData([
                    "guestArrived": true
                ]) { error in
                    if let error = error {
                        PrintControl.shared.printErrorMessages("Error updating guestArrived: \(error)")
                    } else {
                        PrintControl.shared.printLocationServices("guestArrived successfully updated")
                    }
                }
            } else if location.distance(from: froopLocation) > 25 {
                userDocRef.updateData([
                    "guestArrived": false,
                    "guestLeft": true
                ]) { error in
                    if let error = error {
                        PrintControl.shared.printErrorMessages("Error updating guestArrived and guestLeft: \(error)")
                    } else {
                        PrintControl.shared.printLocationServices("guestArrived and guestLeft successfully updated")
                    }
                }
            }
        }
    }
}
extension LocationManager {
    func getCurrentLocationAddress(_ location: CLLocation, completion: @escaping (String?) -> Void) {
        PrintControl.shared.printLocationServices("-LocationManager: Function: getCurrentLocationAddress is firing!")
        let geoCoder = CLGeocoder()
        geoCoder.reverseGeocodeLocation(location) { placemarks, error in
            if let error = error {
                PrintControl.shared.printErrorMessages("Error getting location address: \(error.localizedDescription)")
                completion(nil)
                return
            }
            guard let placemarks = placemarks, let placemark = placemarks.first else {
                completion(nil)
                return
            }
            // Use the placemark to get the address
            var addressString = ""
            if let streetNumber = placemark.subThoroughfare {
                addressString += streetNumber + " "
            }
            if let streetName = placemark.thoroughfare {
                addressString += streetName + ", "
            }
            if let city = placemark.locality {
                addressString += city + ", "
            }
            if let state = placemark.administrativeArea {
                addressString += state + " "
            }
            if let postalCode = placemark.postalCode {
                addressString += postalCode + ", "
            }
            if let country = placemark.country {
                addressString += country
            }
            completion(addressString)
        }
    }
    
    func getAddress(from location: FroopData) {
        PrintControl.shared.printLocationServices("-LocationManager: Function: getAddress is firing!")
        let geocoder = CLGeocoder()
        let location = CLLocation(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
        geocoder.reverseGeocodeLocation(location) { (placemarks, error) in
            if let error = error {
                PrintControl.shared.printErrorMessages(error.localizedDescription)
            } else if let placemarks = placemarks {
                if let placemark = placemarks.first {
                    var addressString = ""
                    if let streetNumber = placemark.subThoroughfare {
                        addressString += streetNumber + " "
                    }
                    if let streetName = placemark.thoroughfare {
                        addressString += streetName + ", "
                    }
                    if let city = placemark.locality {
                        addressString += city + ", "
                    }
                    if let state = placemark.administrativeArea {
                        addressString += state + " "
                    }
                    if let postalCode = placemark.postalCode {
                        addressString += postalCode + ", "
                    }
                    if let country = placemark.country {
                        addressString += country
                    }
                    PrintControl.shared.printLocationServices(addressString)
                }
            }
        }
    }
}

extension Message: Equatable {
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(text)
        hasher.combine(froopId)
        hasher.combine(senderId)
        hasher.combine(receiverId)
        hasher.combine(timestamp)
        hasher.combine(conversationId)
    }
    
    static func == (lhs: Message, rhs: Message) -> Bool {
        return lhs.text == rhs.text &&
        lhs.froopId == rhs.froopId &&
        lhs.senderId == rhs.senderId &&
        lhs.receiverId == rhs.receiverId &&
        lhs.timestamp == rhs.timestamp &&
        lhs.conversationId == rhs.conversationId
    }
}

extension FriendRequest {
    enum CodingKeys: String, CodingKey {
        case fromUserID
        case toUserInfo
        case toUserID
        case status
        case documentID
        case firstName
        case lastName
        case profileImageUrl
        case phoneNumber
        case friendsInCommon // Add profile image URLs to CodingKeys
    }
}

extension FriendListData: Encodable {
    func encode(to encoder: Encoder) throws {
        PrintControl.shared.printInviteFriends("-FriendListData: Function: encode firing")
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(froopUserID, forKey: .froopUserID)
        try container.encode(timeZone, forKey: .timeZone)
        try container.encode(firstName, forKey: .firstName)
        try container.encode(lastName, forKey: .lastName)
        try container.encode(phoneNumber, forKey: .phoneNumber)
        try container.encode(profileImageUrl, forKey: .profileImageUrl)
    }
}

extension MKCoordinateRegion {
    static var myRegion: MKCoordinateRegion {
        return .init(center: .myLocation, latitudinalMeters: 10000, longitudinalMeters: 10000)
    }
}

extension MKMapRect {
    func reducedRect(_ fraction: CGFloat = 0.35) -> MKMapRect {
        var regionRect = self

        let wPadding = regionRect.size.width * fraction
        let hPadding = regionRect.size.height * fraction
                    
        regionRect.size.width += wPadding
        regionRect.size.height += hPadding
                    
        regionRect.origin.x -= wPadding / 2
        regionRect.origin.y -= hPadding / 2
        
        return regionRect
    }
}

extension CLLocationCoordinate2D {
    static var myLocation: CLLocationCoordinate2D {
        return .init(latitude: LocationManager.shared.user2DLocation?.latitude ?? 0.0, longitude: LocationManager.shared.user2DLocation?.longitude ?? 0.0
        )
    }
}

extension LocationSearchViewModel: MKLocalSearchCompleterDelegate {
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        self.results = completer.results
    }
}

extension DetailsMapViewRepresentable {
    
    class DetailsMapCoordinator: NSObject, MKMapViewDelegate {
        @State var froop: Froop
        var mapView = MKMapView()
        @ObservedObject var locationManager = LocationManager.shared
        @ObservedObject var locationServices = LocationServices.shared // @Binding var mapState: MapViewState
        @ObservedObject var appStateManager = AppStateManager.shared
        @ObservedObject var printControl = PrintControl.shared
        @ObservedObject var froopDataListener = FroopDataListener.shared
        @Published var annotations: [MKAnnotation] = []

        @EnvironmentObject var locationViewModel: LocationSearchViewModel
        
        let annotationModel = AnnotationModel()
        var visualEffectView: UIVisualEffectView?
        var selectedAnnotationView: MKAnnotationView?

        // MARK: - Properties
        let mapUpdateState: MapUpdateState
        let parent: DetailsMapViewRepresentable
        var userLocationCoordinate: CLLocationCoordinate2D?
        var currentRegion: MKCoordinateRegion?
        //var froopLocation: CLLocationCoordinate2D?
        
        //print("updating userLocation FOURTEEN")
        // MARK: - Lifecycle
        
        
        init(parent: DetailsMapViewRepresentable, mapUpdateState: MapUpdateState, froop: Froop, mapView: MKMapView) {
            self.parent = parent
            self.mapUpdateState = mapUpdateState
            self.froop = froop
            self.mapView = mapView
            //            self.mapView = parent.mapView // set mapView to parent's mapView
            super.init()
        }
        
        // MARK: - MKMapViewDelegate
        
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            print("MapView ViewFor Function Called")
            if let froopDropPin = annotation as? FroopDropPin {
                let identifier = "FroopDropPin"
                
                // Reuse or create an MKPinAnnotationView
                var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView
                if annotationView == nil {
                    annotationView = MKMarkerAnnotationView(annotation: froopDropPin, reuseIdentifier: identifier)
                    annotationView?.canShowCallout = true
                } else {
                    annotationView?.annotation = froopDropPin
                }
                
                // Set the pin color
                annotationView?.markerTintColor = froopDropPin.color
                
                return annotationView
            }
            return nil
        }
        
        func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
            if locationServices.trackActiveUserLocation == false {
                return
            }
            let newCoordinate = userLocation.coordinate
            guard let previousCoordinate = self.userLocationCoordinate else {
                // This is the first location update, so we don't have a previous location to compare with
                self.userLocationCoordinate = newCoordinate
                return
            }
            
            let distance = sqrt(pow(newCoordinate.latitude - previousCoordinate.latitude, 2) + pow(newCoordinate.longitude - previousCoordinate.longitude, 2))
            if distance < 0.00001 { // Adjust this threshold as needed
                                    // The location hasn't changed significantly, so we ignore this update
                return
            }
            
            // The location has changed significantly, so we process this update
            self.userLocationCoordinate = newCoordinate
            
            PrintControl.shared.printLocationServices("Previous Location: \(String(describing: previousCoordinate.latitude)), \(String(describing: previousCoordinate.longitude))")
            print("New Location: \(newCoordinate.latitude), \(newCoordinate.longitude)")
            
            let region = MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: newCoordinate.latitude, longitude: newCoordinate.longitude),
                span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
            )
            
            PrintControl.shared.printLocationServices("updating userLocation TOMMY")
            PrintControl.shared.printLocationServices(mapUpdateState.isFunctionEnabled.description)
            self.currentRegion = region
            
            parent.mapView.setRegion(region, animated: false)
        }
        
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            PrintControl.shared.printLocationServices("-DetailsMapViewRepresentable: Function: mapView2 is firing!")
            let polyline = MKPolylineRenderer(overlay: overlay)
            polyline.strokeColor = .systemBlue
            polyline.lineWidth = 6
            return polyline
        }
        
        func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
            if let annotation = view.annotation as? MovableAnnotation {
                if control == view.rightCalloutAccessoryView {
                    // Handle the detail disclosure button being tapped
                    let alert = UIAlertController(title: "Edit Annotation", message: nil, preferredStyle: .alert)
                    alert.addTextField { textField in
                        textField.text = annotation.title
                    }
                    alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                        if let newTitle = alert.textFields?.first?.text {
                            annotation.title = newTitle
                        }
                    })
                    alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
                    
                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                        windowScene.windows.first?.rootViewController?.present(alert, animated: true)
                    }
                } else if control == view.leftCalloutAccessoryView {
                    // Handle the delete button being tapped
                    mapView.removeAnnotation(annotation as! MKAnnotation)
                }
            }
        }
        
        func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
            selectedAnnotationView = view

            if view.annotation is FroopDropPin {
                appStateManager.isAnnotationMade = true
                appStateManager.isFroopTabUp = false
                appStateManager.isDarkStyle = false
                ActiveMapViewModel.shared.annotationModel.annotation = view.annotation as? FroopDropPin
            }
        }
        
        // MARK: - Helpers
        
        @objc func addAnnotationOnLongPress(gesture: UILongPressGestureRecognizer) {
            print("Long press detected!")

            if gesture.state == .began {
                print("Gesture state is .began")

                let point = gesture.location(in: mapView)
                let coordinate = mapView.convert(point, toCoordinateFrom: mapView)
                print("Coordinate: \(coordinate.latitude), \(coordinate.longitude)")
 
                // Fetch or define the creatorUID and profileImageUrl values
                let creatorUID = FirebaseServices.shared.uid
                let profileImageUrl = MyData.shared.profileImageUrl
                
                let annotation = FroopDropPin(coordinate: coordinate, title: "Title Here.", subtitle: "SubTitle Here", messageBody: "Message Here", color: UIColor.purple, creatorUID: creatorUID, profileImageUrl: profileImageUrl)
                
                mapView.addAnnotation(annotation)
                appStateManager.isAnnotationMade = true
                appStateManager.isFroopTabUp = false
                annotationModel.annotation = annotation
                
                annotations.append(annotation) // Add the new annotation to viewModel.annotations
            }
        }
        
        @objc func handleMapTap(_ gesture: UITapGestureRecognizer) {
            // Get the point that was tapped
            let point = gesture.location(in: mapView)
            
            // Convert that point to a coordinate
            let coordinate = mapView.convert(point, toCoordinateFrom: mapView)
            
            // Define the map rect to search within
            let mapPoint = MKMapPoint(coordinate)
            let searchRect = MKMapRect(x: mapPoint.x, y: mapPoint.y, width: 1, height: 1)
            
            // Filter the map's annotations to find those within the search rect
            let tappedAnnotations = mapView.annotations.filter { annotation in
                searchRect.contains(MKMapPoint(annotation.coordinate))
            }
            
            // If no annotations were tapped
            if tappedAnnotations.isEmpty {
                // Deselect all currently selected annotations
                for annotation in mapView.selectedAnnotations {
                    mapView.deselectAnnotation(annotation, animated: true)
                }
            }
        }
        
        func addAndSelectAnnotation(withCoordinate coordinate: CLLocationCoordinate2D) {
            PrintControl.shared.printLocationServices("-DetailsMapViewRepresentable: Function: addAndSelectAnnotation is firing!")
            parent.mapView.removeAnnotations(parent.mapView.annotations)
            
            let anno = MKPointAnnotation()
            anno.coordinate = froop.froopLocationCoordinate ?? CLLocationCoordinate2D()
            parent.mapView.addAnnotation(anno)
            parent.mapView.selectAnnotation(anno, animated: true)
        }
        
        func calculateDistance(to location: Froop) -> Double {
            PrintControl.shared.printLocationServices("-DetailsMapViewRepresentable: Function: calculateDistance is firing!")
            guard let userLocation = locationManager.userLocation else { return 0 }
            let froop = CLLocation(latitude: location.froopLocationCoordinate?.latitude ?? 0.0, longitude: location.froopLocationCoordinate?.longitude ?? 0.0)
            print("FROOP LOCATION")
            print(location.froopLocationCoordinate?.longitude ?? 0.0)
            print(location.froopLocationCoordinate?.latitude ?? 0.0)
            
            return userLocation.distance(from: froop)
        }
        
        func configurePolyline(withDestinationCoordinate coordinate: CLLocationCoordinate2D) {
            PrintControl.shared.printMap("-FroopMapViewRepresentable: Function: configurePolyline is firing!")
            PrintControl.shared.printMap("DAVID - CONFIGURE POLY LINE STARTED")

            guard let userCoordinate = self.parent.mapView.userLocation.location?.coordinate else {
                print("Error: Unable to fetch userCoordinate.")
                return
            }
            print("User Coordinate: \(userCoordinate.latitude), \(userCoordinate.longitude)")
            print("Destination Coordinate: \(coordinate.latitude), \(coordinate.longitude)")

            let request = MKDirections.Request()
            request.source = MKMapItem(placemark: MKPlacemark(coordinate: userCoordinate))
            request.destination = MKMapItem(placemark: MKPlacemark(coordinate: coordinate))
            request.transportType = .automobile

            let directions = MKDirections(request: request)
            directions.calculate { [unowned self] response, error in
                if let error = error {
                    print("Error in directions.calculate: \(error.localizedDescription)")
                    return
                }
                guard let route = response?.routes.first else {
                    print("No route available.")
                    return
                }

                self.parent.mapView.addOverlay(route.polyline)
                self.parent.mapState = .polylineAdded

                let rect = self.parent.mapView.mapRectThatFits(route.polyline.boundingMapRect,
                                                               edgePadding: .init(top: 150, left: 50, bottom: 150, right: 50))
                print("Setting map region to cover polyline.")
                self.parent.mapView.setRegion(MKCoordinateRegion(rect), animated: true)
            }
        }
        
        func clearMapViewAndRecenterOnUserLocation() {
            PrintControl.shared.printMap("DetailsMapViewRepresentable: Function: clearMapViewAndRecenterOnUserLocation is firing!")
            parent.mapView.removeAnnotations(parent.mapView.annotations)
            parent.mapView.removeOverlays(parent.mapView.overlays)
            PrintControl.shared.printLocationServices("updating userLocation NINETEEN")
            if let currentRegion = currentRegion {
                parent.mapView.setRegion(currentRegion, animated: false)
            }
        }
    }
}

extension FroopMapViewRepresentable {
    
    class MapCoordinator: NSObject, MKMapViewDelegate {
        @ObservedObject var froopData: FroopData
        let mapView = MKMapView()
        @ObservedObject var locationManager = LocationManager.shared
        @ObservedObject var locationServices = LocationServices.shared // @Binding var mapState: MapViewState
        @EnvironmentObject var locationViewModel: LocationSearchViewModel
        
        // MARK: - Properties
        let mapUpdateState: MapUpdateState
        let parent: FroopMapViewRepresentable
        var userLocationCoordinate: CLLocationCoordinate2D?
        var currentRegion: MKCoordinateRegion?
        //var froopLocation: CLLocationCoordinate2D?
        
        //print("updating userLocation FOURTEEN")
        // MARK: - Lifecycle
        
        init(parent: FroopMapViewRepresentable, mapUpdateState: MapUpdateState, froopData: FroopData) {
            self.parent = parent
            self.mapUpdateState = mapUpdateState
            self.froopData = froopData
            
            super.init()
        }
        
        
        // MARK: - MKMapViewDelegate
        
        func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
            if LocationServices.shared.trackUserLocation == false {
                return
            }
            let newCoordinate = userLocation.coordinate
            guard let previousCoordinate = self.userLocationCoordinate else {
                // This is the first location update, so we don't have a previous location to compare with
                self.userLocationCoordinate = newCoordinate
                return
            }
            
            let distance = sqrt(pow(newCoordinate.latitude - previousCoordinate.latitude, 2) + pow(newCoordinate.longitude - previousCoordinate.longitude, 2))
            if distance < 0.00001 { // Adjust this threshold as needed
                // The location hasn't changed significantly, so we ignore this update
                return
            }
            
            // The location has changed significantly, so we process this update
            self.userLocationCoordinate = newCoordinate
            
            PrintControl.shared.printLocationServices("Previous Location: \(String(describing: previousCoordinate.latitude)), \(String(describing: previousCoordinate.longitude))")
            PrintControl.shared.printLocationServices("New Location: \(newCoordinate.latitude), \(newCoordinate.longitude)")
            
            let region = MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: newCoordinate.latitude, longitude: newCoordinate.longitude),
                span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
            )
            
            PrintControl.shared.printLocationServices("updating userLocation TOMMY")
            PrintControl.shared.printLocationServices(mapUpdateState.isFunctionEnabled.description)
            self.currentRegion = region
            
            parent.mapView.setRegion(region, animated: false)
        }
        
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            PrintControl.shared.printLocationServices("-FroopMapViewRepresentable: Function: mapView2 is firing!")
            let polyline = MKPolylineRenderer(overlay: overlay)
            polyline.strokeColor = .systemBlue
            polyline.lineWidth = 6
            return polyline
        }
        
        // MARK: - Helpers
        
        func addAndSelectAnnotation(withCoordinate coordinate: CLLocationCoordinate2D) {
            PrintControl.shared.printLocationServices("-FroopMapViewRepresentable: Function: addAndSelectAnnotation is firing!")
            parent.mapView.removeAnnotations(parent.mapView.annotations)
            
            let anno = MKPointAnnotation()
            anno.coordinate = coordinate
            parent.mapView.addAnnotation(anno)
            parent.mapView.selectAnnotation(anno, animated: true)
        }
        
        func calculateDistance(to location: FroopData) -> Double {
            PrintControl.shared.printLocationServices("-FroopMapViewRepresentable: Function: calculateDistance is firing!")
            guard let userLocation = locationManager.userLocation else { return 0 }
            let froopData = CLLocation(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
            return userLocation.distance(from: froopData)
        }
        
        func configurePolyline(withDestinationCoordinate coordinate: CLLocationCoordinate2D) {
            PrintControl.shared.printMap("-FroopMapViewRepresentable: Function: configurePolyline is firing!")
            PrintControl.shared.printMap("DAVID - CONFIGURE POLY LINE STARTED")
            
            guard let userCoordinate = LocationManager.shared.userLocation?.coordinate else {
                return
            }
            
            let request = MKDirections.Request()
            request.source = MKMapItem(placemark: MKPlacemark(coordinate: userCoordinate))
            request.destination = MKMapItem(placemark: MKPlacemark(coordinate: coordinate))
            request.transportType = .automobile
            
            let directions = MKDirections(request: request)
            directions.calculate { [weak self] response, error in
                guard let route = response?.routes.first else {
                    return
                }
                
                self?.parent.mapView.addOverlay(route.polyline)
                self?.parent.mapState = .polylineAdded
                
                let rect = self?.parent.mapView.mapRectThatFits(route.polyline.boundingMapRect,
                                                                edgePadding: .init(top: 64, left: 32, bottom: 500, right: 32))
                
                if let rect = rect {
                    self?.parent.mapView.setRegion(MKCoordinateRegion(rect), animated: true)
                }
            }
        }
        
        func clearMapViewAndRecenterOnUserLocation() {
            PrintControl.shared.printMap("FroopMapViewRepresentable: Function: clearMapViewAndRecenterOnUserLocation is firing!")
            parent.mapView.removeAnnotations(parent.mapView.annotations)
            parent.mapView.removeOverlays(parent.mapView.overlays)
            PrintControl.shared.printLocationServices("updating userLocation NINETEEN")
            if let currentRegion = currentRegion {
                parent.mapView.setRegion(currentRegion, animated: false)
            }
        }
    }
}


extension UserData {
    static func convert(from myData: MyData) -> UserData {
        let userData = UserData()
        userData.data = myData.data
        userData.froopUserID = myData.froopUserID
        userData.timeZone = myData.timeZone
        userData.firstName = myData.firstName
        userData.lastName = myData.lastName
        userData.phoneNumber = myData.phoneNumber
        userData.addressNumber = myData.addressNumber
        userData.addressStreet = myData.addressStreet
        userData.unitName = myData.unitName
        userData.addressCity = myData.addressCity
        userData.addressState = myData.addressState
        userData.addressZip = myData.addressZip
        userData.addressCountry = myData.addressCountry
        userData.profileImageUrl = myData.profileImageUrl
        userData.fcmToken = myData.fcmToken
        userData.badgeCount = myData.badgeCount
        userData.coordinate = myData.coordinate
        return userData
    }
}
extension MyData: CustomStringConvertible {
    var description: String {
        return """
        MyData:
        - firstName: \(firstName)
        - lastName: \(lastName)
        - phoneNumber: \(phoneNumber)
        - addressNumber: \(addressNumber)
        - addressStreet: \(addressStreet)
        - unitName: \(unitName)
        - addressCity: \(addressCity)
        - addressState: \(addressState)
        - addressZip: \(addressZip)
        - addressCountry: \(addressCountry)
        - profileImageUrl: \(profileImageUrl)
        - coordinate: \(coordinate)
        - geoPoint: \(geoPoint)
        """
    }
}
extension Froop: CustomStringConvertible {
    var description: String {
        return "Froop(id: \(id), location: \(String(describing: froopLocationCoordinate)), ...)" // Add all the properties you want to print
    }
}
extension Froop: Equatable {
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(froopId)
        hasher.combine(froopName)
        hasher.combine(froopType)
        hasher.combine(froopLocationid)
        hasher.combine(froopLocationtitle)
        hasher.combine(froopLocationsubtitle)
        hasher.combine(froopDate)
        hasher.combine(froopStartTime)
        hasher.combine(froopCreationTime)
        hasher.combine(froopDuration)
        hasher.combine(froopInvitedFriends)
        hasher.combine(froopImages)
        hasher.combine(froopDisplayImages)
        hasher.combine(froopThumbnailImages)
        hasher.combine(froopVideos)
        hasher.combine(froopHost)
        hasher.combine(froopHostPic)
        hasher.combine(froopTimeZone)
        hasher.combine(froopEndTime)
        hasher.combine(froopMessage)
        hasher.combine(froopList)
        hasher.combine(template)
    }
    
    static func == (lhs: Froop, rhs: Froop) -> Bool {
        return lhs.froopId == rhs.froopId &&
        lhs.froopName == rhs.froopName &&
        lhs.froopType == rhs.froopType &&
        lhs.froopLocationid == rhs.froopLocationid &&
        lhs.froopLocationtitle == rhs.froopLocationtitle &&
        lhs.froopLocationsubtitle == rhs.froopLocationsubtitle &&
        lhs.froopDate == rhs.froopDate &&
        lhs.froopStartTime == rhs.froopStartTime &&
        lhs.froopCreationTime == rhs.froopCreationTime &&
        lhs.froopDuration == rhs.froopDuration &&
        lhs.froopInvitedFriends == rhs.froopInvitedFriends &&
        lhs.froopImages == rhs.froopImages &&
        lhs.froopDisplayImages == rhs.froopDisplayImages &&
        lhs.froopThumbnailImages == rhs.froopThumbnailImages &&
        lhs.froopVideos == rhs.froopVideos &&
        lhs.froopHost == rhs.froopHost &&
        lhs.froopHostPic == rhs.froopHostPic &&
        lhs.froopTimeZone == rhs.froopTimeZone &&
        lhs.froopEndTime == rhs.froopEndTime &&
        lhs.froopMessage == rhs.froopMessage &&
        lhs.froopList == rhs.froopList &&
        lhs.template == rhs.template
    }
}

// MARK: HelperView
fileprivate struct RemovebackgroundColor: UIViewRepresentable{
    func makeUIView(context: Context) -> UIView {
        return UIView()
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        DispatchQueue.main.async {
            uiView.superview?.superview?.backgroundColor = .clear
        }
    }
}


















