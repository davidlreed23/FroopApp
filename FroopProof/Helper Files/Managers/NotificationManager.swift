//
//  notificationsManager.swift
//  FroopProof
//
//  Created by David Reed on 3/12/23.
//

import Foundation
import Firebase
import FirebaseFirestore
import UserNotifications
import UIKit
import SwiftUI

class NotificationsManager: ObservableObject {
    static let shared = NotificationsManager()
    @ObservedObject var appStateManager = AppStateManager.shared
    @ObservedObject var firebaseServices = FirebaseServices.shared
    @ObservedObject var printControl = PrintControl.shared
    @ObservedObject var froopDataListener = FroopDataListener.shared
    @Published var chatCount: Int = 0
    @Published var conversationsAndMessages: [ConversationAndMessages] = []
    @Published var conversationExists: Bool = false
    @Published var bringScrollDown: Bool = true
    @Published var chatEntered: Bool = false
    
    //MARK: badges app wide
    //MARK: Froop badges
    @Published var homeInvites: Int = 0  //@User You have recieved an invitation to a Froop
    @Published var homeConfirmed: Int = 0  //@Host Friend has confirmed your invitation
    @Published var homeDeclined: Int = 0  //@Host Friend has declined your invitation
    @Published var activeFroopPreGame: Int = 0  //@User Froop Notice Message it will start in 30 minutes
    ////@Published var activeFroopEnding: Int = 0  //@User Froop Notice Message it will end in 30 mintues
    ////@Published var activeFroopHostMessage: Int = 0 //@AllConfirmed Host sends message to everyone attending
    ////@Published var activeFroopMessages: Int = 0 //@User Everyone that sent you a message in the Froop
    ////@Published var activeFroopChanges: Int = 0  //@AllConfirmed Host changes a detail about the Froop
    @Published var activeFroopPinDrop: Int = 0  //@User Someone Dropped a Pin on the Map
    @Published var froopImageAdded: Int = 0  //@User Someone uploaded a picture to the froop
    ////@Published var froopVideoAdded: Int = 0 //@User Someone uploaded a video to the froop
    ////@Published var froopPublished: Int = 0  //@AllConfirmed Host publishes froop for sharing in feed
    
    //MARK: Friend Badges
    @Published var newFriendRequest: Int = 0 //@User you have a new friend request waiting
    @Published var newFriendAccept: Int = 0  //@Sending User A friend you invited has accepted
    @Published var newFriendJoined: Int = 0  //@Sending User A friend you invited by SMS has joined
    //@Published var newFriendDeclined: Int = 0  //@Sending User A friend you invited has declined
    //@Published var newAcquaintanceJoined: Int = 0  //@User Someone you know has joined Froop
    
    //MARK: Communication Badges
    //@Published var friendMessage: Int = 0  //@User a friend has messaged you in Froop
    //@Published var friendMessages: Int = 0  //@User aggregate of all messages sent to you in Froop
    //@Published var froopHostMessage: Int = 0  //@User Host from inactive froop has sent a message to all invited / confirmed users
    //@Published var systemMessage: Int = 0  //@User Froop System Message
    

    @Published var badgeCounts: [Tab: Int] = [
//        .make: 0,
//        .person: 0,
        .froop: 0,
    ]
    
    let db = FirebaseServices.shared.db
    let uid = FirebaseServices.shared.uid
    
