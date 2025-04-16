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
    var messages: [Message]  // Must be mutable to append new messages.
    var hasUnread: Bool
    var lastMessage: Message? {
        messages.last
    }
}

// MARK: - ConversationRow

struct ConversationRow: View {
    let conversation: Conversation
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: conversation.otherUser.profileImageName)
                .resizable()
                .scaledToFit()
                .frame(width: 50, height: 50)
                .clipShape(Circle())
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(conversation.otherUser.username)
                        .font(conversation.hasUnread ? .headline.bold() : .headline)
                    if conversation.hasUnread {
                        // A subtle red dot indicator for unread messages.
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

// MARK: - DirectMessagesView with Auto-Open Chat Support

struct DirectMessagesView: View {
    var userId: String  // The currently authenticated user's id
    // New optional parameter: if provided, automatically open the chat with this user.
    var openConversationWith: UserModel? = nil
    
    enum MessageTab: String, CaseIterable {
         case chats = "Chats"
         case requests = "Requests"
    }
    
    @State private var selectedTab: MessageTab = .chats
    @State private var searchQuery: String = ""
    
    // Accepted conversations (regular chats)
    @State private var acceptedConversations: [Conversation] = {
         let userAlice = UserModel(id: "1", username: "Alice", profileImageName: "person.crop.circle")
         let userBob = UserModel(id: "2", username: "Bob", profileImageName: "person.crop.circle.fill")
         
         let accepted1 = Conversation(
             otherUser: userAlice,
             messages: [
                 Message(text: "Hey, how are you?", senderId: "1", timestamp: Date().addingTimeInterval(-3600)),
                 Message(text: "I'm good, thanks!", senderId: "self", timestamp: Date().addingTimeInterval(-3500))
             ],
             hasUnread: true)
         
         let accepted2 = Conversation(
             otherUser: userBob,
             messages: [
                 Message(text: "Let's meet tomorrow.", senderId: "2", timestamp: Date().addingTimeInterval(-7200)),
                 Message(text: "Sure, sounds good.", senderId: "self", timestamp: Date().addingTimeInterval(-7100))
             ],
             hasUnread: false)
         
         return [accepted1, accepted2]
    }()
    
    // Message requests not yet accepted.
    @State private var messageRequests: [Conversation] = {
         let userCharlie = UserModel(id: "3", username: "Charlie", profileImageName: "person.2.crop.circle")
         let request = Conversation(
             otherUser: userCharlie,
             messages: [
                 Message(text: "Are you free this weekend?", senderId: "3", timestamp: Date().addingTimeInterval(-10800)),
                 Message(text: "I'd love to catch up.", senderId: "3", timestamp: Date().addingTimeInterval(-10700))
             ],
             hasUnread: true)
         return [request]
    }()
    
    // Filtering for accepted chats.
    var filteredAccepted: [Conversation] {
       if searchQuery.isEmpty {
         return acceptedConversations
       } else {
         return acceptedConversations.filter { convo in
             convo.otherUser.username.localizedCaseInsensitiveContains(searchQuery) ||
             (convo.lastMessage?.text.localizedCaseInsensitiveContains(searchQuery) ?? false)
         }
       }
    }
    
    // State to handle auto-navigation.
    @State private var selectedConversationIndex: Int? = nil
    @State private var navigateToChat: Bool = false
    
    var body: some View {
         NavigationView {
             VStack {
                 Picker("Select Tab", selection: $selectedTab) {
                     ForEach(MessageTab.allCases, id: \.self) { tab in
                         Text(tab.rawValue).tag(tab)
                     }
                 }
                 .pickerStyle(SegmentedPickerStyle())
                 .padding()
                 
                 if selectedTab == .chats {
                     List {
                         ForEach(acceptedConversations.indices, id: \.self) { index in
                             NavigationLink(
                                 destination: ChatDetailView(conversation: $acceptedConversations[index], ownUserId: userId)
                             ) {
                                 ConversationRow(conversation: acceptedConversations[index])
                             }
                         }
                     }
                     .listStyle(PlainListStyle())
                     .searchable(text: $searchQuery,
                                 placement: .navigationBarDrawer(displayMode: .always),
                                 prompt: "Search Chats")
                 } else if selectedTab == .requests {
                     // Use your existing MessageRequestsView (imported from a separate file).
                     MessageRequestsView(requests: $messageRequests, userId: userId, onAccept: { convo in
                         if let index = messageRequests.firstIndex(where: { $0.id == convo.id }) {
                             let acceptedConvo = messageRequests.remove(at: index)
                             acceptedConversations.append(acceptedConvo)
                         }
                     })
                 }
                 
                 // Hidden NavigationLink to auto-navigate if a conversation is selected.
                 if let index = selectedConversationIndex {
                     NavigationLink(
                        destination: ChatDetailView(conversation: $acceptedConversations[index], ownUserId: userId),
                        isActive: $navigateToChat,
                        label: { EmptyView() }
                     )
                     .hidden()
                 }
             }
             .navigationTitle("Messages")
         }
         .onAppear {
             // If a specific conversation should be opened...
             if let openUser = openConversationWith, selectedConversationIndex == nil {
                 if let idx = acceptedConversations.firstIndex(where: { $0.otherUser.id == openUser.id }) {
                     selectedConversationIndex = idx
                     navigateToChat = true
                 } else {
                     // Create a new conversation.
                     let newConversation = Conversation(otherUser: openUser, messages: [], hasUnread: false)
                     acceptedConversations.append(newConversation)
                     selectedConversationIndex = acceptedConversations.count - 1
                     navigateToChat = true
                 }
             }
         }
    }
}

struct DirectMessagesView_Previews: PreviewProvider {
    static var previews: some View {
         // For preview, try auto-opening a conversation with a sample user.
         let sampleUser = UserModel(id: "2", username: "Bob", profileImageName: "person.crop.circle.fill")
         DirectMessagesView(userId: "self", openConversationWith: sampleUser)
    }
}
