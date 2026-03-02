//
//  POIScorer.swift
//  OverTheHorizon
//
//  Created by Programmer Agent
//

import Foundation
import CoreLocation

/// Calculates deterministic interest scores for POIs based on multiple factors.
struct POIScorer {
    
    // MARK: - Category Significance Scores
    
    /// Category significance weights (higher = more important).
    /// Parks and landmarks get highest priority, civic buildings lowest.
    static let categoryScores: [LocationCategory: Double] = [
        .landmark: 10.0,      // Highest priority
        .monument: 9.5,
        .viewpoint: 9.0,
        .museum: 9.0,
        .historicSite: 8.5,
        .amusementPark: 8.0,
        .zoo: 8.0,
        .aquarium: 7.5,
        .theater: 7.5,
        .venue: 7.5,
        .stadium: 7.5,
        .park: 9.0,           // High priority for parks
        .beach: 8.0,
        .trailhead: 7.0,
        .golfCourse: 6.0,
        .recreationFacility: 6.0,
        .airport: 7.0,
        .trainStation: 6.5,
        .ferryTerminal: 6.0,
        .campground: 5.0,
        .library: 5.5,
        .university: 5.5,
        .governmentBuilding: 4.0,  // Lower priority (civic)
        .publicSpace: 5.0      // Lower priority (civic/public)
    ]
    
    /// Minimum and maximum distance bounds for scoring.
    static let minDistance: CLLocationDistance = 100.0
    static let maxDistance: CLLocationDistance = 50000.0
    
    /// Optimal midpoint distance where interest is maximized.
    static let optimalDistance: CLLocationDistance = (minDistance + maxDistance) / 2.0 // 25,050 meters
    
    /// FOV half-width for directional centrality calculation.
    static let fovHalfWidth: Double = 22.5 // Half of 45° FOV
    
    // MARK: - Scoring Methods
    
    /// Calculates the complete interest score for a POI.
    /// Score is normalized to [0, 1] range where higher = more interesting.
    /// - Parameters:
    ///   - poi: The point of interest to score.
    ///   - bearingOffset: Angular offset from device heading (in degrees).
    /// - Returns: Normalized interest score in range [0, 1].
    static func calculateInterestScore(for poi: POILocation, bearingOffset: Double) -> Double {
        let categoryScore = calculateCategorySignificanceScore(for: poi.category)
        let distanceScore = calculateDistanceWeightingScore(for: poi.distance)
        let prominenceScore = poi.prominence // Already normalized [0, 1]
        let directionalScore = calculateDirectionalCentralityScore(bearingOffset: bearingOffset)
        
        // Weighted combination of all factors
        // Category (35%), Distance (25%), Prominence (25%), Directional (15%)
        let finalScore = categoryScore * 0.35 +
                        distanceScore * 0.25 +
                        prominenceScore * 0.25 +
                        directionalScore * 0.15
        
        return clamp(finalScore, min: 0.0, max: 1.0)
    }
    
    /// Calculates category significance score (higher for parks/landmarks).
    private static func calculateCategorySignificanceScore(for category: LocationCategory) -> Double {
        guard let baseScore = categoryScores[category] else {
            return 5.0 // Default mid-range score for unknown categories
        }
        
        // Normalize to [0, 1] range (scores range from ~4 to 10)
        let minScore = 4.0
        let maxScore = 10.0
        
        return (baseScore - minScore) / (maxScore - minScore)
    }
    
    /// Calculates distance weighting score (optimal at midpoint, lower at extremes).
    private static func calculateDistanceWeightingScore(for distance: CLLocationDistance) -> Double {
        let clampedDistance = clamp(distance, min: minDistance, max: maxDistance)
        
        // Calculate normalized distance from optimal point [0, 1]
        // Distance is closest to optimal when score is highest
        let distFromOptimal = abs(clampedDistance - optimalDistance)
        let maxDistFromOptimal = (maxDistance - minDistance) / 2.0
        
        // Normalize: 0 at optimal, 1 at extremes
        let normalizedDist = clamp(distFromOptimal / maxDistFromOptimal, min: 0.0, max: 1.0)
        
        // Convert to score: high near midpoint, low at extremes (parabolic curve)
        return 1.0 - (normalizedDist * normalizedDist)
    }
    
    /// Calculates directional centrality score (center of FOV > edges).
    private static func calculateDirectionalCentralityScore(bearingOffset: Double) -> Double {
        let absOffset = abs(normalizeBearingDifference(bearingOffset))
        
        // Clamp to FOV bounds with slight extension for partial clipping
        let clampedOffset = max(0.0, min(absOffset, fovHalfWidth + 5.0))
        
        // Score highest at center (offset = 0), decreasing toward edges
        // Use cosine-based falloff for smooth transition
        // Center: cos(0) = 1, Edge: cos(pi/2) ≈ 0
        let normalizedOffset = clamp(clampedOffset / fovHalfWidth, min: 0.0, max: 1.0)
        
        // Cosine curve from center to edge (smooth falloff)
        return cos(normalizedOffset * Double.pi / 2.0)
    }
    
    /// Normalizes bearing difference to range [-180, 180].
    private static func normalizeBearingDifference(_ difference: Double) -> Double {
        var normalized = difference.truncatingRemainder(dividingBy: 360.0)
        
        if normalized > 180.0 {
            normalized -= 360.0
        } else if normalized < -180.0 {
            normalized += 360.0
        }
        
        return normalized
    }
    
    /// Clamps value to specified range.
    private static func clamp(_ value: Double, min: Double, max: Double) -> Double {
        return max(min, min(value, max))
    }
    
    /// Clamps CGFloat value to specified range.
    private static func clamp(_ value: CGFloat, min: CGFloat, max: CGFloat) -> CGFloat {
        return max(min, min(value, max))
    }
}
