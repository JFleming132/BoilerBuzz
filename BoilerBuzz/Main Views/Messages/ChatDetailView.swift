//
//  ChatDetailView.swift
//  BoilerBuzz
//
//  Created by Matt Zlatniski on 4/23/25.
//


import SwiftUI

// MARK: - ChatDetailView

struct ChatDetailView: View {
    @Binding var conversation: Conversation
    let ownUserId: String
    @State private var newMessage: String = ""

    var body: some View {
        VStack(spacing: 0) {
            // Top bar with profile image and name
            HStack(spacing: 12) {
                // Profile Image: URL or Base64
                if let str = conversation.otherUser.profileImageURL {
                    if let url = URL(string: str), url.scheme?.hasPrefix("http") == true {
                        AsyncImage(url: url) { phase in
                            if let image = phase.image {
                                image.resizable().scaledToFill()
                            } else {
                                Image(systemName: "person.circle.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 36, height: 36)
                                    .foregroundColor(.gray)
                            }
                        }
                        .frame(width: 36, height: 36)
                        .clipShape(Circle())
                    } else if let data = Data(base64Encoded: str), let uiImg = UIImage(data: data) {
                        Image(uiImage: uiImg)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 36, height: 36)
                            .clipShape(Circle())
                    } else {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 36, height: 36)
                            .foregroundColor(.gray)
                    }
                } else {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 36, height: 36)
                        .foregroundColor(.gray)
                }
                
                Text(conversation.otherUser.username)
                    .font(.headline)
                Spacer()
            }
            .padding()
            .background(Color(UIColor.systemBackground))
            .shadow(color: Color.black.opacity(0.05), radius: 4, y: 4)

            Divider()

            // Message bubbles list
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(conversation.messages) { msg in
                            MessageBubble(
                                text: msg.text,
                                isCurrentUser: msg.sender == ownUserId
                            )
                            .id(msg.id)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                }
                .background(Color(UIColor.systemBackground))
                .onAppear {
                    if let last = conversation.messages.last {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
                .onChange(of: conversation.messages.count) { _ in
                    if let last = conversation.messages.last {
                        withAnimation {
                            proxy.scrollTo(last.id, anchor: .bottom)
                        }
                    }
                }
            }

            // Input bar
            HStack(spacing: 8) {
                TextField("Message...", text: $newMessage)
                    .padding(10)
                    .background(Color(UIColor.secondarySystemBackground))
                    .clipShape(Capsule())

                Button(action: {
                    let newMsg = MessageModel(
                        id: UUID().uuidString,
                        text: newMessage,
                        sender: ownUserId
                    )
                    conversation.messages.append(newMsg)
                    conversation.lastMessage = newMessage
                    newMessage = ""
                }) {
                    Image(systemName: "paperplane.fill")
                        .rotationEffect(.degrees(45))
                        .font(.system(size: 20))
                        .foregroundColor(newMessage.isEmpty ? Color.gray : Color.blue)
                }
                .disabled(newMessage.isEmpty)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .background(Color(UIColor.systemBackground))
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - MessageBubble

struct MessageBubble: View {
    let text: String
    let isCurrentUser: Bool

    var body: some View {
        HStack {
            if isCurrentUser { Spacer(minLength: 80) }

            Text(text)
                .padding(12)
                .background(isCurrentUser ? Color.blue : Color(UIColor.secondarySystemBackground))
                .foregroundColor(isCurrentUser ? .white : .primary)
                .cornerRadius(16)
                .frame(maxWidth: UIScreen.main.bounds.width * 0.7,
                       alignment: isCurrentUser ? .trailing : .leading)

            if !isCurrentUser { Spacer(minLength: 80) }
        }
    }
}

