import SwiftUI
import PhotosUI
import MapKit
import UIKit


//api data for harrys
struct APIResponse: Codable {
    let peopleInBar: Int?
    let peopleInLine: Int?
    let lastUpdated: Date?
    let message: String?
    
    enum CodingKeys: String, CodingKey {
        case peopleInBar = "people_in_bar"
        case peopleInLine = "people_in_line"
        case lastUpdated = "last_updated"
        case message
    }
}
// Event Struct
struct Event: Identifiable, Codable {
    //DONE: Add author, currentRSVPcount, and promoted status
    let id: String
    let author: String
    let rsvpCount: Int
    let title: String
    let description: String?
    let location: String
    let capacity: Int
    let is21Plus: Bool
    let promoted: Bool
    let date: Date
    let imageUrl: String?
    let authorUsername: String
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case title, author, rsvpCount, description, location, capacity, is21Plus, promoted, date, imageUrl, authorUsername
    }

    // Convert Base64 string to UIImage
    var eventImage: UIImage? {
        guard let imageUrl = imageUrl, let imageData = Data(base64Encoded: imageUrl) else {
            return nil
        }
        return UIImage(data: imageData)
    }
}

// Home View with Tabs
struct HomeView: View {
    @State private var selectedTab = 0
    @State private var isCreatingEvent = false
    @State private var events: [Event] = []
    @State private var errorMessage: String?
    
    @State private var selectedEvent: Event? = nil
    @State private var showEventDetail: Bool = false

    
    var eventToView: String? = nil
    
    @ViewBuilder
    private func NavigationDestinationView() -> some View {
        if let event = selectedEvent {
            EventDetailView(event: event)
        } else {
            EmptyView()
        }
    }


    var body: some View {
        NavigationStack {
            VStack {
                // Custom Top Tab Bar
                HStack {
                    Button(action: { selectedTab = 0 }) {
                        VStack {
                            Image(systemName: "calendar")
                            Text("Events")
                        }
                        .foregroundColor(selectedTab == 0 ? .blue : .gray)
                    }
                    .frame(maxWidth: .infinity)

                    Button(action: { selectedTab = 1 }) {
                        VStack {
                            Image(systemName: "cup.and.saucer")
                            Text("Harry's")
                        }
                        .foregroundColor(selectedTab == 1 ? .blue : .gray)
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding()
                .background(Color(uiColor: UIColor.systemBackground))
                .shadow(radius: 2)

                // Tab Content
                ZStack {
                    if selectedTab == 0 {
                        EventsTab(
                            events: events,
                            errorMessage: errorMessage,
                            isCreatingEvent: $isCreatingEvent,
                            fetchEvents: fetchEvents
                        )
                    } else if selectedTab == 1 {
                        HarrysView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(uiColor: UIColor.systemBackground))
                
            }
            .onAppear {
                fetchEvents()
            }
            .navigationDestination(isPresented: $showEventDetail) {
                if let event = selectedEvent {
                    EventDetailView(event: event)
                }
            }

        }
    }


    private func fetchEvents() {
        guard let url = URL(string: "http://localhost:3000/api/home/events") else {
            errorMessage = "Invalid API URL"
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        if let token = UserDefaults.standard.string(forKey: "authToken") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    self.errorMessage = "Error fetching events: \(error.localizedDescription)"
                }
                return
            }

            guard let data = data else {
                DispatchQueue.main.async {
                    self.errorMessage = "No data received"
                }
                return
            }

            do {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .millisecondsSince1970
                
                let fetchedEvents = try decoder.decode([Event].self, from: data)
                DispatchQueue.main.async {
                    self.events = fetchedEvents.filter { $0.date >= Date() }
                    self.errorMessage = nil
                    if let targetId = eventToView,
                        let matched = self.events.first(where: { $0.id == targetId }) {
                        self.selectedEvent = matched
                        self.showEventDetail = true
                    }
                }
            } catch {
                print("JSON Decoding Error: \(error)")
                DispatchQueue.main.async {
                    self.errorMessage = "JSON Decoding Error: \(error.localizedDescription)"
                }
            }
        }.resume()
    }
}

// Events Tab
struct EventsTab: View {
    let events: [Event]
    let errorMessage: String?
    @Binding var isCreatingEvent: Bool
    var fetchEvents: () -> Void