    private var conversationListeners: [String: ListenerRegistration] = [:]
    
    
    init() {
        guard let uid = Auth.auth().currentUser?.uid else {
            // Handle the case where there's no logged in user
            return
        }
        
        RefPath.chatStoreDocRef(uid: uid).addSnapshotListener { documentSnapshot, error in
            guard let document = documentSnapshot else {
                print("Error fetching chat store: \(error!)")
                return
            }
            
            let data = document.data()
            let chatIds = data?["chats"] as? [String] ?? []
            
            // For each chatId, if it is not already being listened to, create a new listener
            for chatId in chatIds {
                if self.conversationListeners[chatId] == nil {
                    self.conversationListeners[chatId] = self.fetchMessagesAndConversations(for: chatId)
                }
            }
            
            // For each existing listener, if its conversation ID is not in the chatIds, remove the listener
            for (chatId, listener) in self.conversationListeners {
                if !chatIds.contains(chatId) {
                    listener.remove()
                    self.conversationListeners.removeValue(forKey: chatId)
                    // Also remove the conversation and its messages from the array
                    self.conversationsAndMessages.removeAll(where: { $0.id == chatId })
                }
            }
        }
    }
    
    deinit {
        for (_, listener) in conversationListeners {
            listener.remove()
        }
    }
    
    func resetBadgeCountForUser(uid: String) {
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(uid)
        
        userRef.updateData([
            "badgeCount": 0
        ]) { err in
            if let err = err {
                print("Error updating document: \(err)")
            } else {
                print("Document successfully updated")
            }
        }
    }
    
    func fetchChatStoreData(uid: String, completion: @escaping (ChatStoreData?, Error?) -> Void) {
        RefPath.chatStoreDocRef(uid: uid).getDocument { (snapshot, error) in
            if let error = error {
                completion(nil, error)
            } else if let snapshot = snapshot, let data = snapshot.data() {
                let chats = data["chats"] as? [String] ?? []
                let chatStoreData = ChatStoreData(chats: chats)
                completion(chatStoreData, nil)
            }
        }
    }
    
    func updateChatStoreData(uid: String, chatStoreData: ChatStoreData, completion: @escaping (Error?) -> Void) {
        RefPath.chatStoreDocRef(uid: uid).setData([
            "chatIds": chatStoreData.chats
        ]) { error in
            completion(error)
        }
    }
    
    func fetchMessagesAndConversations(for conversationId: String) -> ListenerRegistration {
        print("Fetching messages and conversations for conversation ID: \(conversationId)") // Add this line
        let listener = RefPath.messagesColRef(conversationId: conversationId)
            .order(by: "timestamp")
            .addSnapshotListener { [weak self] querySnapshot, error in
                guard let self = self else { return }

                if let error = error {
                    print("Error fetching messages: \(error)")
                    return
                }

                let messages = querySnapshot?.documents.compactMap { Message(document: $0) } ?? []
                
                // Fetch the conversation
                RefPath.conversationDocRef(conversationId: conversationId).getDocument { (document, error) in
                    if let document = document, document.exists {
                        let conversation = Conversation(document: document)
                        // Find the ConversationAndMessages object and update it
                        if let index = self.conversationsAndMessages.firstIndex(where: { $0.id == conversationId }) {
                            self.conversationsAndMessages[index].messages = messages
                        } else {  // If it doesn't exist, add a new one
                            let conversationAndMessages = ConversationAndMessages(conversation: conversation, messages: messages)
                            self.conversationsAndMessages.append(conversationAndMessages)
                        }
                    } else {
                        print("Document does not exist or unable to convert to Conversation")
                    }
                }
            }

        return listener
    }
    
    func sendMessage(content: String) {
        if content == "" {
            return
        }
        print("Conversation Exists? : \(conversationExists)")
        if conversationExists {
            print("Printing conversationsAndMessages array contents:")
            for (index, convAndMsg) in conversationsAndMessages.enumerated() {
                print("Index: \(index)")
                print("Conversation ID: \(convAndMsg.conversation.id)")
                print("User ID: \(convAndMsg.conversation.userId)")
                print("Guest ID: \(convAndMsg.conversation.guestId)")
                print("Printing Messages in this conversation:")
                for msg in convAndMsg.messages {
                    print("Message ID: \(msg.id), Sender ID: \(msg.senderId), Receiver ID: \(msg.receiverId), Content: \(msg.text), Timestamp: \(msg.timestamp)")
                }
                print("--- End of conversation ---")
            }
            // Find the conversation ID of the current conversation
            if let conversationId = conversationsAndMessages.first(where: { ($0.conversation.userId == uid || $0.conversation.guestId == uid) && ($0.conversation.userId == appStateManager.chatWith.froopUserID || $0.conversation.guestId == appStateManager.chatWith.froopUserID) })?.conversation.id {
                postMessage(content: content, conversationId: conversationId)
                // Send push notification after successfully posting the message
                NotificationsManager.sendPushNotification(
                    to: self.appStateManager.chatWith.fcmToken,  // Pass the FCM token instead of user ID
                    title: "New Message from \(self.appStateManager.chatWith.firstName)",
                    body: content,
                    data: ["conversationId": conversationId] // Use conversationId instead of conversationRef.documentID
                )
            }

        } else {
            createNewConversation(content: content)
        }
    }
    
