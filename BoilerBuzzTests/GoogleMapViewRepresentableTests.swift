import XCTest
import GoogleMaps
import CoreLocation
@testable import BoilerBuzz

class GoogleMapViewRepresentableTests: XCTestCase {
    
    var mapView: GMSMapView!
    
    override func setUp() {
        super.setUp()
        let options = GMSMapViewOptions()
        options.camera = GMSCameraPosition.camera(withLatitude: 37.7, longitude: -122.4, zoom: 10)
        mapView = GMSMapView(options: options)
        mapView.isMyLocationEnabled = true
        mapView.settings.myLocationButton = true
    }
    
    override func tearDown() {
        mapView = nil
        super.tearDown()
    }
    
    func testMapViewInitialization() {
        XCTAssertNotNil(mapView, "MapView should be initialized")
        XCTAssertEqual(mapView.camera.zoom, 10, "Zoom level should be 5")
    }
    
    func testAddingMarker() {
        let marker = GMSMarker()
        marker.position = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
        marker.map = mapView

        XCTAssertNotNil(marker.map, "Marker should be added to the map")
        XCTAssertEqual(marker.position.latitude, 37.7749, "Latitude should match")
        XCTAssertEqual(marker.position.longitude, -122.4194, "Longitude should match")
    }
    
    func testMockLocationManager() {
        let mockLocationManager = MockLocationManager()
        let location = mockLocationManager.location

        XCTAssertNotNil(location, "Mock location should not be nil")
        XCTAssertEqual(location?.coordinate.latitude, 37.7749, "Latitude should be correct")
        XCTAssertEqual(location?.coordinate.longitude, -122.4194, "Longitude should be correct")
    }
}

class MockLocationManager: CLLocationManager {
    override var location: CLLocation? {
        return CLLocation(latitude: 37.7749, longitude: -122.4194)
    }
}