    var body: some View {
        ZStack {
            VStack {
                Text("Events Near You")
                    .font(.largeTitle)
                    .bold()
                    .padding()
                    .multilineTextAlignment(.center)

                if let errorMessage = errorMessage {
                    Text("\(errorMessage)")
                        .foregroundColor(.red)
                        .padding()
                } else {
                    EventListView(events: events)
                }
            }
            .padding(.horizontal)

            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: {
                        isCreatingEvent.toggle()
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .resizable()
                            .frame(width: 40, height: 40)
                            .foregroundColor(.blue)
                            .shadow(radius: 4)
                    }
                    .padding()
                }
            }
        }
        .sheet(isPresented: $isCreatingEvent) {
            CreateEventView(onEventCreated: { _ in
                // Placeholder for event creation
            })
        }
    }
}

// Event List View
struct EventListView: View {
    let events: [Event]

    var body: some View {
        ScrollView {
            VStack(spacing: 15) {
                if events.isEmpty {
                    Text("No upcoming events available.")
                        .foregroundColor(.gray)
                        .italic()
                        .padding()
                } else {
                    ForEach(events) { event in
                        NavigationLink(destination: EventDetailView(event: event)) {
                            EventCardView(event: event)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            .padding()
        }
    }
}

// Event Card View
struct EventCardView: View {
    let event: Event
    
    //maybe by saving eventIDs in an array in the UserDefaults and simply testing if event.id is in that array?
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Only show image if it's available
            if let eventImage = event.eventImage {
                Image(uiImage: eventImage)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 200)
                    .clipped()
            }
            
            VStack(alignment: .leading, spacing: 5) {
                Text(event.title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                if let description = event.description {
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .lineLimit(2)
                }
                
                HStack {
                    Text(event.location)
                        .font(.footnote)
                        .foregroundColor(.blue)
                    
                    Spacer()
                    
                    Text(event.date.formatted(date: .abbreviated, time: .shortened))
                        .font(.footnote)
                        .foregroundColor(.gray)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(10)
            .shadow(radius: 2)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(15)
        .shadow(radius: 3)
    }
}
func isRSVPed(event: Event) -> Bool {
    let arr: [String] = UserDefaults.standard.array(forKey: "rsvpEvents") as? [String] ?? []
        if arr.contains(event.id) {
            return true
        }
        return false
    }

func rsvp(event: Event) {
    let currentUserID = UserDefaults.standard.string(forKey: "userId") ?? "noID"
    guard let url = URL(string: "http://localhost:3000/api/home/rsvp") else {
        print("invalid URL")
        return
    }
    
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    let body: [String: Any] = ["userId": currentUserID, "eventId": event.id]
    do {
        request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
    } catch {
        print("Error serializing JSON: \(error)")
        return
    }
    URLSession.shared.dataTask(with: request) { data, response, error in
        if let error = error {
            print("Error removing friend: \(error.localizedDescription)")
            return
        }
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            print("Unexpected response rsvping: \(response ?? "No response" as Any)")
            return
        }
    }.resume()
    return
}

func unrsvp(event: Event) {
    let currentUserID = UserDefaults.standard.string(forKey: "userId") ?? "noID"
    guard let url = URL(string: "http://localhost:3000/api/home/unrsvp") else {
        print("invalid URL")
        return
    }
    
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    let body: [String: Any] = ["userId": currentUserID, "eventId": event.id]
    do {
        request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
    } catch {
        print("Error serializing JSON: \(error)")
        return
    }
    URLSession.shared.dataTask(with: request) { data, response, error in
        if let error = error {
            print("Error removing friend: \(error.localizedDescription)")
            return
        }
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            print("Unexpected response rsvping: \(response ?? "No response" as Any)")
            return
        }
    }.resume()
    return
}


private func uploadImageToServer(_ image: UIImage) -> String {
    // Simulate image upload - Replace with actual upload logic if needed
    let imageId = UUID().uuidString
    return "https://localhost:3000/uploads/\(imageId).jpg"
}

// Harry's View
struct HarrysView: View {
    @State private var peopleInBar: Int = 0
    @State private var peopleInLine: Int = 0
    @State private var lastUpdated: String = ""
    @State private var errorMessage: String?
    @State private var isRefreshing: Bool = false

    var body: some View {
        VStack(spacing: 20) {
            Text("Harry's Bar Status")
                .font(.largeTitle)
                .bold()
                .padding()

            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
            } else {
                VStack(alignment: .leading, spacing: 15) {
                    HStack {
                        Image(systemName: "person.3")
                        Text("People in Bar:")
                        Spacer()
                        Text("\(peopleInBar)")
                            .fontWeight(.bold)
                    }

                    HStack {
                        Image(systemName: "line.3.horizontal")
                        Text("People in Line:")
                        Spacer()
                        Text("\(peopleInLine)")
                            .fontWeight(.bold)
                    }

                    HStack {
                        Image(systemName: "clock")
                        Text("Last Updated:")
                        Spacer()
                        Text(lastUpdated)
                            .fontWeight(.bold)
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
            }

            Button(action: {
                isRefreshing = true
                fetchHarrysData()
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    isRefreshing = false
                }
            }) {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("Refresh")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(isRefreshing ? Color.gray : Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
                .disabled(isRefreshing)
            }
            .padding()

            Spacer()
        }
        .padding()
        .onAppear {
            fetchHarrysData()
        }
    }
    
    private func fetchHarrysData() {
        guard let url = URL(string: "http://localhost:3000/api/home/harrys/line") else {
            errorMessage = "Invalid API URL"
            return
        }

        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    self.errorMessage = "Error: \(error.localizedDescription)"
                }
                return
            }

            guard let data = data else {
                DispatchQueue.main.async {
                    self.errorMessage = "No data received"
                }
                return
            }

            do {
                            let decoder = JSONDecoder()
                            // Configure date decoding strategy
                            let dateFormatter = DateFormatter()
                            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
                            decoder.dateDecodingStrategy = .formatted(dateFormatter)
                            
                            let apiResponse = try decoder.decode(APIResponse.self, from: data)
                            DispatchQueue.main.async {
                                if let message = apiResponse.message {
                                    self.errorMessage = message  // Handle "No data found" gracefully
                                } else {
                                    self.peopleInBar = apiResponse.peopleInBar ?? 0
                                    self.peopleInLine = apiResponse.peopleInLine ?? 0
                                    // In your data handling code
                                    if let date = apiResponse.lastUpdated {
                                                    // Add 1 hour to the decoded date
                                                    let calendar = Calendar.current
                                                    if let newDate = calendar.date(byAdding: .hour, value: 1, to: date) {
                                                        self.lastUpdated = formatDate(newDate) // Pass the adjusted date to formatDate
                                                    } else {
                                                        self.lastUpdated = "Error adjusting time"
                                                    }
                                                }                                    else {
                                        self.lastUpdated = "Not available"
                                    }                    }
                            }
                        } catch {
                            DispatchQueue.main.async {
                                self.errorMessage = "JSON Decoding Error: \(error.localizedDescription)"
                            }
                            print("Decoding Error: \(error)")
                        }
                    }.resume()
                }
                
                func formatDate(_ date: Date?) -> String {
                    guard let date = date else { return "Unknown" }
                    
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "MMMM d"
                    let monthDay = dateFormatter.string(from: date)
                    
                    // Add the day suffix (th, st, nd, rd)
                    let day = Calendar.current.component(.day, from: date)
                    let daySuffix: String
                    switch day {
                    case 1, 21, 31: daySuffix = "st"
                    case 2, 22: daySuffix = "nd"
                    case 3, 23: daySuffix = "rd"
                    default: daySuffix = "th"
                    }
                    
                    // Time formatting
                    dateFormatter.dateFormat = "h:mm a"
                    let time = dateFormatter.string(from: date).lowercased()
                    
                    return "\(monthDay)\(daySuffix) at \(time)"
                }
            }

struct CreateEventView: View {
    @Environment(\.presentationMode) var presentationMode
    var onEventCreated: (Event) -> Void
    //Done: Add author field to be propogated to database
    @State private var title = ""
    @State private var description = ""
    @State private var author = UserDefaults.standard.string(forKey: "userId") ?? "noID"
    let rsvpCount = 0
    @State private var authorUsername = UserDefaults.standard.string(forKey: "username") ?? "anonymouse"
    @State private var location = ""
    @State private var capacity = ""
    @State private var is21Plus = false
    @State private var promoted = false
    @State private var date = Date()
    @State private var selectedImage: UIImage?
    @State private var showImagePicker = false
    //Done: add state for if event is a promoted event and propogate to database
    @State private var showError = false
    @State private var errorMessage = ""
    private var canPromote : Bool {
        return UserDefaults.standard.bool(forKey: "isAdmin") || UserDefaults.standard.bool(forKey: "isPromoted")
    }
    private let maxDescriptionLength = 200  //  Set max description length
    
