import SwiftUI
import GoogleMaps
import GooglePlaces

struct MapView: View {
    @StateObject private var locationManager = LocationManager()
    
    var body: some View {
        VStack {
            if let coordinate = locationManager.userLocation?.coordinate { // ✅ Extracts coordinate safely
                GoogleMapViewRepresentable(location: coordinate)
            } else {
                Text("Loading location...")
            }
        }
        .ignoresSafeArea()
        .onAppear {
            locationManager.requestLocationPermission()
        }
    }
}
