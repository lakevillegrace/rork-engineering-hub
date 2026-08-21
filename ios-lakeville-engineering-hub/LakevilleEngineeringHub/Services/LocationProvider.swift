import CoreLocation
import Foundation
import Observation

/// Supplies the crew's current position so field staff can see where they are
/// relative to a closure. Location is used only while the app is in use and is
/// never stored or transmitted.
@Observable
final class LocationProvider: NSObject {
    enum Access: Equatable {
        case notDetermined
        case authorized
        case denied
        case restricted

        var isAuthorized: Bool { self == .authorized }
    }

    private let manager = CLLocationManager()

    private(set) var access: Access = .notDetermined
    private(set) var currentPoint: GeoPoint?
    private(set) var headingDegrees: Double?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        manager.distanceFilter = 25
        access = LocationProvider.access(for: manager.authorizationStatus)
    }

    /// Asks for permission the first time, then begins updates when allowed.
    func start() {
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            manager.startUpdatingLocation()
        default:
            break
        }
    }

    func stop() {
        manager.stopUpdatingLocation()
    }

    private static func access(for status: CLAuthorizationStatus) -> Access {
        switch status {
        case .notDetermined: .notDetermined
        case .authorizedAlways, .authorizedWhenInUse: .authorized
        case .restricted: .restricted
        default: .denied
        }
    }
}

extension LocationProvider: CLLocationManagerDelegate {
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor in
            self.access = LocationProvider.access(for: status)
            if self.access.isAuthorized {
                manager.startUpdatingLocation()
            } else {
                self.currentPoint = nil
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let last = locations.last else { return }
        let point = GeoPoint(latitude: last.coordinate.latitude, longitude: last.coordinate.longitude)
        Task { @MainActor in
            self.currentPoint = point
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        guard (error as? CLError)?.code != .locationUnknown else { return }
        Task { @MainActor in
            self.currentPoint = nil
        }
    }
}