    private func checkIfUserIsIdentified(completion: @escaping (Bool) -> Void) {
        guard let userId = UserDefaults.standard.string(forKey: "userId"),
              let url = URL(string: "http://localhost:3000/api/profile/isIdentified/\(userId)") else {
            completion(false)
            return
        }

        URLSession.shared.dataTask(with: url) { data, response, error in
            if let data = data,
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let isIdentified = json["isIdentified"] as? Bool {
                completion(isIdentified)
            } else {
                completion(false)
            }
        }.resume()
    }


    var body: some View {
        NavigationView {
            Form {
                if showError {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .bold()
                        .padding(.bottom, 5)
                }
                
                Section(header: Text("Event Details")) {
                    
                    TextField("Title", text: $title)
                    TextField("Location", text: $location)
                    TextField("Max Capacity", text: $capacity)
                        .keyboardType(.numberPad)
                    Toggle("21+ Event", isOn: $is21Plus)
                    if (canPromote) { //Done: Change "true" to be "if user is admin OR if user is verified"
                        Toggle("Promoted Event", isOn: $promoted)
                    }
                    DatePicker("Date & Time", selection: $date, displayedComponents: [.date, .hourAndMinute])
                    
                    VStack(alignment: .leading) {
                        TextField("Description (Max \(maxDescriptionLength) chars)", text: $description, onEditingChanged: { _ in
                            validateDescription()
                        })
                        .onChange(of: description) { _ in
                            validateDescription()
                        }
                        
                        HStack {
                            Spacer()
                            Text("\(description.count)/\(maxDescriptionLength)")
                                .font(.caption)
                                .foregroundColor(description.count > maxDescriptionLength ? .red : .gray)
                        }
                    }

                    Button("Select Image") {
                        showImagePicker.toggle()
                    }
                    .sheet(isPresented: $showImagePicker) {
                        ImagePicker(image: Binding(
                            get: { selectedImage ?? UIImage() },
                            set: { selectedImage = $0 }
                        ))
                    }

                    if let image = selectedImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 200)
                    }
                }
            }
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Post") {
                    validateAndCreateEvent()
                }
            )
            .navigationTitle("Create Event")
        }
    }
    
    // Validate description length
    private func validateDescription() {
        if description.count > maxDescriptionLength {
            showError = true
            errorMessage = "Description is too long! Maximum \(maxDescriptionLength) characters allowed."
        } else {
            showError = false
            errorMessage = ""
        }
    }
    
    private func validateAndCreateEvent() {
        guard !title.isEmpty, !location.isEmpty, !capacity.isEmpty, let capacityInt = Int(capacity), capacityInt > 0 else {
            showError = true
            errorMessage = "Please fill in all required fields with valid values."
            return
        }

        if description.count > maxDescriptionLength {
            showError = true
            errorMessage = "Description is too long!"
            return
        }

        if date < Date() {
            showError = true
            errorMessage = "Please select a future date."
            return
        }

        // ✅ Check identity before continuing
        checkIfUserIsIdentified { isIdentified in
            if isIdentified {
                validateLocation { isValid in
                    DispatchQueue.main.async {
                        if isValid {
                            createEvent(capacityInt: capacityInt)
                        } else {
                            showError = true
                            errorMessage = "Invalid location. Please enter a valid address."
                        }
                    }
                }
            } else {
                DispatchQueue.main.async {
                    showError = true
                    errorMessage = "You must complete identity verification before posting an event."
                }
            }
        }
    }

    
    private func validateLocation(completion: @escaping (Bool) -> Void) {
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(location) { placemarks, error in
            DispatchQueue.main.async {
                guard let placemark = placemarks?.first else {
                    completion(false)
                    return
                }

                // Require full address details to consider it valid
                if let street = placemark.thoroughfare,
                   let streetNumber = placemark.subThoroughfare,
                   let city = placemark.locality,
                   let state = placemark.administrativeArea,
                   !street.isEmpty, !streetNumber.isEmpty, !city.isEmpty, !state.isEmpty {
                    completion(true)
                } else {
                    completion(false)
                }
            }
        }
    }
    


    private func createEvent(capacityInt: Int) {
        print("🔍 Creating event")

        var encodedImage: String? = nil
        if let selectedImage = selectedImage {
            encodedImage = selectedImage.base64 //  Convert image to Base64
        }

        let newEvent = Event(
            id: UUID().uuidString,
            //Done: include author and promotion status
            author: author,
            rsvpCount: 0,
            title: title,
            description: description,
            location: location,
            capacity: capacityInt,
            is21Plus: is21Plus,
            promoted: promoted,
            date: date,
            imageUrl: encodedImage, // Save Base64 string instead of URL
            authorUsername: authorUsername
        )

        guard let url = URL(string: "http://localhost:3000/api/home/events") else {
            print("Invalid URL")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let token = UserDefaults.standard.string(forKey: "authToken") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .millisecondsSince1970 //  Use milliseconds for date
            let requestData = try encoder.encode(newEvent)
            request.httpBody = requestData
        } catch {
            print(" Error encoding event:", error)
            return
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error posting event:", error)
                return
            }
            
            DispatchQueue.main.async {
                onEventCreated(newEvent)
                presentationMode.wrappedValue.dismiss()
            }
        }.resume()
    }
}
// Event Detail View
struct EventDetailView: View {
    var event: Event
    @State private var rsvpCountDisplay: Int
    @State private var hasRSVPed: Bool
    @State private var showEditSheet = false
    @Environment(\.dismiss) var dismiss
    @State private var showDeleteAlert = false
    @State private var showReportSheet = false
    @State private var isShareSheetPresented = false
    @StateObject private var creatorProfile = ProfileViewModel()
    

