//
//  ARLabelPositioner.swift
//  OverTheHorizon
//
//  Created by Programmer Agent
//

import Foundation
import CoreGraphics
import SwiftUI
import CoreLocation

/// Calculates label positioning and scaling for AR overlay display.
struct ARLabelPositioner {
    // MARK: - Constants
    
    /// Horizontal field of view in degrees
    static let horizontalFOV: Double = 45.0
    
    /// Distance range for display (in meters)
    let minDistance: CLLocationDistance = 100.0
    let maxDistance: CLLocationDistance = 50000.0
    
    /// Screen dimensions
    let screenWidth: CGFloat
    let screenHeight: CGFloat
    
    /// Center of the screen in screen coordinates
    var screenCenter: CGPoint {
        CGPoint(x: screenWidth / 2, y: screenHeight / 2)
    }
    
    /// Width of the visible FOV arc on screen (in screen points)
    var fovScreenWidth: CGFloat {
        screenWidth * 0.9 // Use 90% of screen width for FOV
    }
    
    // MARK: - Initialization
    
    init(screenWidth: CGFloat, screenHeight: CGFloat) {
        self.screenWidth = screenWidth
        self.screenHeight = screenHeight
    }
    
    // MARK: - Public Methods
    
    /// Determines if a POI should be displayed (within FOV and distance range).
    /// - Parameters:
    ///   - bearing: The bearing to the POI in degrees (0-360)
    ///   - heading: The current device heading in degrees (0-360)
    ///   - distance: The distance to the POI in meters
    /// - Returns: true if POI should be displayed
    func shouldDisplay(bearing: Double, heading: Double, distance: CLLocationDistance) -> Bool {
        // Check distance range
        guard distance >= minDistance && distance <= maxDistance else {
            return false
        }
        
        // Check if bearing is within FOV arc centered on heading
        let fovHalfWidth = Self.horizontalFOV / 2.0
        let bearingOffset = normalizeBearingDifference(bearing - heading)
        let withinFOV = abs(bearingOffset) <= fovHalfWidth
        
        return withinFOV
    }
    
    /// Calculates the screen position for a POI label.
    /// - Parameters:
    ///   - bearing: The bearing to the POI in degrees
    ///   - heading: The current device heading in degrees
    ///   - distance: The distance to the POI in meters
    /// - Returns: The screen position (0-1 for x, 0-1 for y) where (0.5, 0.5) is center
    func calculateNormalizedPosition(bearing: Double, heading: Double, distance: CLLocationDistance) -> CGPoint {
        // Calculate horizontal offset from heading
        let fovHalfWidth = Self.horizontalFOV / 2.0
        let bearingOffset = normalizeBearingDifference(bearing - heading)
        
        // Clamp to FOV bounds with slight extension for partial clipping
        let clampedOffset = max(-fovHalfWidth - 5, min(fovHalfWidth + 5, bearingOffset))
        
        // Normalize to 0-1 range (0 = left edge, 0.5 = center, 1 = right edge)
        let normalizedX = 0.5 + (clampedOffset / (fovHalfWidth * 2.0))
        
        // Calculate vertical position based on distance
        // Closer = lower on screen, Farther = higher on screen
        let normalizedDistance = (distance - minDistance) / (maxDistance - minDistance)
        let clampedDistance = max(0.0, min(1.0, normalizedDistance))
        
        // Map distance: close (0) -> lower on screen (0.7), far (1) -> higher (0.2)
        let normalizedY = 0.2 + (1.0 - clampedDistance) * 0.5
        
        return CGPoint(x: normalizedX, y: normalizedY)
    }
    
    /// Calculates the screen position in points.
    /// - Parameters:
    ///   - bearing: The bearing to the POI in degrees
    ///   - heading: The current device heading in degrees
    ///   - distance: The distance to the POI in meters
    /// - Returns: The screen position in points
    func calculateScreenPosition(bearing: Double, heading: Double, distance: CLLocationDistance) -> CGPoint {
        let normalized = calculateNormalizedPosition(bearing: bearing, heading: heading, distance: distance)
        
        let screenX = screenCenter.x + (normalized.x - 0.5) * fovScreenWidth
        let screenY = screenCenter.y + (normalized.y - 0.5) * (screenHeight * 0.5)
        
        return CGPoint(x: screenX, y: screenY)
    }
    
    /// Calculates the text size for a label based on distance.
    /// Closer = larger, Farther = smaller.
    /// - Parameter distance: The distance to the POI in meters
    /// - Returns: Font size in points
    func calculateFontSize(for distance: CLLocationDistance) -> CGFloat {
        let normalizedDistance = (distance - minDistance) / (maxDistance - minDistance)
        let clampedDistance = max(0.0, min(1.0, normalizedDistance))
        
        // Size range: 24pt (close) to 10pt (far)
        let minSize: CGFloat = 10.0
        let maxSize: CGFloat = 24.0
        
        return maxSize - (clampedDistance * (maxSize - minSize))
    }
    
    /// Calculates the opacity for a label based on distance from FOV edges.
    /// Labels at FOV edges fade out smoothly.
    /// - Parameters:
    ///   - bearing: The bearing to the POI in degrees
    ///   - heading: The current device heading in degrees
    /// - Returns: Opacity value (0.0 to 1.0)
    func calculateOpacity(bearing: Double, heading: Double) -> Double {
        let fovHalfWidth = Self.horizontalFOV / 2.0
        let bearingOffset = normalizeBearingDifference(bearing - heading)
        
        // Fade zone: 5 degrees on each side of FOV edge
        let fadeZone = 5.0
        let distanceFromEdge = fovHalfWidth - abs(bearingOffset)
        
        if distanceFromEdge < 0 {
            return 0.0 // Outside FOV
        } else if distanceFromEdge < fadeZone {
            return Double(distanceFromEdge / fadeZone)
        } else {
            return 1.0
        }
    }
    
    /// Calculates the alpha scale (for partial clipping effect).
    /// - Parameters:
    ///   - bearing: The bearing to the POI in degrees
    ///   - heading: The current device heading in degrees
    /// - Returns: Scale value (0.0 to 1.0) for clipping
    func calculateClippingScale(bearing: Double, heading: Double) -> CGFloat {
        let fovHalfWidth = Self.horizontalFOV / 2.0
        let bearingOffset = normalizeBearingDifference(bearing - heading)
        
        // Clipping zone: 5 degrees beyond FOV edge
        let clippingZone = 5.0
        let beyondEdge = abs(bearingOffset) - fovHalfWidth
        
        if beyondEdge <= 0 {
            return 1.0 // Fully visible
        } else if beyondEdge < clippingZone {
            // Partially clipped
            return 1.0 - (beyondEdge / clippingZone)
        } else {
            return 0.0 // Fully clipped
        }
    }
    
    // MARK: - Private Helper Methods
    
    /// Normalizes bearing difference to range [-180, 180].
    /// This represents the shortest angular distance between two bearings.
    func normalizeBearingDifference(_ difference: Double) -> Double {
        var normalized = difference.truncatingRemainder(dividingBy: 360.0)
        
        if normalized > 180.0 {
            normalized -= 360.0
        } else if normalized < -180.0 {
            normalized += 360.0
        }
        
        return normalized
    }
}
