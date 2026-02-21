import Foundation
import CoreLocation
import Combine


class QiblaManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    
    @Published var heading: Double = 0.0
    @Published var qiblaDirection: Double = 0.0
    @Published var angleToQibla: Double = 0.0
    
    // Makkah Coordinates
    private let makkahCoordinate = CLLocationCoordinate2D(latitude: 21.4225, longitude: 39.8262)
    private var currentLocation: CLLocationCoordinate2D?
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.headingFilter = 1 // Update every 1 degree
        startUpdatingHeading()
    }
    
    func startUpdatingHeading() {
        if CLLocationManager.headingAvailable() {
            locationManager.startUpdatingHeading()
        }
    }
    
    func stopUpdatingHeading() {
        locationManager.stopUpdatingHeading()
    }
    
    func updateLocation(coordinate: CLLocationCoordinate2D) {
        self.currentLocation = coordinate
        calculateQiblaDirection()
    }
    
    private func calculateQiblaDirection() {
        guard let loc = currentLocation else { return }
        
        // Qibla calculation using Adhan library (handles complex great-circle)
        let coords = Coordinates(latitude: loc.latitude, longitude: loc.longitude)
        self.qiblaDirection = Qibla(coordinates: coords).direction
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        // Use true heading if available, else magnetic
        let currentHeading = newHeading.trueHeading > 0 ? newHeading.trueHeading : newHeading.magneticHeading
        
        DispatchQueue.main.async {
            self.heading = currentHeading
            
            // Difference between where the phone is pointing and the Qibla
            var angle = self.qiblaDirection - currentHeading
            if angle < 0 {
                angle += 360
            }
            self.angleToQibla = angle
        }
    }
}