    var shareMessage: String {
        let shareURL = URL(string: "boilerbuzz://event?id=\(event.id)")!
        return "Check out this event: \(shareURL.absoluteString)"
    }

    
    init(event: Event) {
        self.event = event
        _rsvpCountDisplay = State(initialValue: event.rsvpCount)
        _hasRSVPed = State(initialValue: isRSVPed(event: event))
    }

    var body: some View {
            VStack(spacing: 20) {
                if let image = event.eventImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 250)
                        .clipped()
                }

                VStack(alignment: .leading, spacing: 10) {
                    // HStack for the title and ProfileNavigation
                    HStack {
                        Text(event.title)
                            .font(.title)
                            .bold()
                        
                        Spacer() // Push the button to the right
                        
                        // TODO still have to fetch user details from event
                        ProfileNavigationButton(
                            userId: event.author, // TODO
                            username: creatorProfile.username, // TODO
                            profilePicture: creatorProfile.profilePicture
                        )
                    }
                    Text(event.description ?? "")
                        .font(.body)

                    HStack {
                        Label(event.location, systemImage: "mappin.and.ellipse")
                        Spacer()
                        Label(event.date.formatted(date: .abbreviated, time: .shortened), systemImage: "calendar")
                    }
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                    HStack {
                        Label("Capacity: \(event.capacity)", systemImage: "person.3")
                        if event.is21Plus {
                            Text("21+")
                                .font(.caption)
                                .padding(5)
                                .background(Color.red.opacity(0.2))
                                .cornerRadius(5)
                        }
                    }

                    Divider()

                    Text("👥 RSVPs: \(rsvpCountDisplay)")
                        .font(.headline)

                    if event.rsvpCount >= event.capacity {
                        Text("Event Full")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.gray)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        
                    } else if event.author == UserDefaults.standard.string(forKey: "userId") {
                        Button("Edit Post") {
                            showEditSheet = true
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .sheet(isPresented: $showEditSheet) {
                            EditEventView(event: event) { updatedEvent in
                                // Handle updated event if needed
                                print("✅ Event updated:", updatedEvent)
                            }
                        }
                        
                    } else {
                        Button(action: {
                            toggleRSVP()
                        }) {
                            Text(hasRSVPed ? "You're Going \u{2705}" : "RSVP")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(hasRSVPed ? Color.green : Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                    }

                    Button(action: {
                        isShareSheetPresented = true
                    }) {
                        Label("Share", systemImage: "square.and.arrow.up")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(10)
                    }
                    .sheet(isPresented: $isShareSheetPresented) {
                        ShareSheet(activityItems: [shareMessage])
                    }
                }
                .padding()
            }
            .onAppear {
                creatorProfile.fetchUserProfile(userId: event.author)
            }
        .navigationTitle("Event Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
                if UserDefaults.standard.bool(forKey: "isAdmin") {
                    ToolbarItemGroup(placement: .navigationBarTrailing) {
                        Button {
                            showReportSheet = true
                        } label: {
                            Image(systemName: "exclamationmark.triangle.fill")
                        }
                        Button {
                            showDeleteAlert = true
                        } label: {
                            Image(systemName: "trash")
                        }
                    }
                }
                else {
                    ToolbarItemGroup(placement: .navigationBarTrailing) {
                        Button {
                            showReportSheet = true
                        } label: {
                            Image(systemName: "exclamationmark.triangle.fill")
                        }
                    }
                }

            }
            .alert("Delete Event", isPresented: $showDeleteAlert) {
                Button("Delete", role: .destructive) {
                    deleteEvent()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Are you sure you want to delete this event?")
            }
            .sheet(isPresented: $showReportSheet) {
                ReportEventView(event: event)
            }
        }

    func deleteEvent() {
        guard let url = URL(string: "http://localhost:3000/api/home/delEvents/\(event.id)") else {
            print("Invalid URL for event deletion")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error deleting event: \(error.localizedDescription)")
                return
            }
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                print("Unexpected response deleting event: \(response ?? "No response" as Any)")
                return
            }
            DispatchQueue.main.async {
                print("Event deleted successfully!")
                dismiss()
            }
        }.resume()
    }
    private func toggleRSVP() {
        hasRSVPed.toggle()
        rsvpCountDisplay += hasRSVPed ? 1 : -1
        var tempArr: [String] = UserDefaults.standard.stringArray(forKey: "rsvpEvents") ?? []
        
        if hasRSVPed {
            if !tempArr.contains(event.id) {
                tempArr.append(event.id)
                UserDefaults.standard.set(tempArr, forKey: "rsvpEvents")
            }
            rsvp(event: event)
        } else {
            tempArr.removeAll { $0 == event.id }
            UserDefaults.standard.set(tempArr, forKey: "rsvpEvents")
            unrsvp(event: event)
        }
    }
}

