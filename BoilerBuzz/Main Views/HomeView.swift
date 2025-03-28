import SwiftUI
import PhotosUI
import MapKit
import UIKit

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


struct HomeView: View {
    @State private var isCreatingEvent = false
    @State private var events: [Event] = []
    @State private var errorMessage: String?

    var body: some View {
        NavigationView { // ✅ Add this
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
                        EventListView(events: events) // ✅ This will now allow navigation
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
                        NavigationLink(destination: EventDetailView(event: event)) {
                            EventCardView(event: event)
                        }
                        .buttonStyle(PlainButtonStyle()) // ✅ Removes default blue highlight
                    }
                }
            }
            .padding()
        }
    }
}


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
                        .lineLimit(nil) //  Allow dynamic height
                        .fixedSize(horizontal: false, vertical: true) //  Expand dynamically
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


private func uploadImageToServer(_ image: UIImage) -> String {
    // Simulate image upload - Replace with actual upload logic if needed
    let imageId = UUID().uuidString
    return "https://localhost:3000/uploads/\(imageId).jpg"
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

struct EventDetailView: View {
    let event: Event
    @State private var rsvpCount: Int = Int.random(in: 5...50)
    @State private var hasRSVPed = false
    @Environment(\.dismiss) var dismiss

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
                    Text(event.title)
                        .font(.title)
                        .bold()

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
    }
}
