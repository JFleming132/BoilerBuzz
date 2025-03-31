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
    let id: String
    let title: String
    let description: String?
    let location: String
    let capacity: Int
    let is21Plus: Bool
    let date: Date
    let imageUrl: String?

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case title, description, location, capacity, is21Plus, date, imageUrl
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

    var body: some View {
        NavigationView {
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
                .background(
                    Color(uiColor: UIColor.systemBackground) // Adaptive to light/dark mode
                )
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
                .background(Color(uiColor: UIColor.systemBackground)) // Ensure background adapts
            }
            .onAppear {
                fetchEvents()
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
    
    @State private var title = ""
    @State private var description = ""
    @State private var location = ""
    @State private var capacity = ""
    @State private var is21Plus = false
    @State private var date = Date()
    @State private var selectedImage: UIImage?
    @State private var showImagePicker = false
    
    @State private var showError = false
    @State private var errorMessage = ""
    
    private let maxDescriptionLength = 200  //  Set max description length

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
            title: title,
            description: description,
            location: location,
            capacity: capacityInt,
            is21Plus: is21Plus,
            date: date,
            imageUrl: encodedImage // Save Base64 string instead of URL
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
    let event: Event
    @State private var rsvpCount: Int = Int.random(in: 5...50)
    @State private var hasRSVPed = false
    @Environment(\.dismiss) var dismiss
    @State private var showDeleteAlert = false
    @State private var showReportSheet = false
    

    var body: some View {
        ScrollView {
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
                            userId: "67c208c071b197bb4b40fd84", // TODO
                            username: "NOT DONE", // TODO
                            profilePictureURL: nil
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

                    Text("👥 RSVPs: \(rsvpCount)")
                        .font(.headline)

                    Button(action: {
                        hasRSVPed.toggle()
                        rsvpCount += hasRSVPed ? 1 : -1
                    }) {
                        Text(hasRSVPed ? "You're Going ✅" : "RSVP")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(hasRSVPed ? Color.green : Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }

                    Button(action: {
                        let activityVC = UIActivityViewController(
                            activityItems: ["Check out this event: \(event.title) at \(event.location)"],
                            applicationActivities: nil
                        )
                        UIApplication.shared.windows.first?.rootViewController?.present(activityVC, animated: true)
                    }) {
                        Label("Share", systemImage: "square.and.arrow.up")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(10)
                    }
                }
                .padding()
            }
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
}

struct ProfileNavigationButton: View {
    let userId: String
    let username: String
    let profilePictureURL: String? // optional URL string for the user's profile picture idk yet

    var body: some View {
        NavigationLink(destination: AccountView(viewedUserId: userId, adminStatus: nil)) {
            VStack(spacing: 4) {
                // If a URL is available, load the image; otherwise, show a default icon.
                if let urlString = profilePictureURL, let url = URL(string: urlString) {
                    AsyncImage(url: url) { phase in
                        if let image = phase.image {
                            image
                                .resizable()
                                .scaledToFill()
                        } else if phase.error != nil {
                            Image(systemName: "person.crop.circle.fill")
                                .resizable()
                                .scaledToFill()
                        } else {
                            Image(systemName: "person.crop.circle.fill")
                                .resizable()
                                .scaledToFill()
                        }
                    }
                    .frame(width: 50, height: 50)
                    .clipShape(Circle())
                } else {
                    Image(systemName: "person.crop.circle.fill")
                        .resizable()
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