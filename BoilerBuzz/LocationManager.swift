import CoreLocation

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    @Published var location: CLLocation?

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = kCLDistanceFilterNone
        locationManager.startUpdatingLocation()
    }

    func requestWhenInUseAuthorization() {
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }

    func startUpdatingLocation() {
        locationManager.startUpdatingLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let newLocation = locations.last else { return }
        self.location = newLocation
        
        print("📍 New location: \(newLocation.coordinate.latitude), \(newLocation.coordinate.longitude)")
        // Call API to update user location
        updateUserLocationInDatabase(newLocation)
    }

    private func updateUserLocationInDatabase(_ location: CLLocation) {
        guard let userId = UserDefaults.standard.string(forKey: "userId") else {
            print("User ID not found. Please log in again.")
            return
        }

        let latitude = location.coordinate.latitude
        let longitude = location.coordinate.longitude

        let url = URL(string: "http://localhost:3000/api/location/updateLocation")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "userId": userId,
            "latitude": latitude,
            "longitude": longitude
        ]

        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Error updating location: \(error.localizedDescription)")
                    return
                }

                guard let data = data else {
                    print("No data received from the server.")
                    return
                }

                do {
                    if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                        if let message = json["message"] as? String {
                            print(message)
                            if message == "Location updated successfully!" {
                                // Optionally handle success (e.g., notify user or update UI)
                            }
                        }
                    }
                } catch {
                    print("Error decoding response: \(error.localizedDescription)")
                }
            }
        }.resume()
    }
}

