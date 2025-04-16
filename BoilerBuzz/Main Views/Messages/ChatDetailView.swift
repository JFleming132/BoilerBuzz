
//  ChatDetailView.swift
//  BoilerBuzz
//
//  Created by Matt Zlatniski on 4/9/25.
//

import SwiftUI

struct ChatDetailView: View {
    // Accept a binding so that changes propagate back.
    @Binding var conversation: Conversation
    let ownUserId: String  // The logged-in user's ID
    
    @State private var messages: [Message]
    @State private var newMessage: String = ""
    
    // Initialize the state with the conversation’s messages.
    init(conversation: Binding<Conversation>, ownUserId: String) {
        self._conversation = conversation
        self.ownUserId = ownUserId
        _messages = State(initialValue: conversation.wrappedValue.messages)
    }
    
    var body: some View {
        VStack {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(messages) { message in
                            ChatBubble(message: message, isCurrentUser: message.senderId == ownUserId)
                                .id(message.id)
                        }
                    }
                    .padding(.vertical)
                }
                .onChange(of: messages.count) { _ in
                    // Scroll to the latest message when a new message is added.
                    if let lastMessage = messages.last {
                        withAnimation {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
                .background(Color(UIColor.systemBackground))
            }
            
            Divider()
            
            // Input area for new messages.
            HStack {
                TextField("Type a message...", text: $newMessage)
                    .padding(10)
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(20)
                
                Button(action: sendMessage) {
                    Text("Send")
                        .bold()
                }
            }
            .padding()
        }
        .navigationTitle(conversation.otherUser.username)
        .navigationBarTitleDisplayMode(.inline)
        // Mark the conversation as read on appear.
        .onAppear {
            conversation.hasUnread = false
        }
    }
    
    func sendMessage() {
        let trimmedMessage = newMessage.trimmingCharacters(in: .whitespaces)
        guard !trimmedMessage.isEmpty else { return }
        
        let message = Message(text: trimmedMessage, senderId: ownUserId, timestamp: Date())
        // Append the new message to the local state.
        messages.append(message)
        // Also update the conversation binding so the new message is persisted.
        conversation.messages.append(message)
        newMessage = ""
    }
}

// A view representing a single chat bubble.
struct ChatBubble: View {
    var message: Message
    var isCurrentUser: Bool
    
    var body: some View {
        HStack {
            if isCurrentUser {
                Spacer(minLength: 50)
                Text(message.text)
                    .padding(10)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(16)
                    .frame(maxWidth: UIScreen.main.bounds.width * 0.7, alignment: .trailing)
            } else {
                Text(message.text)
                    .padding(10)
                    .background(Color.gray.opacity(0.3))
                    .foregroundColor(.black)
                    .cornerRadius(16)
                    .frame(maxWidth: UIScreen.main.bounds.width * 0.7, alignment: .leading)
                Spacer(minLength: 50)
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - Preview

struct ChatDetailView_Previews: PreviewProvider {
    // Sample preview data for ChatDetailView.
    @State static var sampleConversation = Conversation(
        otherUser: UserModel(id: "2", username: "Bob", profileImageName: "person.crop.circle.fill"),
        messages: [
            Message(text: "Hello, how are you?", senderId: "2", timestamp: Date()),
            Message(text: "I’m doing well!", senderId: "self", timestamp: Date())
        ],
        hasUnread: true
    )
    
    static var previews: some View {
        NavigationView {
            ChatDetailView(conversation: $sampleConversation, ownUserId: "self")
        }
    }
}
