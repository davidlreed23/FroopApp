import SwiftUI

enum OnboardingTab: Int, Hashable {
    case first = 1
    case second = 2
    case third = 3
    case fourth = 4
    case fifth = 5
    
    init?(fromInt value: Int) {
        switch value {
            case 1: self = .first
            case 2: self = .second
            case 3: self = .third
            case 4: self = .fourth
            case 5: self = .fifth
            default: return nil
        }
    }
}


struct OnboardingView: View {
    @State var selectedTab: OnboardingTab = .first
    @State private var isKeyboardShown: Bool = false
    @State private var keyboardHeight: CGFloat = 0
    @Binding var ProfileCompletionCurrentPage: Int
    
    var body: some View {
        ZStack {
            Color.clear
            TabView(selection: $selectedTab) {
                OnboardOne(selectedTab: $selectedTab)
                    .tag(OnboardingTab.first)
                
                OnboardTwo(selectedTab: $selectedTab)
                    .tag(OnboardingTab.second)
                
                OnboardThree(selectedTab: $selectedTab)
                    .tag(OnboardingTab.third)
                
                OnboardFour(selectedTab: $selectedTab)
                    .tag(OnboardingTab.fourth)
                
                OnboardFive(selectedTab: $selectedTab, ProfileCompletionCurrentPage: $ProfileCompletionCurrentPage)
                    .tag(OnboardingTab.fifth)
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never)) // Set to never since we have our own custom indicatorsSet to never since we have our own custom indicators
        }
        .ignoresSafeArea(.keyboard)
        .ignoresSafeArea()
        .overlay(
            HStack(spacing: 20) {
                Image(systemName: "circle.fill")
                    .font(.system(size: 10))
                    .opacity(selectedTab == .first ? 1 : 0.25)
                Image(systemName: "circle.fill")
                    .font(.system(size: 10))
                    .opacity(selectedTab == .second ? 1 : 0.25)
                Image(systemName: "circle.fill")
                    .font(.system(size: 10))
                    .opacity(selectedTab == .third ? 1 : 0.25)
                Image(systemName: "circle.fill")
                    .font(.system(size: 10))
                    .opacity(selectedTab == .fourth ? 1 : 0.25)
                Image(systemName: "circle.fill")
                    .font(.system(size: 10))
                    .opacity(selectedTab == .fifth ? 1 : 0.25)
            }
                .foregroundColor(Color(red: 249/255, green: 98/255, blue: 0/255))
                .padding(.top, 0),
            alignment: .top
        )
        .navigationBarTitle("Froop Beta", displayMode: .inline)
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
        //        .offset(y: isKeyboardShown ? 0 : (keyboardHeight - 20) / 2)
    }
}
