//
//  ZoomGestureManager.swift
//  OverTheHorizon
//
//  Created by Programmer Agent
//

import SwiftUI
import Combine
import CoreLocation

/// Manages zoom state from pinch gestures.
/// Pinch OUT increases min/max distances (zoom out view, see farther, smaller labels).
/// Pinch IN decreases min/max distances (zoom in view, focus nearer, larger labels).
@MainActor
class ZoomGestureManager: NSObject, ObservableObject {
    
    /// Current zoom level (0.5 = zoomed in, 1.0 = default, 2.0 = zoomed out)
    @Published var zoomLevel: Double = 1.0
    
    /// Label scale multiplier (1.0 = default size)
    @Published var labelScaleMultiplier: Double = 1.0
    
    /// Minimum distance range in meters (can be adjusted by zoom)
    @Published var minDistance: CLLocationDistance = 100.0
    
    /// Maximum distance range in meters (can be adjusted by zoom)
    @Published var maxDistance: CLLocationDistance = 50000.0
    
    // MARK: - Configuration Constants
    
    /// Default min distance (zoom level 1.0)
    let defaultMinDistance: CLLocationDistance = 100.0
    
    /// Default max distance (zoom level 1.0)
    let defaultMaxDistance: CLLocationDistance = 50000.0
    
    /// Minimum allowed zoom level (maximum zoom in)
    let minZoomLevel: Double = 0.3
    
    /// Maximum allowed zoom level (maximum zoom out)
    let maxZoomLevel: Double = 3.0
    
    /// Minimum allowed min distance (at max zoom in)
    let absoluteMinDistance: CLLocationDistance = 50.0
    
    /// Maximum allowed max distance (at max zoom out)
    let absoluteMaxDistance: CLLocationDistance = 100000.0
    
    // MARK: - Initialization
    
    override init() {
        super.init()
        updateDistances()
    }
    
    // MARK: - Public Methods
    
    /// Updates zoom level based on pinch gesture scale factor.
    /// - Parameter scaleFactor: The scale factor from the pinch gesture (>1 = pinch out, <1 = pinch in)
    func updateZoomWithGesture(scaleFactor: CGFloat) {
        // Apply smooth scaling: each pinch unit changes zoom level
        let newZoomLevel = zoomLevel * Double(scaleFactor)
        setZoomLevel(newZoomLevel)
    }
    
    /// Sets the zoom level directly, with bounds checking.
    /// - Parameter level: The desired zoom level
    func setZoomLevel(_ level: Double) {
        let clampedLevel = max(minZoomLevel, min(maxZoomLevel, level))
        
        if abs(zoomLevel - clampedLevel) > 0.01 {  // Only update if change is meaningful
            zoomLevel = clampedLevel
            updateDistances()
        }
    }
    
    /// Resets zoom to default state
    func resetZoom() {
        zoomLevel = 1.0
        updateDistances()
    }
    
    // MARK: - Private Methods
    
    /// Updates distance ranges and label scale based on current zoom level.
    private func updateDistances() {
        // Zoom level affects distance ranges:
        // - Lower zoom (0.3): focus nearer, smaller distance range
        // - Default zoom (1.0): standard distance range
        // - Higher zoom (3.0): see farther, larger distance range
        
        let zoomFactor = zoomLevel
        
        // Min distance decreases with zoom in (focus nearer)
        // At zoom 0.3: ~30 meters, At zoom 1.0: 100 meters, At zoom 3.0: 300 meters
        minDistance = max(
            absoluteMinDistance,
            defaultMinDistance * zoomFactor
        )
        
        // Max distance increases with zoom out (see farther)
        // At zoom 0.3: ~16k meters, At zoom 1.0: 50k meters, At zoom 3.0: 150k meters
        maxDistance = min(
            absoluteMaxDistance,
            defaultMaxDistance * zoomFactor
        )
        
        // Label scale: inverse of zoom (zoom out = smaller labels)
        // At zoom 0.3: labels 3.3x larger, At zoom 1.0: labels normal, At zoom 3.0: labels 0.33x smaller
        labelScaleMultiplier = 1.0 / zoomLevel
    }
}
