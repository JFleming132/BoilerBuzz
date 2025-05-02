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
    
    func markMessagesAsRead(convoId: String, userId: String) {
        guard let url = URL(string: "http://54.146.194.154:3000/api/messages/conversations/\(convoId)/markRead") else {
            print("Invalid URL")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "userId": userId
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
        } catch {
            print("Failed to encode body: \(error.localizedDescription)")
            return
        }

        URLSession.shared.dataTask(with: request) { _, response, error in
            if let error = error {
                print("Failed to send mark-read request: \(error.localizedDescription)")
                return
            }

            DispatchQueue.main.async {
                for i in 0..<conversation.messages.count {
                    if conversation.messages[i].sender != userId && !conversation.messages[i].read {
                        conversation.messages[i].read = true
                    }
                }
            }
        }.resume()
    }

    
    func sendMessageBackend(convoId: String, messageText: String, sender: String, other: String) {
        guard let postUrl = URL(string: "http://54.146.194.154:3000/api/messages/conversations/\(convoId)/sendMessage") else {
            print("Invalid URL")
            return
        }
        
        var request = URLRequest(url: postUrl)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "content-type")

        let body: [String: Any] = [
            "messageText": messageText,
            "sender": sender,
            "other": other,
            "read": false
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
        } catch {
            print("Failed to encode body: \(error.localizedDescription)")
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Failed to send message: \(error.localizedDescription)")
                return
            }
            
            guard let data = data else {
                print("No data received from server")
                return
            }
            
            do {
                // First decode the top-level server response
                struct MessageResponse: Decodable {
                    let message: String
                    let messageData: MessageModel
                }
                
                let decoded = try JSONDecoder().decode(MessageResponse.self, from: data)
                let newMsg = decoded.messageData
                DispatchQueue.main.async {
                    conversation.messages.append(newMsg)
                    conversation.lastMessage = newMessage
                    newMessage = ""
                }
                
            } catch {
                print("Failed to decode message response: \(error.localizedDescription)")
                return
            }
        }.resume()
    }

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

            if conversation.status == "accepted" {
                // Input bar
                HStack(spacing: 8) {
                    TextField("Message...", text: $newMessage)
                        .padding(10)
                        .background(Color(UIColor.secondarySystemBackground))
                        .clipShape(Capsule())

                    Button(action: {
                        sendMessageBackend(convoId: conversation.id, messageText: newMessage, sender: ownUserId, other: conversation.otherUser.id)
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
            } else if conversation.initiatorId == ownUserId {
                Text("You can't send messages until \(conversation.otherUser.username) accepts your request.")
                    .font(.footnote)
                    .foregroundColor(.gray)
                    .padding()
            }
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .background(Color(UIColor.systemBackground))
        .navigationBarTitleDisplayMode(.inline)
        .task {
            markMessagesAsRead(convoId: conversation.id, userId: ownUserId)
        }

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

