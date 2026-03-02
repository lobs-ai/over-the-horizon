//
//  POILocation.swift
//  OverTheHorizon
//
//  Created by Programmer Agent
//

import Foundation
import CoreLocation
import MapKit

/// Represents a single point of interest with location, category, and bearing information.
struct POILocation: Identifiable, Equatable {
    /// Unique identifier for the POI.
    let id = UUID()
    
    /// Name of the point of interest.
    let name: String
    
    /// Geographic coordinate of the POI.
    let coordinate: CLLocationCoordinate2D
    
    /// Category of the POI.
    let category: LocationCategory
    
    /// Distance from user to this POI, in meters.
    let distance: CLLocationDistance
    
    /// Bearing from user to this POI, in degrees (0-360).
    /// 0° is North, 90° is East, 180° is South, 270° is West.
    let bearing: Double
    
    /// Prominence or importance rating for this POI.
    /// Range: 0.0 to 1.0, where 1.0 is most prominent.
    let prominence: Double
    
    /// Creates a new POI location.
    /// - Parameters:
    ///   - name: The name of the POI.
    ///   - coordinate: The geographic coordinate.
    ///   - category: The category of the POI.
    ///   - distance: Distance from user in meters.
    ///   - bearing: Bearing from user in degrees (0-360).
    ///   - prominence: Prominence rating (0.0-1.0).
    init(
        name: String,
        coordinate: CLLocationCoordinate2D,
        category: LocationCategory,
        distance: CLLocationDistance,
        bearing: Double,
        prominence: Double = 0.5
    ) {
        self.name = name
        self.coordinate = coordinate
        self.category = category
        self.distance = distance
        self.bearing = bearing
        self.prominence = max(0.0, min(1.0, prominence)) // Clamp to 0.0-1.0
    }
    
    /// Calculates the bearing from a user location to this POI's coordinate.
    /// - Parameter from: The user's current location.
    /// - Returns: The bearing in degrees (0-360), where 0° is North.
    static func calculateBearing(from userLocation: CLLocationCoordinate2D, to poiCoordinate: CLLocationCoordinate2D) -> Double {
        let lat1 = userLocation.latitude * Double.pi / 180.0
        let lat2 = poiCoordinate.latitude * Double.pi / 180.0
        let dLon = (poiCoordinate.longitude - userLocation.longitude) * Double.pi / 180.0
        
        let y = sin(dLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)
        let bearing = atan2(y, x) * 180.0 / Double.pi
        
        return (bearing + 360.0).truncatingRemainder(dividingBy: 360.0)
    }
    
    /// Calculates the distance from a user location to this POI's coordinate.
    /// - Parameter from: The user's current location.
    /// - Returns: The distance in meters.
    static func calculateDistance(from userLocation: CLLocationCoordinate2D, to poiCoordinate: CLLocationCoordinate2D) -> CLLocationDistance {
        let userCLLocation = CLLocation(latitude: userLocation.latitude, longitude: userLocation.longitude)
        let poiCLLocation = CLLocation(latitude: poiCoordinate.latitude, longitude: poiCoordinate.longitude)
        return userCLLocation.distance(from: poiCLLocation)
    }
    
    // Equatable conformance
    static func == (lhs: POILocation, rhs: POILocation) -> Bool {
        lhs.id == rhs.id
    }
}
