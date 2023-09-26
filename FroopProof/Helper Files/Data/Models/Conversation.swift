//
//  Conversation.swift
//  FroopProof
//
//  Created by David Reed on 7/25/23.
//

import SwiftUI
import Firebase
import FirebaseFirestore


struct Conversation: Identifiable {
    var id: String
    var userId: String
    var guestId: String

    // initialize with Firestore document
    init(document: DocumentSnapshot) {
        self.id = document.documentID
        self.userId = document.get("userId") as? String ?? ""
        self.guestId = document.get("guestId") as? String ?? ""
    }
    
    // initialize with separate parameters
    init(id: String, userId: String, guestId: String) {
        self.id = id
        self.userId = userId
        self.guestId = guestId
    }
}

struct ConversationAndMessages: Identifiable {
    var id: String { conversation.id }  // Use conversation's id as the identifier
    var conversation: Conversation
    var messages: [Message]
}

struct ChatStoreData {
    var chats: [String] // Array to hold the conversation IDs
}
