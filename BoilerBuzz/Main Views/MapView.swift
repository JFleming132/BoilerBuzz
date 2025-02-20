//  MapView.swift
//  BoilerBuzz
//
//  Created by user269394 on 2/7/25.
//

import SwiftUI
import GoogleMaps
import GooglePlaces

struct MapView: View {
    @StateObject private var locationManager = LocationManager()

    var body: some View {
        GeometryReader { geometry in
            GoogleMapViewRepresentable(location: locationManager.location)
                .frame(width: geometry.size.width, height: geometry.size.height)
                .edgesIgnoringSafeArea(.all)
        }
        .ignoresSafeArea()
        .onAppear {
            locationManager.requestWhenInUseAuthorization()
        }
    }
}
