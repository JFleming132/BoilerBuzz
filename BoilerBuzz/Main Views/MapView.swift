import SwiftUI
import GoogleMaps
import GooglePlaces

struct MapView: View {
    @StateObject private var locationManager = LocationManager()
    @StateObject private var eventManager = EventManager() // Create EventManager instance

    var body: some View {
        GoogleMapViewRepresentable(location: locationManager.location?.coordinate, eventManager: eventManager) // Pass CLLocationCoordinate2D?
            .ignoresSafeArea()
            .onAppear {
                locationManager.requestWhenInUseAuthorization()
                eventManager.fetchUserEvents {} // Fetch events when the view appears
            }
    }
}
