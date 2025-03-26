import CoreLocation
import UIKit

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    @Published var location: CLLocation?
    private var lastUpdateTime: Date?
    private var updateTimer: Timer?
    private var backgroundTask: UIBackgroundTaskIdentifier = .invalid

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = kCLDistanceFilterNone
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false
        locationManager.startUpdatingLocation()
        locationManager.startMonitoringSignificantLocationChanges() // ✅ Keeps tracking in background

        startTimer() // ✅ Ensures updates every 5 minutes
    }

    func requestWhenInUseAuthorization() {
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }

    func startUpdatingLocation() {
        locationManager.startUpdatingLocation()
    }

    // 🔴 Live location updates for the map
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let newLocation = locations.last else { return }
        self.location = newLocation
        print("📍 Live location updated: \(newLocation.coordinate.latitude), \(newLocation.coordinate.longitude)")
    }

    // 🕒 Timer to send location updates to the database every 5 minutes
    private func startTimer() {
        updateTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.sendLocationUpdate()
        }
    }

    private func sendLocationUpdate() {
        guard let location = location else {
            print("⚠️ No location available to send to the database.")
            return
        }

        let now = Date()
        if let lastUpdate = lastUpdateTime, now.timeIntervalSince(lastUpdate) < 60 {
            print("⏳ Skipping database update. Last update was less than 5 minutes ago.")
            return
        }

        lastUpdateTime = now
        beginBackgroundTask() // ✅ Ensures background execution
        updateUserLocationInDatabase(location)
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

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.endBackgroundTask() // ✅ Ends background task after update
                
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
                            print("📡 Database update: \(message)")
                        }
                    }
                } catch {
                    print("Error decoding response: \(error.localizedDescription)")
                }
            }
        }.resume()
    }

    // 🚀 Keeps location updates working in background mode
    private func beginBackgroundTask() {
        backgroundTask = UIApplication.shared.beginBackgroundTask {
            self.endBackgroundTask()
        }
    }

    private func endBackgroundTask() {
        if backgroundTask != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTask)
            backgroundTask = .invalid
        }
    }
}
