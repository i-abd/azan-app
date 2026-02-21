import SwiftUI

struct QiblaView: View {
    @StateObject private var qiblaManager = QiblaManager()
    @EnvironmentObject var locationManager: LocationManager
    @State private var wasOnTarget = false  // Tracks previous state to avoid repeating haptics
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Point your phone towards the Kaaba")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.top)

                Spacer()
                
                ZStack {
                    // Compass Background Ring
                    Circle()
                        .stroke(lineWidth: 10)
                        .foregroundColor(Color.gray.opacity(0.2))
                        .frame(width: 300, height: 300)
                    
                    // North Indicator (N)
                    Text("N")
                        .font(.title2)
                        .fontWeight(.bold)
                        .offset(y: -130)
                        .rotationEffect(.degrees(-qiblaManager.heading)) // North spins opposite to heading
                    
                    // Kaaba Direction Arrow
                    Image(systemName: "arrow.up")
                        .resizable()
                        .frame(width: 40, height: 100)
                        .foregroundColor(.green)
                        // Arrow rotates to point to Qibla relative to the phone's current heading
                        .rotationEffect(.degrees(qiblaManager.angleToQibla))
                        // Add a pulse effect if we are pointing correctly
                        .shadow(color: isCorrectDirection() ? .green : .clear, radius: 10, x: 0, y: 0)
                }
                
                Spacer()
                
                if let loc = locationManager.location {
                    Text("Qibla Direction: \(String(format: "%.1f", qiblaManager.qiblaDirection))°")
                        .font(.headline)
                        .padding()
                } else {
                    Text("Waiting for location...")
                        .font(.headline)
                        .padding()
                }
                
                if isCorrectDirection() {
                    Text("You are facing the Qibla")
                        .foregroundColor(.green)
                        .fontWeight(.bold)
                        .padding(.bottom)
                } else {
                    Text("Rotate your phone")
                        .foregroundColor(.secondary)
                        .padding(.bottom)
                }
            }
            .navigationTitle("Qibla Compass")
            .onAppear {
                qiblaManager.startUpdatingHeading()
                if let loc = locationManager.location {
                    qiblaManager.updateLocation(coordinate: loc)
                }
            }
            .onDisappear {
                qiblaManager.stopUpdatingHeading()
            }
            .onChange(of: locationManager.locationString) { _ in
                if let loc = locationManager.location {
                    qiblaManager.updateLocation(coordinate: loc)
                }
            }
            .onChange(of: qiblaManager.angleToQibla) { angle in
                let onTarget = angle < 5 || angle > 355
                if onTarget && !wasOnTarget {
                    // Fired once when entering the Qibla zone
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.success)
                }
                wasOnTarget = onTarget
            }
        }
    }
    
    // Check if the user is facing within +/- 5 degrees of the Qibla
    private func isCorrectDirection() -> Bool {
        let angle = qiblaManager.angleToQibla
        return angle < 5 || angle > 355
    }
}

struct QiblaView_Previews: PreviewProvider {
    static var previews: some View {
        QiblaView()
    }
}
