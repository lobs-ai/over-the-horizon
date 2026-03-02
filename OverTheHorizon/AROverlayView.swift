//
//  AROverlayView.swift
//  OverTheHorizon
//
//  Created by Programmer Agent
//

import SwiftUI
import CoreLocation

/// Renders the AR overlay with POI labels positioned and scaled based on bearing, heading, and distance.
struct AROverlayView: View {
    /// Array of POIs to display
    let pois: [POILocation]
    
    /// Current device heading in degrees
    let heading: Double?
    
    /// Screen dimensions
    @State private var screenSize: CGSize = .zero
    
    /// Positioner for calculating label positions
    private var positioner: ARLabelPositioner {
        ARLabelPositioner(screenWidth: screenSize.width, screenHeight: screenSize.height)
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
                
                // Render labels
                ZStack {
                    ForEach(pois) { poi in
                        POILabelView(
                            poi: poi,
                            heading: heading,
                            positioner: positioner
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
    
    /// Animation state for smooth transitions
    @State private var isVisible: Bool = true
    
    var body: some View {
        let shouldDisplay = shouldShowPOI()
        let position = positioner.calculateScreenPosition(
            bearing: poi.bearing,
            heading: heading ?? 0.0,
            distance: poi.distance
        )
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
            .position(position)
            .opacity(opacity)
            .scaleEffect(clippingScale, anchor: .center)
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
        heading: 0.0
    )
}
