import Foundation
import CoreLocation
import Combine

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    
    @Published var location: CLLocationCoordinate2D?
    @Published var locationString: String = ""  // Used for onChange observation
    @Published var authorizationStatus: CLAuthorizationStatus?
    @Published var countryCode: String?
    @Published var error: String?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyKilometer // Saves battery, accurate enough for prayer times
        authorizationStatus = manager.authorizationStatus
    }

    func requestLocation() {
        manager.requestWhenInUseAuthorization()
        manager.requestLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last else { return }
        DispatchQueue.main.async {
            self.location = loc.coordinate
            self.locationString = "\(loc.coordinate.latitude),\(loc.coordinate.longitude)"
            self.reverseGeocode(location: loc)
        }
    }

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        DispatchQueue.main.async {
            self.authorizationStatus = status
            if status == .authorizedWhenInUse || status == .authorizedAlways {
                self.manager.requestLocation()
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        let clError = error as? CLError
        // CLError.locationUnknown (code 1) is temporary — the manager is still searching.
        // Don't show it as a red error; just retry silently.
        if clError?.code == .locationUnknown {
            print("Location still searching, retrying...")
            manager.requestLocation()
            return
        }
        // For real errors (e.g. denied), surface the message
        DispatchQueue.main.async {
            self.error = error.localizedDescription
            print("Location Manager Failed: \(error.localizedDescription)")
        }
    }

    private func reverseGeocode(location: CLLocation) {
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            if let error = error {
                print("Reverse geocoding error: \(error.localizedDescription)")
                return
            }
            if let placemark = placemarks?.first {
                DispatchQueue.main.async {
                    self?.countryCode = placemark.isoCountryCode
                }
            }
        }
    }
}