struct EditEventView: View {
    @Environment(\.presentationMode) var presentationMode
    var event: Event
    var onEventUpdated: (Event) -> Void

    @State private var title: String
    @State private var description: String
    @State private var location: String
    @State private var capacity: String
    @State private var is21Plus: Bool
    @State private var promoted: Bool
    @State private var date: Date
    @State private var selectedImage: UIImage?
    @State private var errorMessage: String?
    @State private var showImagePicker = false

    init(event: Event, onEventUpdated: @escaping (Event) -> Void) {
        self.event = event
        self.onEventUpdated = onEventUpdated
        _title = State(initialValue: event.title)
        _description = State(initialValue: event.description ?? "")
        _location = State(initialValue: event.location)
        _capacity = State(initialValue: "\(event.capacity)")
        _is21Plus = State(initialValue: event.is21Plus)
        _promoted = State(initialValue: event.promoted)
        _date = State(initialValue: event.date)
    }

    var body: some View {
        NavigationView {
            Form {
                if let error = errorMessage {
                    Text(error).foregroundColor(.red)
                }

                Section(header: Text("Edit Event")) {
                    TextField("Title", text: $title)
                    TextField("Location", text: $location)
                    TextField("Capacity", text: $capacity)
                        .keyboardType(.numberPad)
                    Toggle("21+ Event", isOn: $is21Plus)
                    Toggle("Promoted", isOn: $promoted)
                    DatePicker("Date", selection: $date)

                    TextField("Description", text: $description)

                    Button("Select New Image") {
                        showImagePicker = true
                    }
                    .sheet(isPresented: $showImagePicker) {
                        ImagePicker(image: Binding(
                            get: { selectedImage ?? UIImage() },
                            set: { selectedImage = $0 }
                        ))
                    }

                    if let selectedImage = selectedImage {
                        Image(uiImage: selectedImage)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 200)
                    }
                }
            }
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Update") {
                    updateEvent()
                }
            )
            .navigationTitle("Edit Event")
        }
    }

    func updateEvent() {
        guard let capacityInt = Int(capacity) else {
            errorMessage = "Invalid capacity"
            return
        }

        let encodedImage = selectedImage?.base64

        let updatedData: [String: Any] = [
            "title": title,
            "description": description,
            "location": location,
            "capacity": capacityInt,
            "is21Plus": is21Plus,
            "promoted": promoted,
            "date": Int(date.timeIntervalSince1970 * 1000),
            "imageUrl": encodedImage ?? event.imageUrl ?? ""
        ]

        guard let url = URL(string: "http://localhost:3000/api/home/events/\(event.id)") else {
            errorMessage = "Invalid URL"
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = UserDefaults.standard.string(forKey: "authToken") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: updatedData)
        } catch {
            errorMessage = "Failed to encode update"
            return
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                errorMessage = "Error: \(error.localizedDescription)"
                return
            }

            DispatchQueue.main.async {
                let updatedEvent = Event(
                    id: event.id,
                    author: event.author,
                    rsvpCount: event.rsvpCount,
                    title: title,
                    description: description,
                    location: location,
                    capacity: capacityInt,
                    is21Plus: is21Plus,
                    promoted: promoted,
                    date: date,
                    imageUrl: encodedImage ?? event.imageUrl,
                    authorUsername: event.authorUsername
                )
                onEventUpdated(updatedEvent)
                presentationMode.wrappedValue.dismiss()
            }
        }.resume()
    }
}

