import SwiftUI
import GoogleMaps
import GooglePlaces

struct MapView: View {
    @StateObject private var locationManager = LocationManager()

    var body: some View {
        GoogleMapViewRepresentable(location: locationManager.location)
            .ignoresSafeArea()
            .onAppear {
                locationManager.requestWhenInUseAuthorization()
            }
    }
}
//test
//test
