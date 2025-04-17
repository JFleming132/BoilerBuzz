import SwiftUI
import UIKit

// MARK: - Models

struct UserModel: Identifiable, Decodable {
    let id: String
    let username: String
    let profileImageURL: String?
}

private struct APIUser: Decodable {
    let id: String
    let username: String
    let profilePicture: String?
}

private struct APIConversation: Decodable {
    let id: String
    let otherUser: APIUser
    let lastMessage: String
}

struct Conversation: Identifiable {
    let id: String
    let otherUser: UserModel
    let lastMessage: String
}

// MARK: - ViewModel

final class DirectMessagesViewModel: ObservableObject {
    @Published var conversations: [Conversation] = []
    @Published var errorMessage: String?
    @Published var isLoading: Bool = false

    func fetchConversations(userId: String) {
        guard let url = URL(string: "http://localhost:3000/api/messages/getConversations?userId=\(userId)") else {
            self.errorMessage = "Invalid URL"
            return
        }
        isLoading = true
        URLSession.shared.dataTask(with: url) { data, response, error in
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
                    let apiConvos = try JSONDecoder().decode([APIConversation].self, from: data)
                    self.conversations = apiConvos.map { api in
                        Conversation(
                            id: api.id,
                            otherUser: UserModel(
                                id: api.otherUser.id,
                                username: api.otherUser.username,
                                profileImageURL: api.otherUser.profilePicture
                            ),
                            lastMessage: api.lastMessage
                        )
                    }
                } catch {
                    self.errorMessage = error.localizedDescription
                }
            }
        }.resume()
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
                    ProgressView("Loading...")
                } else if let error = viewModel.errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding()
                } else {
                    List(filteredConversations) { convo in
                        HStack(spacing: 15) {
                            // Profile Image: URL or Base64
                            if let str = convo.otherUser.profileImageURL {
                                // Remote URL
                                if let url = URL(string: str), let scheme = url.scheme, scheme.hasPrefix("http") {
                                    AsyncImage(url: url) { phase in
                                        if let image = phase.image {
                                            image.resizable().scaledToFill()
                                        } else {
                                            Image(systemName: "person.circle").resizable().scaledToFit()
                                        }
                                    }
                                    .frame(width: 50, height: 50)
                                    .clipShape(Circle())
                                }
                                // Base64 Image
                                else if let data = Data(base64Encoded: str), let uiImg = UIImage(data: data) {
                                    Image(uiImage: uiImg)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 50, height: 50)
                                        .clipShape(Circle())
                                } else {
                                    // Fallback placeholder
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
                            VStack(alignment: .leading, spacing: 2) {
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
                        .padding(.horizontal, 4)
                    }
                    .listStyle(PlainListStyle())
                    .searchable(text: $searchQuery, prompt: "Search")
                }
            }
            .navigationTitle("Messages")
        }
        .onAppear {
            viewModel.fetchConversations(userId: userId)
        }
    }
}

struct DirectMessagesView_Previews: PreviewProvider {
    static var previews: some View {
        DirectMessagesView(userId: "self")
    }
}