struct ProfileNavigationButton: View {
    let userId: String
    let username: String
    let profilePicture: UIImage?

    var body: some View {
        NavigationLink(destination: AccountView(viewedUserId: userId, adminStatus: nil)) {
            VStack(spacing: 4) {
                // If a URL is available, load the image; otherwise, show a default icon.
                if let image = profilePicture {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 50, height: 50)
                        .clipShape(Circle())
                } else {
                    Image(systemName: "person.crop.circle.fill")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 50, height: 50)
                        .clipShape(Circle())
                }
                Text(username)
                    .font(.caption)
                    .foregroundColor(.primary)
            }
            .padding(4)
        }
    }
}

struct ReportEventView: View {
    let event: Event
    @Environment(\.dismiss) var dismiss
    @State private var selectedReason: String = "False Information"
    @State private var customReason: String = ""
    @State private var additionalInfo: String = ""
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var showConfirmation = false

    let reasons = ["False Information", "Unsafe Content", "Spam", "Other"]

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 20) {

                Text("Select a reason for reporting this event:")
                    .font(.subheadline)
                
                // Picker for selecting a reason.
                Picker("Reason", selection: $selectedReason) {
                    ForEach(reasons, id: \.self) { reason in
                        Text(reason).tag(reason)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .padding(10)
                .background(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.5), lineWidth: 1))
                
                // If "Other" is selected, let the user enter a custom reason.
                if selectedReason == "Other" {
                    TextField("Enter your reason", text: $customReason)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                Text("Additional Information (Optional):")
                    .font(.subheadline)
                TextEditor(text: $additionalInfo)
                    .frame(height: 100)
                    .overlay(RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.5), lineWidth: 1))
                
                Text("Your Details")
                    .font(.subheadline)
                    .padding(.top)
                
                TextField("First Name", text: $firstName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                TextField("Last Name", text: $lastName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Spacer()
                
                Button(action: {
                    submitReport()
                }) {
                    Text("Submit Report")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(buttonBackgroundColor)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .disabled(isSubmitDisabled)
            }
            .padding()
            .navigationTitle("Report Event")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Report Submitted", isPresented: $showConfirmation) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Thank you for reporting this event. Our team will review it shortly.")
            }
        }
    }
    
    // Disable the submit button if any required field is empty.
    var isSubmitDisabled: Bool {
        selectedReason.isEmpty ||
        (selectedReason == "Other" && customReason.isEmpty) ||
        firstName.isEmpty ||
        lastName.isEmpty
    }
    
    // Change the button color based on whether the form is complete.
    var buttonBackgroundColor: Color {
        isSubmitDisabled ? Color.gray : Color.red
    }
    
    func submitReport() {
        // Choose the final reason based on the selection.
        let finalReason = selectedReason == "Other" ? customReason : selectedReason
        guard let reporterId = UserDefaults.standard.string(forKey: "userId") else {
            print("Reporter user ID not found")
            return
        }
        
        let reportData: [String: Any] = [
            "eventId": event.id,
            "reporterId": reporterId,
            "reporterFirstName": firstName,
            "reporterLastName": lastName,
            "reason": finalReason,
            "additionalInfo": additionalInfo
        ]
        
        guard let url = URL(string: "http://localhost:3000/api/report/submit") else {
            print("Invalid URL for submitting report")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: reportData, options: [])
        } catch {
            print("Error serializing report data: \(error)")
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error submitting report: \(error.localizedDescription)")
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("No valid response received")
                return
            }
            
            if httpResponse.statusCode == 201 {
                // Report successfully created
                DispatchQueue.main.async {
                    showConfirmation = true
                }
            } else {
                print("Unexpected response code: \(httpResponse.statusCode)")
                if let data = data,
                let responseString = String(data: data, encoding: .utf8) {
                    print("Response data: \(responseString)")
                }
            }
        }.resume()
    }
}
