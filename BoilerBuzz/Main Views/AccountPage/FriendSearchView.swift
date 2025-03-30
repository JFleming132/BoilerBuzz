struct FriendSearchView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var searchQuery: String = ""
    @State private var searchResults: [Friend] = []
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationView {
            VStack {
                TextField("Search by username", text: $searchQuery, onCommit: {
                    performSearch()
                })
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

                if isLoading {
                    ProgressView()
                } else if let error = errorMessage {
                    Text("Error: \(error)")
                        .foregroundColor(.red)
                } else if searchResults.isEmpty {
                    Text("No users found.")
                        .foregroundColor(.gray)
                } else {
                    List(searchResults) { friend in
                        Button(action: {
                            // Trigger add friend action here.
                            addFriend(friend)
                        }) {
                            HStack {
                                // Optionally load profile picture.
                                Image(systemName: "person.crop.circle.fill")
                                    .resizable()
                                    .frame(width: 40, height: 40)
                                Text(friend.name)
                                    .font(.headline)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Search Friends")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }

    func performSearch() {
        // Reset state
        isLoading = true
        errorMessage = nil
        searchResults = []
        
        // Build the URL for your search endpoint.
        guard let url = URL(string: "http://localhost:3000/api/friends/search?username=\(searchQuery)") else {
            errorMessage = "Invalid URL."
            isLoading = false
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            defer { isLoading = false }
            if let error = error {
                DispatchQueue.main.async {
                    errorMessage = error.localizedDescription
                }
                return
            }
            guard let data = data else {
                DispatchQueue.main.async {
                    errorMessage = "No data received."
                }
                return
            }
            
            do {
                let users = try JSONDecoder().decode([Friend].self, from: data)
                DispatchQueue.main.async {
                    self.searchResults = users
                }
            } catch {
                DispatchQueue.main.async {
                    errorMessage = error.localizedDescription
                }
            }
        }.resume()
    }
    
    func addFriend(_ friend: Friend) {
        // Send add friend request to backend.
        // After success, you might want to dismiss the search view.
        presentationMode.wrappedValue.dismiss()
    }
}
