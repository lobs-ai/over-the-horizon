//
//  LocationCategory.swift
//  OverTheHorizon
//
//  Created by Programmer Agent
//

import Foundation
import MapKit

/// Represents all supported point-of-interest categories for map search.
/// Excludes restaurants and food-related categories.
enum LocationCategory: String, CaseIterable, Codable {
    // Landmarks & Monuments
    case landmark = "landmark"
    case monument = "monument"
    
    // Culture & History
    case museum = "museum"
    case historicSite = "historic site"
    
    // Nature & Recreation
    case park = "park"
    case beach = "beach"
    case viewpoint = "viewpoint"
    case trailhead = "trailhead"
    
    // Entertainment & Leisure
    case amusementPark = "amusement park"
    case zoo = "zoo"
    case aquarium = "aquarium"
    case theater = "theater"
    case venue = "venue"
    case stadium = "stadium"
    case golfCourse = "golf course"
    case recreationFacility = "recreation facility"
    
    // Transportation
    case airport = "airport"
    case trainStation = "train station"
    case ferryTerminal = "ferry terminal"
    
    // Accommodation & Facilities
    case campground = "campground"
    case library = "library"
    case university = "university"
    case governmentBuilding = "government building"
    case publicSpace = "public space"
    
    /// Represents a grouping of related categories
    enum Group: String, CaseIterable {
        case landmarksAndCulture = "Landmarks and Culture"
        case natureAndOutdoors = "Nature and Outdoors"
        case entertainmentAndAttractions = "Entertainment and Attractions"
        case sportsAndRecreation = "Sports and Recreation"
        case travelAndInfrastructure = "Travel and Infrastructure"
        case civicAndPublicInterest = "Civic and Public Interest"
    }
    
    /// Returns the group this category belongs to
    var group: LocationCategory.Group {
        switch self {
        case .landmark, .monument, .museum, .historicSite:
            return .landmarksAndCulture
        case .park, .beach, .viewpoint, .trailhead:
            return .natureAndOutdoors
        case .amusementPark, .zoo, .aquarium, .theater, .venue, .stadium, .golfCourse, .recreationFacility:
            return .entertainmentAndAttractions
        case .campground:
            return .sportsAndRecreation
        case .airport, .trainStation, .ferryTerminal:
            return .travelAndInfrastructure
        case .library, .university, .governmentBuilding, .publicSpace:
            return .civicAndPublicInterest
        }
    }
    
    /// Return a human-readable display name for the category.
    var displayName: String {
        switch self {
        case .landmark:
            return "Landmark"
        case .monument:
            return "Monument"
        case .museum:
            return "Museum"
        case .historicSite:
            return "Historic Site"
        case .park:
            return "Park"
        case .beach:
            return "Beach"
        case .viewpoint:
            return "Viewpoint"
        case .trailhead:
            return "Trailhead"
        case .amusementPark:
            return "Amusement Park"
        case .zoo:
            return "Zoo"
        case .aquarium:
            return "Aquarium"
        case .theater:
            return "Theater"
        case .venue:
            return "Venue"
        case .stadium:
            return "Stadium"
        case .golfCourse:
            return "Golf Course"
        case .recreationFacility:
            return "Recreation Facility"
        case .airport:
            return "Airport"
        case .trainStation:
            return "Train Station"
        case .ferryTerminal:
            return "Ferry Terminal"
        case .campground:
            return "Campground"
        case .library:
            return "Library"
        case .university:
            return "University"
        case .governmentBuilding:
            return "Government Building"
        case .publicSpace:
            return "Public Space"
        }
    }
    
    /// Returns the MKLocalPointOfInterestFilter category for the location category.
    /// This maps our custom categories to Apple's MKPointOfInterestCategory.
    @available(iOS 17.0, *)
    var mkCategory: MKPointOfInterestCategory {
        switch self {
        case .landmark:
            return .landmark
        case .monument:
            return .landmark // Maps to landmark
        case .museum:
            return .museum
        case .historicSite:
            return .landmark
        case .park:
            return .park
        case .beach:
            return .beach
        case .viewpoint:
            return .landmark
        case .trailhead:
            return .park
        case .amusementPark:
            return .amusementPark
        case .zoo:
            return .zoo
        case .aquarium:
            return .aquarium
        case .theater:
            return .theater
        case .venue:
            return .stadium // Maps to stadium/venue
        case .stadium:
            return .stadium
        case .golfCourse:
            return .golfCourse
        case .recreationFacility:
            return .park
        case .airport:
            return .airport
        case .trainStation:
            return .trainStation
        case .ferryTerminal:
            return .park // Falls back to park
        case .campground:
            return .campground
        case .library:
            return .library
        case .university:
            return .university
        case .governmentBuilding:
            return .landmark
        case .publicSpace:
            return .park
        }
    }
}