    func createNewConversation(content: String) {
        // Create a new conversation document
        let newConversationRef = db.collection("conversations").document()
        let newConversationData: [String: Any] = ["userId": uid, "guestId": appStateManager.chatWith.froopUserID]
        newConversationRef.setData(newConversationData)

        // Add the ID of the new conversation to the 'chats' array of both users
        let currentUserChatStoreRef = RefPath.chatStoreDocRef(uid: uid)
        let otherUserChatStoreRef = RefPath.chatStoreDocRef(uid: appStateManager.chatWith.froopUserID)
        currentUserChatStoreRef.setData(["chats": FieldValue.arrayUnion([newConversationRef.documentID])], merge: true)
        otherUserChatStoreRef.setData(["chats": FieldValue.arrayUnion([newConversationRef.documentID])], merge: true)

        // Post the first message
        postMessage(content: content, conversationId: newConversationRef.documentID)

        // Set the conversationExists flag to true
        conversationExists = true
    }
    
    func postMessage(content: String, conversationId: String) {
        // Create a reference to the conversation document
        print("conversationId: \(conversationId)")
        let conversationRef = db.collection("conversations").document(conversationId)
        
        print("Posting message to conversation: \(conversationId)") // Log the conversation ID
        
        // Add a new message to the conversation
        conversationRef.collection("messages").addDocument(data: [
            "senderId": uid,
            "receiverId": appStateManager.chatWith.froopUserID,
            "text": content,
            "timestamp": FieldValue.serverTimestamp(),
            "froopId": appStateManager.inProgressFroop.froopId,
            "conversationId": conversationId
        ]) { error in
            if let error = error {
                print("Error sending message: \(error)")
                return
            }
            
            print("Message posted successfully") // Log success
            
            // Send push notification after successfully posting the message
            NotificationsManager.sendPushNotification(
                to: self.appStateManager.chatWith.fcmToken,  // Pass the FCM token instead of user ID
                title: "New Message from \(self.appStateManager.chatWith.firstName)",
                body: content,
                data: ["conversationId": conversationId] // Use conversationId instead of conversationRef.documentID
            )
        }
    }

    
    static func sendPushNotification(to token: String, title: String, body: String, data: [String: Any]) {
        let urlString = "https://fcm.googleapis.com/fcm/send"
        let url = NSURL(string: urlString)!
        let paramString: [String: Any] = ["to": token,
                                          "notification": ["title": title, "body": body],
                                          "data": data]
        let request = NSMutableURLRequest(url: url as URL)
        request.httpMethod = "POST"
        request.httpBody = try? JSONSerialization.data(withJSONObject:paramString, options: [.prettyPrinted])
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("key=TYMUNU9WWS", forHTTPHeaderField: "Authorization")
        
        let task = URLSession.shared.dataTask(with: request as URLRequest) { (data, response, error) in
            do {
                if let jsonData = data {
                    if let json = try JSONSerialization.jsonObject(with: jsonData, options: [.allowFragments]) as? [String: Any] {
                        print(json)
                    }
                }
            } catch let error {
                print("Error serializing JSON: \(error)")
            }
        }
        task.resume()
    }
}
