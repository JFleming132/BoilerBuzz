import SwiftUI
import UIKit

// MARK: - Models

/// Simple message model with id, text, sender
struct MessageModel: Identifiable, Decodable {
    let id: String
    let text: String
    let sender: String
}

/// User model
struct UserModel: Identifiable, Decodable {
    let id: String
    let username: String
    let profileImageURL: String?
}

// MARK: - API Decodable Structures

/// Decodable version of a message from API
private struct APIMessage: Decodable {
    let id: String
    let text: String
    let sender: String
}

/// Decodable version of a user from API
private struct APIUser: Decodable {
    let id: String
    let username: String
    let profilePicture: String?
}

/// Decodable version of a conversation from API
private struct APIConversation: Decodable {
    let id: String
    let otherUser: APIUser
    let lastMessage: String
    let messages: [APIMessage]
}

// MARK: - App Conversation Model

/// Conversation model used in UI
struct Conversation: Identifiable {
    let id: String
    let otherUser: UserModel
    var lastMessage: String
    var messages: [MessageModel] = []
}

// MARK: - ViewModel

final class DirectMessagesViewModel: ObservableObject {
    @Published var conversations: [Conversation] = []
    @Published var errorMessage: String?
    @Published var isLoading: Bool = false

    /// Fetch conversations including message lists
    func fetchConversations(userId: String) {
        guard let url = URL(string: "http://localhost:3000/api/messages/getConversations?userId=\(userId)") else {
            errorMessage = "Invalid URL"
            return
        }
        isLoading = true
        let decoder = JSONDecoder()
        URLSession.shared.dataTask(with: url) { data, _, error in
            DispatchQueue.main.async {
                self.isLoading = false
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    return
                }
                guard let data = data else {
                    self.errorMessage = "No data received"
                    return
                }
                do {
                    let apiConvos = try decoder.decode([APIConversation].self, from: data)
                    self.conversations = apiConvos.map { api in
                        let mappedMessages = api.messages.map { msg in
                            MessageModel(id: msg.id, text: msg.text, sender: msg.sender)
                        }
                        return Conversation(
                            id: api.id,
                            otherUser: UserModel(
                                id: api.otherUser.id,
                                username: api.otherUser.username,
                                profileImageURL: api.otherUser.profilePicture
                            ),
                            lastMessage: api.lastMessage,
                            messages: mappedMessages
                        )
                    }
                } catch {
                    self.errorMessage = error.localizedDescription
                }
            }
        }.resume()
    }
}

// MARK: - ProfileImageView

struct ProfileImageView: View {
    let urlString: String?

    var body: some View {
        if let str = urlString {
            if let url = URL(string: str), url.scheme?.hasPrefix("http") == true {
                AsyncImage(url: url) { phase in
                    if let image = phase.image {
                        image.resizable().scaledToFill()
                    } else {
                        Image(systemName: "person.circle").resizable().scaledToFit()
                    }
                }
                .frame(width: 50, height: 50)
                .clipShape(Circle())
            } else if let data = Data(base64Encoded: str), let uiImg = UIImage(data: data) {
                Image(uiImage: uiImg)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 50, height: 50)
                    .clipShape(Circle())
            } else {
                Image(systemName: "person.circle")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 50, height: 50)
                    .clipShape(Circle())
            }
        } else {
            Image(systemName: "person.circle")
                .resizable()
                .scaledToFit()
                .frame(width: 50, height: 50)
                .clipShape(Circle())
        }
    }
}

// MARK: - ConversationRow

struct ConversationRow: View {
    let convo: Conversation

    var body: some View {
        HStack(spacing: 15) {
            ProfileImageView(urlString: convo.otherUser.profileImageURL)
            VStack(alignment: .leading, spacing: 4) {
                Text(convo.otherUser.username)
                    .font(.headline)
                Text(convo.lastMessage)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            Spacer()
        }
        .padding(.vertical, 6)
    }
}

// MARK: - DirectMessagesView

struct DirectMessagesView: View {
    let userId: String
    @StateObject private var viewModel = DirectMessagesViewModel()
    @State private var searchQuery: String = ""

    private var filteredConversations: [Conversation] {
        guard !searchQuery.isEmpty else { return viewModel.conversations }
        return viewModel.conversations.filter { convo in
            convo.otherUser.username.localizedCaseInsensitiveContains(searchQuery)
        }
    }

    var body: some View {
        NavigationView {
            Group {
                if viewModel.isLoading {
                    ProgressView("Loading…")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let error = viewModel.errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding()
                } else {
                    List(filteredConversations) { convo in
                        if let index = viewModel.conversations.firstIndex(where: { $0.id == convo.id }) {
                            NavigationLink(
                                destination: ChatDetailView(conversation: $viewModel.conversations[index], ownUserId: userId)
                            ) {
                                ConversationRow(convo: convo)
                            }
                        }
                    }
                    .listStyle(PlainListStyle())
                    .searchable(text: $searchQuery, prompt: "Search…")
                }
            }
            .navigationTitle("Messages")
        }
        .onAppear {
            viewModel.fetchConversations(userId: userId)
        }
    }
}
