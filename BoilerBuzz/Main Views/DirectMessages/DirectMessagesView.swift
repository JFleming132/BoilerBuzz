//
//  DirectMessagesView.swift
//  BoilerBuzz
//
//  Created by Matt Zlatniski on 4/9/25.
//

import SwiftUI

// MARK: - Models

struct UserModel: Identifiable {
    let id: String
    let username: String
    let profileImageName: String
}

struct Message: Identifiable {
    let id = UUID()
    let text: String
    let senderId: String
    let timestamp: Date
}

struct Conversation: Identifiable {
    let id = UUID()
    let otherUser: UserModel
    var messages: [Message]   // Changed from let to var.
    var hasUnread: Bool
    var lastMessage: Message? {
        messages.last
    }
}


// MARK: - ConversationRow with Professional Unread Indicator

struct ConversationRow: View {
    let conversation: Conversation
    
    var body: some View {
        HStack(spacing: 15) {
            // Profile image.
            Image(systemName: conversation.otherUser.profileImageName)
                .resizable()
                .scaledToFit()
                .frame(width: 50, height: 50)
                .clipShape(Circle())
            
            // Username and last message.
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(conversation.otherUser.username)
                        .font(conversation.hasUnread ? .headline.bold() : .headline)
                    
                    // Unread indicator: a small red dot.
                    if conversation.hasUnread {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 10, height: 10)
                    }
                }
                if let lastMessage = conversation.lastMessage {
                    Text(lastMessage.text)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .lineLimit(1)
                }
            }
            Spacer()
        }
        .padding(.vertical, 8)
    }
}

// MARK: - DirectMessagesView with Search Bar

struct DirectMessagesView: View {
    var userId: String  // The currently authenticated user's id

    // MARK: - Mock Data
    @State private var conversations: [Conversation] = {
        // Sample users.
        let userAlice = UserModel(id: "1", username: "Alice", profileImageName: "person.crop.circle")
        let userBob = UserModel(id: "2", username: "Bob", profileImageName: "person.crop.circle.fill")
        let userCharlie = UserModel(id: "3", username: "Charlie", profileImageName: "person.2.crop.circle")
        
        // Sample messages.
        let messagesAlice = [
            Message(text: "Hey, how are you?", senderId: "1", timestamp: Date().addingTimeInterval(-3600)),
            Message(text: "I'm good, thanks!", senderId: "self", timestamp: Date().addingTimeInterval(-3500))
        ]
        let messagesBob = [
            Message(text: "Let's meet tomorrow.", senderId: "2", timestamp: Date().addingTimeInterval(-7200)),
            Message(text: "Sure, sounds good.", senderId: "self", timestamp: Date().addingTimeInterval(-7100))
        ]
        let messagesCharlie = [
            Message(text: "Are you free this weekend?", senderId: "3", timestamp: Date().addingTimeInterval(-10800)),
            Message(text: "Yes, let's catch up.", senderId: "self", timestamp: Date().addingTimeInterval(-10700))
        ]
        
        // Assemble sample conversations.
        return [
            Conversation(otherUser: userAlice, messages: messagesAlice, hasUnread: true),
            Conversation(otherUser: userBob, messages: messagesBob, hasUnread: false),
            Conversation(otherUser: userCharlie, messages: messagesCharlie, hasUnread: true)
        ]
    }()
    
    @State private var searchQuery: String = ""
    
    // Filter conversations based on the search query.
    var filteredConversations: [Conversation] {
        if searchQuery.isEmpty {
            return conversations
        } else {
            return conversations.filter { convo in
                convo.otherUser.username.localizedCaseInsensitiveContains(searchQuery) ||
                (convo.lastMessage?.text.localizedCaseInsensitiveContains(searchQuery) ?? false)
            }
        }
    }
    
    var body: some View {
        NavigationView {
            List {
                // Iterate through conversations using their indices so we can pass a binding.
                ForEach(conversations.indices, id: \.self) { index in
                    // Apply the same filter using the conversation value.
                    let convo = conversations[index]
                    if searchQuery.isEmpty ||
                       convo.otherUser.username.localizedCaseInsensitiveContains(searchQuery) ||
                       (convo.lastMessage?.text.localizedCaseInsensitiveContains(searchQuery) ?? false)
                    {
                        NavigationLink(
                            destination: ChatDetailView(conversation: $conversations[index], ownUserId: userId)
                        ) {
                            ConversationRow(conversation: convo)
                        }
                    }
                }
            }
            .listStyle(PlainListStyle())
            .navigationTitle("Messages")
            .searchable(
                text: $searchQuery,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "Search Conversations"
            )
        }
    }
}

struct DirectMessagesView_Previews: PreviewProvider {
    static var previews: some View {
        DirectMessagesView(userId: "self")
    }
}
