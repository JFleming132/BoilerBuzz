import Foundation
import CoreLocation

class LocationManager: NSObject, CLLocationManagerDelegate, ObservableObject {
    
    private var locationManager = CLLocationManager()
    
    @Published var userLocation: CLLocation? // Stores the user's current location
    @Published var locationStatus: CLAuthorizationStatus? // Stores authorization status
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = kCLDistanceFilterNone
        checkLocationAuthorization() // Ensure proper permission handling
    }
    
    /// Checks and requests location authorization
    private func checkLocationAuthorization() {
        switch locationManager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            print("✅ Location access granted, starting updates")
            locationManager.startUpdatingLocation()
        case .denied:
            print("❌ Location access denied. Please enable it in Settings.")
        case .restricted:
            print("❌ Location access is restricted.")
        case .notDetermined:
            print("🔄 Requesting location authorization...")
            locationManager.requestWhenInUseAuthorization()
        @unknown default:
            print("❓ Unknown authorization status.")
        }
    }
    
    /// Called when authorization status changes
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        locationStatus = status
        print("📍 Authorization status changed: \(status.rawValue)")
        
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            locationManager.startUpdatingLocation()
        } else {
            print("🚫 Location services are not enabled")
        }
    }
    
    /// Called when location updates are received
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let latestLocation = locations.last else { return }
        userLocation = latestLocation
        print("📍 New location: \(latestLocation.coordinate.latitude), \(latestLocation.coordinate.longitude)")
    }
    
    /// Called when there's an error updating location
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("⚠️ Location manager failed with error: \(error.localizedDescription)")
    }
    
    /// Manually request authorization (if needed)
    func requestLocationPermission() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    /// Manually start location updates
    func startUpdatingLocation() {
        locationManager.startUpdatingLocation()
    }
    
    /// Manually stop location updates
    func stopUpdatingLocation() {
        locationManager.stopUpdatingLocation()
    }
}
