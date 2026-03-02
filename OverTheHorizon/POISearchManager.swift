//
//  POISearchManager.swift
//  OverTheHorizon
//
//  Created by Programmer Agent
//

import Foundation
import CoreLocation
import MapKit
import SwiftUI

/// Manages the discovery and periodic updating of points of interest using Apple Maps.
class POISearchManager: NSObject, ObservableObject {
    // MARK: - Published Properties
    
    /// Array of discovered POIs, sorted by proximity to user.
    @Published var pois: [POILocation] = []
    
    /// Search radius in miles. Default is 5 miles, configurable from 1-10 miles.
    @Published var searchRadiusMiles: Double = 5.0 {
        didSet {
            // Clamp to 1-10 mile range
            searchRadiusMiles = max(1.0, min(10.0, searchRadiusMiles))
        }
    }
    
    /// Whether POI search is currently active.
    @Published var isSearching: Bool = false
    
    /// Error message if search fails.
    @Published var errorMessage: String?
    
    // MARK: - Private Properties
    
    /// Distance threshold (in meters) that triggers a new search.
    /// Default is 500 meters (0.3 miles).
    private let significantMovementThreshold: CLLocationDistance = 500.0
    
    /// Last location where a search was performed.
    private var lastSearchLocation: CLLocation?
    
    /// Timer for periodic re-search.
    private var searchTimer: Timer?
    
    /// Interval (in seconds) for periodic searches. Default is 30 seconds.
    private let periodicSearchInterval: TimeInterval = 30.0
    
    /// Location manager for tracking user movement.
    private let locationManager: LocationManager
    
    /// Categories to search for (all supported categories by default).
    private var categoriesToSearch: [LocationCategory] = LocationCategory.allCases
    
    // MARK: - Initialization
    
    /// Creates a new POI Search Manager.
    /// - Parameter locationManager: The location manager instance for user location tracking.
    init(locationManager: LocationManager) {
        self.locationManager = locationManager
        super.init()
        setupPeriodicSearch()
    }
    
    deinit {
        stopPeriodicSearch()
    }
    
    // MARK: - Public Methods
    
    /// Performs a POI search centered on the user's current location.
    /// - Parameters:
    ///   - categories: Categories to search for. If nil, uses all categories.
    func searchPOIs(for categories: [LocationCategory]? = nil) async {
        guard let userLocation = locationManager.userLocation else {
            DispatchQueue.main.async {
                self.errorMessage = "User location not available"
            }
            return
        }
        
        let categoriesToUse = categories ?? LocationCategory.allCases
        self.categoriesToSearch = categoriesToUse
        
        DispatchQueue.main.async {
            self.isSearching = true
            self.errorMessage = nil
        }
        
        var discoveredPOIs: [POILocation] = []
        
        // Search for each category
        for category in categoriesToUse {
            let pois = await searchCategory(category, from: userLocation)
            discoveredPOIs.append(contentsOf: pois)
        }
        
        // Sort by distance (closest first)
        discoveredPOIs.sort { $0.distance < $1.distance }
        
        DispatchQueue.main.async {
            self.pois = discoveredPOIs
            self.lastSearchLocation = userLocation
            self.isSearching = false
        }
    }
    
    /// Starts periodic re-searching for POIs on user movement.
    func startPeriodicSearch() {
        setupPeriodicSearch()
    }
    
    /// Stops periodic re-searching for POIs.
    func stopPeriodicSearch() {
        searchTimer?.invalidate()
        searchTimer = nil
    }
    
    // MARK: - Private Methods
    
    /// Searches for POIs in a specific category.
    private func searchCategory(_ category: LocationCategory, from userLocation: CLLocation) async -> [POILocation] {
        let searchRequest = MKLocalSearch.Request()
        searchRequest.naturalLanguageQuery = category.rawValue
        
        let region = MKCoordinateRegion(
            center: userLocation.coordinate,
            span: MKCoordinateSpan(
                latitudeDelta: searchRadiusMiles / 69.0,
                longitudeDelta: searchRadiusMiles / 69.0
            )
        )
        searchRequest.region = region
        
        let search = MKLocalSearch(request: searchRequest)
        
        do {
            let response = try await search.start()
            
            var categoryPOIs: [POILocation] = []
            
            for mapItem in response.mapItems {
                guard let name = mapItem.name,
                      let location = mapItem.placemark.location else {
                    continue
                }
                
                let distance = userLocation.distance(from: location)
                let bearing = POILocation.calculateBearing(
                    from: userLocation.coordinate,
                    to: location.coordinate
                )
                
                // Estimate prominence based on availability of additional info
                let prominence: Double
                if mapItem.phoneNumber != nil || mapItem.url != nil {
                    prominence = 0.8 // Higher prominence for detailed POIs
                } else {
                    prominence = 0.5
                }
                
                let poi = POILocation(
                    name: name,
                    coordinate: location.coordinate,
                    category: category,
                    distance: distance,
                    bearing: bearing,
                    prominence: prominence
                )
                
                categoryPOIs.append(poi)
            }
            
            return categoryPOIs
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "Search failed for \(category.displayName): \(error.localizedDescription)"
            }
            return []
        }
    }
    
    /// Sets up periodic search timer and location monitoring.
    private func setupPeriodicSearch() {
        // Stop existing timer
        stopPeriodicSearch()
        
        // Create a new periodic search timer
        searchTimer = Timer.scheduledTimer(withTimeInterval: periodicSearchInterval, repeats: true) { [weak self] _ in
            Task {
                await self?.checkForMovementAndSearch()
            }
        }
        
        // Perform initial search immediately
        Task {
            await searchPOIs()
        }
    }
    
    /// Checks if user has moved significantly and performs new search if needed.
    private func checkForMovementAndSearch() async {
        guard let currentLocation = locationManager.userLocation else { return }
        
        // Check if last search location exists and user has moved beyond threshold
        if let lastSearchLocation = lastSearchLocation {
            let distance = currentLocation.distance(from: lastSearchLocation)
            if distance < significantMovementThreshold {
                return // No significant movement, skip search
            }
        }
        
        // Perform new search due to significant movement
        await searchPOIs()
    }
}
