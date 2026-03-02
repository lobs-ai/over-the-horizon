//
//  OverlapResolver.swift
//  OverTheHorizon
//
//  Created by Programmer Agent
//

import Foundation
import CoreGraphics

/// Resolves label overlap issues using vertical offsets and priority-based positioning.
struct OverlapResolver {
    
    /// Configuration for overlap resolution.
    struct Config {
        /// Minimum vertical spacing between overlapping labels (in screen points).
        var minVerticalSpacing: CGFloat = 60.0
        
        /// Maximum number of vertical positions to use when resolving overlaps.
        var maxVerticalLevels: Int = 3
        
        /// Initial vertical offset for labels at their base position.
        var initialVerticalOffset: CGFloat = 0.0
        
        init() {}
    }
    
    /// Result of overlap resolution containing adjusted positions.
    struct ResolvedLabel {
        let poi: POILocation
        let originalPosition: CGPoint
        let resolvedPosition: CGPoint
        let verticalOffset: CGFloat
        let zIndex: Int // Higher = draws on top
        
        init(poi: POILocation, originalPosition: CGPoint, resolvedPosition: CGPoint, verticalOffset: CGFloat, zIndex: Int) {
            self.poi = poi
            self.originalPosition = originalPosition
            self.resolvedPosition = resolvedPosition
            self.verticalOffset = verticalOffset
            self.zIndex = zIndex
        }
    }
    
    /// Configuration instance.
    let config: Config
    
    /// Minimum label dimensions for overlap detection (approximate).
    private let minLabelWidth: CGFloat = 60.0
    private let minLabelHeight: CGFloat = 24.0
    
    init(config: Config = Config()) {
        self.config = config
    }
    
    /// Resolves overlaps for a list of labels, returning adjusted positions.
    /// Positions should be in screen coordinates (points), not normalized (0-1).
    /// - Parameters:
    ///   - labels: Array of POI locations with their scores and screen positions (in points).
    ///   - screenSize: The screen size in points.
    /// - Returns: Array of resolved labels with non-overlapping positions.
    func resolveOverlaps(for labels: [(poi: POILocation, score: Double, position: CGPoint)], screenSize: CGSize) -> [ResolvedLabel] {
        guard !labels.isEmpty else { return [] }
        
        // Sort by score (highest first) for priority-based resolution
        let sortedLabels = labels.sorted { $0.score > $1.score }
        
        var resolved: [ResolvedLabel] = []
        var occupiedRegions: [CGRect] = []
        
        for label in sortedLabels {
            let basePosition = label.position
            
            // Find non-overlapping position with highest priority
            var resolvedPosition = basePosition
            var zIndex = 0
            var maxVerticalOffset: CGFloat = 0
            var foundNonOverlappingPosition = false
            
            for level in 0..<config.maxVerticalLevels {
                let testPosition = adjustPositionForLevel(basePosition, level: level, spacing: config.minVerticalSpacing, screenHeight: screenSize.height)
                let testBounds = calculateLabelBounds(for: testPosition)
                
                // Check if this position overlaps with any occupied region
                var overlaps = false
                for occupied in occupiedRegions {
                    if boundsIntersect(testBounds, occupied) {
                        overlaps = true
                        break
                    }
                }
                
                if !overlaps {
                    resolvedPosition = testPosition
                    zIndex = level * 10 // Higher levels draw on top
                    maxVerticalOffset = calculateVerticalOffset(from: basePosition, to: testPosition)
                    foundNonOverlappingPosition = true
                    break
                }
            }
            
            // If all positions overlap, accept the overlap but keep highest priority position
            if !foundNonOverlappingPosition && !occupiedRegions.isEmpty {
                zIndex = 100 // Topmost layer for unavoidable overlaps (shouldn't happen often)
            }
            
            let resolvedLabel = ResolvedLabel(
                poi: label.poi,
                originalPosition: basePosition,
                resolvedPosition: resolvedPosition,
                verticalOffset: maxVerticalOffset,
                zIndex: zIndex
            )
            
            resolved.append(resolvedLabel)
            
            // Add to occupied regions (use the position that was actually used for overlap checking)
            let finalBounds = calculateLabelBounds(for: resolvedPosition)
            occupiedRegions.append(finalBounds)
        }
        
        return resolved
    }
    
    /// Calculates approximate label bounds centered at a screen position (in points).
    private func calculateLabelBounds(for position: CGPoint) -> CGRect {
        // Position is already in screen coordinates
        return CGRect(
            x: position.x - minLabelWidth / 2,
            y: position.y - minLabelHeight / 2,
            width: minLabelWidth,
            height: minLabelHeight
        )
    }
    
    /// Adjusts position vertically based on level (0 = base, 1 = up, 2 = down).
    /// - Parameters:
    ///   - position: The base position in screen coordinates.
    ///   - level: The vertical level (0 = base, 1 = up, 2 = down).
    ///   - spacing: The vertical spacing in screen points.
    ///   - screenHeight: The height of the screen in points.
    /// - Returns: Adjusted position in screen coordinates.
    private func adjustPositionForLevel(_ position: CGPoint, level: Int, spacing: CGFloat, screenHeight: CGFloat) -> CGPoint {
        switch level {
        case 0:
            return position // Base position
        case 1:
            // Move up (decrease Y)
            let adjustedY = max(0.0, position.y - spacing)
            return CGPoint(x: position.x, y: adjustedY)
        case 2:
            // Move down (increase Y), but stay within screen bounds
            let adjustedY = min(screenHeight, position.y + spacing)
            return CGPoint(x: position.x, y: adjustedY)
        default:
            return position
        }
    }
    
    /// Calculates the vertical offset between two positions (in screen points).
    private func calculateVerticalOffset(from original: CGPoint, to adjusted: CGPoint) -> CGFloat {
        return abs(original.y - adjusted.y)
    }
    
    /// Checks if two bounds intersect with a small padding to account for text width variations.
    private func boundsIntersect(_ a: CGRect, _ b: CGRect) -> Bool {
        // Add small padding to increase detection sensitivity
        let paddingX: CGFloat = 10.0
        let paddingY: CGFloat = 5.0
        let aPadded = a.insetBy(dx: -paddingX, dy: -paddingY)
        let bPadded = b.insetBy(dx: -paddingX, dy: -paddingY)
        return aPadded.intersects(bPadded)
    }
}
