//
//  MessageRequestsView.swift
//  BoilerBuzz
//
//  Created by Matt Zlatniski on 4/16/25.
//


//  MessageRequestsView.swift
//  BoilerBuzz
//
//  Created by Matt Zlatniski on 4/15/25.
//

import SwiftUI

struct MessageRequestsView: View {
    // Bind to the parent's pending requests array so that changes propagate.
    @Binding var requests: [Conversation]
    let userId: String
    // The onAccept closure will let the parent remove the request and add it to the accepted list.
    let onAccept: (Conversation) -> Void
    
    @State private var searchQuery: String = ""
    
    // Filter requests based on the search query.
    var filteredRequests: [Conversation] {
        if searchQuery.isEmpty {
            return requests
        } else {
            return requests.filter { convo in
                convo.otherUser.username.localizedCaseInsensitiveContains(searchQuery) ||
                (convo.lastMessage?.text.localizedCaseInsensitiveContains(searchQuery) ?? false)
            }
        }
    }
    
    var body: some View {
        List {
            // Use filteredResults; for each conversation, determine its index in the full binding.
            ForEach(filteredRequests) { convo in
                HStack {
                    // Find the original binding index using the conversation's unique id.
                    if let index = requests.firstIndex(where: { $0.id == convo.id }) {
                        NavigationLink(destination: ChatDetailView(conversation: $requests[index], ownUserId: userId)) {
                            ConversationRow(conversation: convo)
                        }
                    }
                    Spacer()
                    Button(action: {
                        // Call the parent's onAccept to process moving this conversation to accepted chats.
                        onAccept(convo)
                    }) {
                        Text("Accept")
                            .foregroundColor(.blue)
                    }
                    .buttonStyle(BorderlessButtonStyle())
                }
            }
        }
        .listStyle(PlainListStyle())
        .searchable(text: $searchQuery,
                    placement: .navigationBarDrawer(displayMode: .always),
                    prompt: "Search Requests")
    }
}

// MARK: - Preview

struct MessageRequestsView_Previews: PreviewProvider {
    @State static var sampleRequests: [Conversation] = {
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
    
    static var previews: some View {
        NavigationView {
            MessageRequestsView(requests: $sampleRequests, userId: "self") { convo in
                // In preview, the accept action can simply remove the request.
                if let index = sampleRequests.firstIndex(where: { $0.id == convo.id }) {
                    sampleRequests.remove(at: index)
                }
            }
        }
    }
}
