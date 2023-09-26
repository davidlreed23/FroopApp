//
//  Message.swift
//  FroopProof
//
//  Created by David Reed on 7/22/23.
//

import SwiftUI
import Firebase
import FirebaseFirestore

// The chat view
struct ChatView: View {
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @ObservedObject var appStateManager = AppStateManager.shared
    @ObservedObject var notificationsManager = NotificationsManager.shared
    @State private var messageText: String = "" // This will hold the current input text
    @State private var lastMessageId: String = "" // This will hold the last message id
    @State var listCount: Int = 0
    
    var currentConversation: ConversationAndMessages? {
        notificationsManager.conversationsAndMessages.first(where: { $0.conversation.id == appStateManager.chatViewId })
    }
    
    init() {
        UITableView.appearance().separatorStyle = .none
    }
    
    var body: some View {
        VStack (spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView(showsIndicators: false) {
                    VStack {
                        Spacer(minLength: UIScreen.main.bounds.height * 0.8) // Use a large enough constant to cover the height of your messages
                        LazyVStack(spacing: 0) {
                            ForEach(currentConversation?.messages ?? [], id: \.id) { message in
                                MessageRow(message: message, isCurrentUser: message.senderId == notificationsManager.uid)
                            }
                        }
                    }
                    .onChange(of: currentConversation?.messages.count ?? 0, initial: currentConversation?.messages.isEmpty == false) { _, newValue in
                        withAnimation {
                            if newValue > 0, let lastMessage = currentConversation?.messages.last {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                    .onChange(of: notificationsManager.chatEntered, initial: notificationsManager.chatEntered) { oldValue, newValue in
                        withAnimation {
                            if newValue, let lastMessage = currentConversation?.messages.last {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                }
            }
            .padding(.top, 100)
            .padding(.leading, 10)
            .padding(.trailing, 10)
            .padding(.bottom, 10)
            .background(Color.clear)
            .keyboardAdaptive()
            
            ChatInputView(messageText: $messageText, onSend: {
                notificationsManager.sendMessage(content: self.messageText)
                self.getLastMessageId() // update the last message id when a new message is sent
            })
            .padding(.bottom, notificationsManager.chatEntered ? 10 : 65) // Conditional padding
        }
        .background(Color.clear)
        .onAppear(perform: {
            self.getLastMessageId() // update the last message id when the view appears
        })
    }
    private func scrollChatToBottom() {
        getLastMessageId()
    }
    private func getLastMessageId() {
        if let lastMessageId = currentConversation?.messages.last?.id {
            self.lastMessageId = lastMessageId
        }
    }
}



// A row in the chat
struct MessageRow: View {
    let message: Message
    let isCurrentUser: Bool
    
    var body: some View {
        ChatBubble(direction: isCurrentUser ? .right : .left) {
            Text(message.text)
                .frame(minWidth: 20)
                .font(.system(size: 14))
                .padding(EdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10))
                .foregroundColor(.white)
                .background(isCurrentUser ? Color(red: 249/255, green: 0/255, blue: 98/255) : Color.gray.opacity(0.5))
        }
        .padding(.top, -30)
    }
}


struct ChatBubble<Content>: View where Content: View {
    let direction: ChatBubbleShape.Direction
    let content: () -> Content
    init(direction: ChatBubbleShape.Direction, @ViewBuilder content: @escaping () -> Content) {
        self.content = content
        self.direction = direction
    }
    
    var body: some View {
        HStack {
            if direction == .right {
                Spacer()
            }
            content().clipShape(ChatBubbleShape(direction: direction))
            if direction == .left {
                Spacer()
            }
        }.padding([(direction == .left) ? .leading : .trailing, .top, .bottom], 20)
            .padding((direction == .right) ? .leading : .trailing, 50)
    }
}

// Chat bubble shape
struct ChatBubbleShape: Shape {
    enum Direction {
        case left
        case right
    }
    
    let direction: Direction
    
    func path(in rect: CGRect) -> Path {
        return (direction == .left) ? getLeftBubblePath(in: rect) : getRightBubblePath(in: rect)
    }
    
    private func getLeftBubblePath(in rect: CGRect) -> Path {
        let width = rect.width
        let height = rect.height
        let path = Path { p in
            p.move(to: CGPoint(x: 25, y: height))
            p.addLine(to: CGPoint(x: width - 20, y: height))
            p.addCurve(to: CGPoint(x: width, y: height - 20),
                       control1: CGPoint(x: width - 8, y: height),
                       control2: CGPoint(x: width, y: height - 8))
            p.addLine(to: CGPoint(x: width, y: 20))
            p.addCurve(to: CGPoint(x: width - 20, y: 0),
                       control1: CGPoint(x: width, y: 8),
                       control2: CGPoint(x: width - 8, y: 0))
            p.addLine(to: CGPoint(x: 21, y: 0))
            p.addCurve(to: CGPoint(x: 4, y: 20),
                       control1: CGPoint(x: 12, y: 0),
                       control2: CGPoint(x: 4, y: 8))
            p.addLine(to: CGPoint(x: 4, y: height - 11))
            p.addCurve(to: CGPoint(x: 0, y: height),
                       control1: CGPoint(x: 4, y: height - 1),
                       control2: CGPoint(x: 0, y: height))
            p.addLine(to: CGPoint(x: -0.05, y: height - 0.01))
            p.addCurve(to: CGPoint(x: 11.0, y: height - 4.0),
                       control1: CGPoint(x: 4.0, y: height + 0.5),
                       control2: CGPoint(x: 8, y: height - 1))
            p.addCurve(to: CGPoint(x: 25, y: height),
                       control1: CGPoint(x: 16, y: height),
                       control2: CGPoint(x: 20, y: height))
            
        }
        return path
    }
    
    private func getRightBubblePath(in rect: CGRect) -> Path {
        let width = rect.width
        let height = rect.height
        let path = Path { p in
            p.move(to: CGPoint(x: 25, y: height))
            p.addLine(to: CGPoint(x:  20, y: height))
            p.addCurve(to: CGPoint(x: 0, y: height - 20),
                       control1: CGPoint(x: 8, y: height),
                       control2: CGPoint(x: 0, y: height - 8))
            p.addLine(to: CGPoint(x: 0, y: 20))
            p.addCurve(to: CGPoint(x: 20, y: 0),
                       control1: CGPoint(x: 0, y: 8),
                       control2: CGPoint(x: 8, y: 0))
            p.addLine(to: CGPoint(x: width - 21, y: 0))
            p.addCurve(to: CGPoint(x: width - 4, y: 20),
                       control1: CGPoint(x: width - 12, y: 0),
                       control2: CGPoint(x: width - 4, y: 8))
            p.addLine(to: CGPoint(x: width - 4, y: height - 11))
            p.addCurve(to: CGPoint(x: width, y: height),
                       control1: CGPoint(x: width - 4, y: height - 1),
                       control2: CGPoint(x: width, y: height))
            p.addLine(to: CGPoint(x: width + 0.05, y: height - 0.01))
            p.addCurve(to: CGPoint(x: width - 11, y: height - 4),
                       control1: CGPoint(x: width - 4, y: height + 0.5),
                       control2: CGPoint(x: width - 8, y: height - 1))
            p.addCurve(to: CGPoint(x: width - 25, y: height),
                       control1: CGPoint(x: width - 16, y: height),
                       control2: CGPoint(x: width - 20, y: height))
            
        }
        return path
    }
}


struct ChatInputView: View {
    @Binding var messageText: String
    @ObservedObject var notificationsManager = NotificationsManager.shared
    var onSend: () -> Void
    
    var body: some View {
        HStack {
            TextField("Type a message...", text: $messageText, onEditingChanged: { isEditing in
                notificationsManager.chatEntered = isEditing
            }, onCommit: {
                self.sendAction()
                notificationsManager.chatEntered = false
                messageText = ""
            })
            .font(.system(size: 14))
            .padding(10)
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .padding(.horizontal)
            
            Button(action: sendAction) {
                ZStack {
                    Image(systemName: "circle.fill")
                        .font(.system(size: 45))
                        .fontWeight(.thin)
                        .frame(minWidth: 15, maxWidth: 15)
                        .foregroundColor(Color(red: 249/255, green: 0/255, blue: 98/255))
                        .padding()
                    Image(systemName: "paperplane.circle")
                        .font(.system(size: 45))
                        .fontWeight(.thin)
                        .foregroundColor(.white)
                        .padding()
                }
            }
            .padding(.trailing)
            .frame(minHeight: 20, maxHeight: 20)
        }
        //.padding(.bottom)
    }
    
    private func sendAction() {
        onSend()
        //notificationsManager.chatEntered = false
        messageText = ""
    }
}
