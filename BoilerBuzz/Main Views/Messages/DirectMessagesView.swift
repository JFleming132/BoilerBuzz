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
    @Published var availableUsers: [UserModel] = []
    @Published var errorMessage: String?
    @Published var isLoadingConversations: Bool = false
    @Published var isLoadingUsers: Bool = false


    /// Fetch conversations including message lists
    func fetchConversations(userId: String) {
        guard let url = URL(string: "http://localhost:3000/api/messages/getConversations?userId=\(userId)") else {
            errorMessage = "Invalid URL"
            return
        }
        isLoadingConversations = true
        let decoder = JSONDecoder()
        URLSession.shared.dataTask(with: url) { data, _, error in
            DispatchQueue.main.async {
                self.isLoadingConversations = false
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
    
    func fetchAvailableUsers(userId: String) {
        guard let url = URL(string: "http://localhost:3000/api/messages/getAvailableUsers?userId=\(userId)") else {
            errorMessage = "Invalid URL"
            return
        }
        isLoadingUsers = true
        URLSession.shared.dataTask(with: url) { data, _, error in
            DispatchQueue.main.async {
                self.isLoadingUsers = false
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    return
                }
                guard let data = data else {
                    self.errorMessage = "No data received"
                    return
                }
                do {
                    self.availableUsers = try JSONDecoder().decode([UserModel].self, from: data)
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
    var navigateToUserId: String? = nil
    
    @StateObject private var viewModel = DirectMessagesViewModel()
    @State private var searchQuery: String = ""
    @State private var showNewConversationSheet = false
    @State private var selectedUser: UserModel? = nil
    @State private var initialMessage: String = ""
    @State private var errorText: String? = nil

    @State private var messageSearchQuery: String = ""
    @State private var newUserSearchQuery: String = ""

    private var filteredConversations: [Conversation] {
        guard !messageSearchQuery.isEmpty else { return viewModel.conversations }
        return viewModel.conversations.filter { convo in
            convo.otherUser.username.localizedCaseInsensitiveContains(messageSearchQuery)
        }
    }

    private var matchingUsers: [UserModel] {
        guard !newUserSearchQuery.isEmpty else { return [] }
        return viewModel.availableUsers.filter { user in
            user.username.localizedCaseInsensitiveContains(newUserSearchQuery)
        }
    }

    var body: some View {
        NavigationView {
            Group {
                if viewModel.isLoadingConversations || viewModel.isLoadingUsers {
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
                    .searchable(text: $messageSearchQuery, prompt: "Search…")
                }
            }
            .navigationTitle("Messages")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showNewConversationSheet = true
                    }) {
                        Image(systemName: "plus.message.fill")
                            .font(.title2)
                    }
                }
            }
            .sheet(isPresented: $showNewConversationSheet) {
                NavigationStack {
                    VStack(spacing: 20) {
                        Text("Start New Conversation")
                            .font(.title2.bold())
                            .padding(.top)

                        TextField("Enter username", text: $newUserSearchQuery)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding(.horizontal)

                        if !matchingUsers.isEmpty {
                            List(matchingUsers) { user in
                                Button {
                                    selectedUser = user
                                    searchQuery = user.username
                                } label: {
                                    HStack {
                                        ProfileImageView(urlString: user.profileImageURL)
                                        Text(user.username)
                                        Spacer()
                                        if selectedUser?.id == user.id {
                                            Image(systemName: "checkmark")
                                                .foregroundColor(.blue)
                                        }
                                    }
                                }
                            }
                            .frame(height: 200)
                        }

                        TextField("Initial message...", text: $initialMessage, axis: .vertical)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding(.horizontal)

                        if let errorText = errorText {
                            Text(errorText)
                                .foregroundColor(.red)
                                .font(.caption)
                        }

                        Button("Start Chat") {
                            createNewConversation()
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(selectedUser == nil || initialMessage.isEmpty)

                        Button("Cancel", role: .cancel) {
                            resetSheet()
                        }
                        .padding(.top, 8)
                    }
                    .navigationBarHidden(true)
                }
            }
            .task {
                if viewModel.conversations.isEmpty {
                    viewModel.fetchConversations(userId: userId)
                }
                if viewModel.availableUsers.isEmpty {
                    viewModel.fetchAvailableUsers(userId: userId)
                }
            }
        }
    }

    private func createNewConversation() {
        guard let validUser = selectedUser else {
            errorText = "Please select a user."
            return
        }
        
        guard !initialMessage.isEmpty else {
            errorText = "Please enter an initial message."
            return
        }
        
        guard let url = URL(string: "http://localhost:3000/api/messages/startConversation") else {
            errorText = "Invalid server URL."
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "initiator": userId,
            "recipient": validUser.id,
            "messageText": initialMessage
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
        } catch {
            errorText = "Failed to encode request."
            return
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    self.errorText = "Request failed: \(error.localizedDescription)"
                    return
                }
                guard let data = data else {
                    self.errorText = "No response from server."
                    return
                }
                do {
                    let apiConvo = try JSONDecoder().decode(APIConversation.self, from: data)
                    let mappedMessages = apiConvo.messages.map { msg in
                        MessageModel(id: msg.id, text: msg.text, sender: msg.sender)
                    }
                    let newConversation = Conversation(
                        id: apiConvo.id,
                        otherUser: UserModel(
                            id: apiConvo.otherUser.id,
                            username: apiConvo.otherUser.username,
                            profileImageURL: apiConvo.otherUser.profilePicture
                        ),
                        lastMessage: apiConvo.lastMessage,
                        messages: mappedMessages
                    )
                    self.viewModel.conversations.append(newConversation)
                    self.viewModel.availableUsers.removeAll { $0.id == validUser.id }
                    self.resetSheet()
                } catch {
                    self.errorText = "Failed to decode server response."
                }
            }
        }.resume()
    }

    private func resetSheet() {
        showNewConversationSheet = false
        selectedUser = nil
        searchQuery = ""
        initialMessage = ""
        errorText = nil
    }
}
