import SwiftUI
import PhotosUI
import MapKit
import UIKit

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


struct HomeView: View {
    @State private var isCreatingEvent = false
    @State private var events: [Event] = []
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            bgColor.ignoresSafeArea(edges: .all)
            
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
        .onAppear {
            fetchEvents()
        }
        .sheet(isPresented: $isCreatingEvent) {
            CreateEventView(onEventCreated: { newEvent in
                events.append(newEvent)
            })
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

            // Debug raw JSON response
            if let jsonString = String(data: data, encoding: .utf8) {
                print("🚀 API Response:\n\(jsonString)")
            }

            do {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .millisecondsSince1970 //  Decode timestamps correctly
                
                let fetchedEvents = try decoder.decode([Event].self, from: data)
                DispatchQueue.main.async {
                    self.events = fetchedEvents.filter { $0.date >= Date() }
                    self.errorMessage = nil
                }
                print("Successfully fetched events")
            } catch {
                print(" JSON Decoding Error: \(error)")
                DispatchQueue.main.async {
                    self.errorMessage = "JSON Decoding Error: \(error.localizedDescription)"
                }
            }
        }.resume()
    }
}

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
                        EventCardView(event: event)
                    }
                }
            }
            .padding()
        }
    }
}

struct EventCardView: View {
    let event: Event

    //TODO: add a boolean field to indicate if the current user is rsvpd or not
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
                        .lineLimit(nil) //  Allow dynamic height
                        .fixedSize(horizontal: false, vertical: true) //  Expand dynamically
                }

                HStack {
                    Text(event.location)
                        .font(.footnote)
                        .foregroundColor(.blue)
                    Spacer()
                    Text(event.date, style: .date)
                        .font(.footnote)
                        .foregroundColor(.gray)
                }
                //TODO: Add current and max capacity here
                //TODO: Add RSVP Button here, which calls RSVP function
                //TODO: Add an bit that gives the authorUsername field
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
    
    private func isRSVPed() -> Bool {
        let arr: [String] = UserDefaults.standard.array(forKey: "rsvpEvents") as? [String] ?? []
        if arr.contains(event.id) {
            return true
        }
        return false
    }
    
    private func rsvp() {
        let currentUserID = UserDefaults.standard.string(forKey: "userId") ?? "noID"
        //TODO: Construct a url POST request to the rsvp url with 2 fields: currentUserID and eventID,
        //where eventID can be found in the Event field of the EventCardView struct
        return
    }
    
    private func unrsvp() {
        let currentUserID = UserDefaults.standard.string(forKey: "userId") ?? "noID"
        //TODO: Construct a url POST request to the rsvp url with 2 fields: currentUserID and eventID,
        //where eventID can be found in the Event field of the EventCardView struct
        return
    }
}


private func uploadImageToServer(_ image: UIImage) -> String {
    // Simulate image upload - Replace with actual upload logic if needed
    let imageId = UUID().uuidString
    return "https://localhost:3000/uploads/\(imageId).jpg"
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
                    if (canPromote) { //TODO: Change "true" to be "if user is admin OR if user is verified"
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
                if let placemark = placemarks?.first, placemark.location != nil, let _ = placemark.locality {
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
