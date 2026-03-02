//
//  AROverlayView.swift
//  OverTheHorizon
//
//  Created by Programmer Agent
//

import SwiftUI
import CoreLocation

/// Maximum number of labels to display simultaneously.
let maxDisplayedLabels = 10

/// Renders the AR overlay with POI labels positioned and scaled based on bearing, heading, and distance.
struct AROverlayView: View {
    /// Array of POIs to display (before filtering/sorting)
    let pois: [POILocation]
    
    /// Current device heading in degrees
    let heading: Double?
    
    /// Zoom gesture manager for distance range and label scaling
    @ObservedObject var zoomGestureManager: ZoomGestureManager
    
    /// Screen dimensions
    @State private var screenSize: CGSize = .zero
    
    /// Positioner for calculating label positions
    private var positioner: ARLabelPositioner {
        ARLabelPositioner(
            screenWidth: screenSize.width,
            screenHeight: screenSize.height,
            minDistance: zoomGestureManager.minDistance,
            maxDistance: zoomGestureManager.maxDistance,
            labelScaleMultiplier: zoomGestureManager.labelScaleMultiplier
        )
    }
    
    /// Overlap resolver for positioning non-overlapping labels
    private var overlapResolver: OverlapResolver {
        OverlapResolver()
    }
    
    /// Computed property with filtered and scored POIs (max 10).
    private var displayedPOIs: [(poi: POILocation, score: Double)] {
        guard let heading = heading else { return [] }
        
        // Filter POIs that should be displayed based on FOV and distance
        let visiblePOIs = pois.filter { poi in
            positioner.shouldDisplay(bearing: poi.bearing, heading: heading, distance: poi.distance)
        }
        
        // Calculate interest scores for each visible POI
        var scoredPOIs: [(poi: POILocation, score: Double)] = []
        for poi in visiblePOIs {
            let bearingOffset = positioner.normalizeBearingDifference(poi.bearing - heading)
            let score = POIScorer.calculateInterestScore(for: poi, bearingOffset: bearingOffset)
            scoredPOIs.append((poi: poi, score: score))
        }
        
        // Sort by score (highest first) and limit to maxDisplayedLabels
        scoredPOIs.sort { $0.score > $1.score }
        return Array(scoredPOIs.prefix(maxDisplayedLabels))
    }
    
    /// Resolved labels with overlap-adjusted positions.
    private var resolvedLabels: [OverlapResolver.ResolvedLabel] {
        let scorePairs = displayedPOIs.map { (poi: $0.poi, score: $0.score) }
        
        // Calculate screen positions for each POI
        var labeledPositions: [(poi: POILocation, score: Double, position: CGPoint)] = []
        for pair in scorePairs {
            let position = positioner.calculateScreenPosition(
                bearing: pair.poi.bearing,
                heading: heading ?? 0.0,
                distance: pair.poi.distance
            )
            labeledPositions.append((pair.poi, pair.score, position))
        }
        
        // Resolve overlaps using priority-based vertical offsetting
        return overlapResolver.resolveOverlaps(for: labeledPositions, screenSize: screenSize)
    }
    
    var body: some View {
        ZStack {
            // Transparent overlay that captures screen size
            GeometryReader { geometry in
                Color.clear
                    .onAppear {
                        screenSize = geometry.size
                    }
                    .onChange(of: geometry.size) { newSize in
                        screenSize = newSize
                    }
                
                // Render resolved labels (non-overlapping, priority-based)
                ZStack {
                    ForEach(resolvedLabels, id: \.poi.id) { resolvedLabel in
                        POILabelView(
                            poi: resolvedLabel.poi,
                            heading: heading,
                            positioner: positioner,
                            adjustedPosition: resolvedLabel.resolvedPosition,
                            zIndex: resolvedLabel.zIndex
                        )
                    }
                }
                .ignoresSafeArea()
            }
        }
        .ignoresSafeArea()
    }
}

/// Individual POI label view with name, arrow, and positioning/scaling.
struct POILabelView: View {
    let poi: POILocation
    let heading: Double?
    let positioner: ARLabelPositioner
    
    /// Position adjusted for overlap resolution (may differ from calculated).
    let adjustedPosition: CGPoint
    
    /// Z-index for layering (higher = draws on top).
    let zIndex: Int
    
    /// Animation state for smooth transitions
    @State private var isVisible: Bool = true
    
    var body: some View {
        let shouldDisplay = shouldShowPOI()
        let fontSize = positioner.calculateFontSize(for: poi.distance)
        let opacity = positioner.calculateOpacity(bearing: poi.bearing, heading: heading ?? 0.0)
        let clippingScale = positioner.calculateClippingScale(bearing: poi.bearing, heading: heading ?? 0.0)
        
        if shouldDisplay && clippingScale > 0 {
            VStack(spacing: 2) {
                // POI Name
                Text(poi.name)
                    .font(.system(size: fontSize, weight: .semibold, design: .default))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .truncationMode(.tail)
                
                // Downward Arrow
                Image(systemName: "arrowtriangle.down.fill")
                    .font(.system(size: fontSize * 0.6))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 4)
            .background(Color.black.opacity(0.6))
            .cornerRadius(6)
            .position(adjustedPosition)
            .opacity(opacity)
            .scaleEffect(clippingScale, anchor: .center)
            .zIndex(CGFloat(zIndex))
            .transition(.opacity)
            .animation(.easeInOut(duration: 0.3), value: shouldDisplay)
            .animation(.easeInOut(duration: 0.1), value: fontSize)
        }
    }
    
    /// Determines if the POI should be displayed based on current heading and distance.
    private func shouldShowPOI() -> Bool {
        guard let heading = heading else { return false }
        return positioner.shouldDisplay(bearing: poi.bearing, heading: heading, distance: poi.distance)
    }
}

#Preview {
    AROverlayView(
        pois: [
            POILocation(
                name: "Museum",
                coordinate: CLLocationCoordinate2D(latitude: 42.0, longitude: -83.0),
                category: .museum,
                distance: 5000,
                bearing: 45,
                prominence: 0.8
            ),
            POILocation(
                name: "Park",
                coordinate: CLLocationCoordinate2D(latitude: 42.1, longitude: -83.1),
                category: .park,
                distance: 2000,
                bearing: 0,
                prominence: 0.7
            ),
            POILocation(
                name: "Landmark",
                coordinate: CLLocationCoordinate2D(latitude: 41.9, longitude: -82.9),
                category: .landmark,
                distance: 10000,
                bearing: 90,
                prominence: 0.6
            )
        ],
        heading: 0.0,
        zoomGestureManager: ZoomGestureManager()
    )
}
