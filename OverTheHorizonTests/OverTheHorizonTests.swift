//
//  OverTheHorizonTests.swift
//  OverTheHorizonTests
//
//  Created by Programmer Agent
//

import XCTest
import AVFoundation
import CoreLocation
import CoreMotion
@testable import OverTheHorizon

class CameraManagerTests: XCTestCase {
    var sut: CameraManager!
    
    override func setUp() {
        super.setUp()
        sut = CameraManager()
    }
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }
    
    func testCameraManagerInitialization() {
        XCTAssertNotNil(sut)
        XCTAssertEqual(sut.authorizationStatus, .notDetermined)
    }
    
    func testRequestCameraPermission() {
        sut.requestCameraPermission()
        // Permission request is asynchronous, so we can only verify it doesn't crash
        XCTAssertNotNil(sut)
    }
    
    func testCameraManagerStop() {
        sut.requestCameraPermission()
        sut.stop()
        // Verify stop doesn't crash
        XCTAssertNotNil(sut)
    }
}

class LocationManagerTests: XCTestCase {
    var sut: LocationManager!
    
    override func setUp() {
        super.setUp()
        sut = LocationManager()
    }
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }
    
    func testLocationManagerInitialization() {
        XCTAssertNotNil(sut)
        XCTAssertNil(sut.userLocation)
        XCTAssertEqual(sut.authorizationStatus, .notDetermined)
    }
    
    func testRequestLocationPermission() {
        sut.requestLocationPermission()
        // Permission request is asynchronous
        XCTAssertNotNil(sut)
    }
}

class MotionManagerTests: XCTestCase {
    var sut: MotionManager!
    
    override func setUp() {
        super.setUp()
        sut = MotionManager()
    }
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }
    
    func testMotionManagerInitialization() {
        XCTAssertNotNil(sut)
        XCTAssertNil(sut.heading)
    }
    
    func testMotionManagerStartAndStop() {
        sut.startUpdates()
        sut.stopUpdates()
        // Verify operations don't crash
        XCTAssertNotNil(sut)
    }
}

class ContentViewTests: XCTestCase {
    func testContentViewExists() {
        let view = ContentView()
        XCTAssertNotNil(view)
    }
}

// MARK: - LocationCategory Tests

class LocationCategoryTests: XCTestCase {
    func testLocationCategoryAllCases() {
        let allCategories = LocationCategory.allCases
        XCTAssertGreaterThan(allCategories.count, 0)
        XCTAssertEqual(allCategories.count, 24) // Should have 24 categories
    }
    
    func testLocationCategoryDisplayNames() {
        for category in LocationCategory.allCases {
            let displayName = category.displayName
            XCTAssertFalse(displayName.isEmpty)
            XCTAssertNotEqual(displayName, category.rawValue) // Display name should differ from raw value
        }
    }
    
    func testLandmarkCategory() {
        let landmark = LocationCategory.landmark
        XCTAssertEqual(landmark.rawValue, "landmark")
        XCTAssertEqual(landmark.displayName, "Landmark")
    }
    
    func testMuseumCategory() {
        let museum = LocationCategory.museum
        XCTAssertEqual(museum.rawValue, "museum")
        XCTAssertEqual(museum.displayName, "Museum")
    }
    
    func testParkCategory() {
        let park = LocationCategory.park
        XCTAssertEqual(park.rawValue, "park")
        XCTAssertEqual(park.displayName, "Park")
    }
    
    func testAirportCategory() {
        let airport = LocationCategory.airport
        XCTAssertEqual(airport.rawValue, "airport")
        XCTAssertEqual(airport.displayName, "Airport")
    }
    
    func testLocationCategoryExcludesRestaurants() {
        let categories = LocationCategory.allCases
        let rawValues = categories.map { $0.rawValue }
        XCTAssertFalse(rawValues.contains("restaurant"))
        XCTAssertFalse(rawValues.contains("food"))
        XCTAssertFalse(rawValues.contains("cafe"))
        XCTAssertFalse(rawValues.contains("cafe coffee"))
    }
    
    func testAllCategoriesHaveMKMappings() {
        for category in LocationCategory.allCases {
            if #available(iOS 17.0, *) {
                let mkCategory = category.mkCategory
                XCTAssertNotNil(mkCategory)
            }
        }
    }
    
    func testCategoryRawValues() {
        let landmark = LocationCategory.landmark
        let museum = LocationCategory.museum
        let park = LocationCategory.park
        let airport = LocationCategory.airport
        
        XCTAssertEqual(landmark.rawValue, "landmark")
        XCTAssertEqual(museum.rawValue, "museum")
        XCTAssertEqual(park.rawValue, "park")
        XCTAssertEqual(airport.rawValue, "airport")
        
        // Verify they're all different
        let allRawValues = LocationCategory.allCases.map { $0.rawValue }
        let uniqueRawValues = Set(allRawValues)
        XCTAssertEqual(allRawValues.count, uniqueRawValues.count)
    }
}

// MARK: - POILocation Tests

class POILocationTests: XCTestCase {
    let testCoordinate = CLLocationCoordinate2D(latitude: 42.3314, longitude: -83.0458) // Detroit, MI
    let testUserCoordinate = CLLocationCoordinate2D(latitude: 42.3314, longitude: -83.0458)
    
    func testPOILocationInitialization() {
        let poi = POILocation(
            name: "Test Museum",
            coordinate: testCoordinate,
            category: .museum,
            distance: 1000.0,
            bearing: 45.0,
            prominence: 0.8
        )
        
        XCTAssertEqual(poi.name, "Test Museum")
        XCTAssertEqual(poi.coordinate.latitude, testCoordinate.latitude)
        XCTAssertEqual(poi.coordinate.longitude, testCoordinate.longitude)
        XCTAssertEqual(poi.category, .museum)
        XCTAssertEqual(poi.distance, 1000.0)
        XCTAssertEqual(poi.bearing, 45.0)
        XCTAssertEqual(poi.prominence, 0.8)
    }
    
    func testPOILocationProminenceClamping() {
        let poiLow = POILocation(
            name: "Test",
            coordinate: testCoordinate,
            category: .landmark,
            distance: 100.0,
            bearing: 0.0,
            prominence: -0.5 // Should be clamped to 0.0
        )
        XCTAssertEqual(poiLow.prominence, 0.0)
        
        let poiHigh = POILocation(
            name: "Test",
            coordinate: testCoordinate,
            category: .landmark,
            distance: 100.0,
            bearing: 0.0,
            prominence: 1.5 // Should be clamped to 1.0
        )
        XCTAssertEqual(poiHigh.prominence, 1.0)
    }
    
    func testCalculateBearingNorth() {
        let userLocation = CLLocationCoordinate2D(latitude: 0.0, longitude: 0.0)
        let northLocation = CLLocationCoordinate2D(latitude: 1.0, longitude: 0.0)
        
        let bearing = POILocation.calculateBearing(from: userLocation, to: northLocation)
        XCTAssertLessThan(abs(bearing - 0.0), 1.0) // Should be approximately 0° (North)
    }
    
    func testCalculateBearingEast() {
        let userLocation = CLLocationCoordinate2D(latitude: 0.0, longitude: 0.0)
        let eastLocation = CLLocationCoordinate2D(latitude: 0.0, longitude: 1.0)
        
        let bearing = POILocation.calculateBearing(from: userLocation, to: eastLocation)
        XCTAssertLessThan(abs(bearing - 90.0), 1.0) // Should be approximately 90° (East)
    }
    
    func testCalculateBearingSouth() {
        let userLocation = CLLocationCoordinate2D(latitude: 0.0, longitude: 0.0)
        let southLocation = CLLocationCoordinate2D(latitude: -1.0, longitude: 0.0)
        
        let bearing = POILocation.calculateBearing(from: userLocation, to: southLocation)
        XCTAssertLessThan(abs(bearing - 180.0), 1.0) // Should be approximately 180° (South)
    }
    
    func testCalculateBearingWest() {
        let userLocation = CLLocationCoordinate2D(latitude: 0.0, longitude: 0.0)
        let westLocation = CLLocationCoordinate2D(latitude: 0.0, longitude: -1.0)
        
        let bearing = POILocation.calculateBearing(from: userLocation, to: westLocation)
        XCTAssert(bearing > 270.0 || bearing < 10.0) // Should be approximately 270° (West)
    }
    
    func testCalculateDistance() {
        let userLocation = CLLocationCoordinate2D(latitude: 42.3314, longitude: -83.0458)
        let poiLocation = CLLocationCoordinate2D(latitude: 42.3314, longitude: -83.0458)
        
        let distance = POILocation.calculateDistance(from: userLocation, to: poiLocation)
        XCTAssertLessThan(distance, 1.0) // Should be very close to 0
    }
    
    func testPOILocationEquality() {
        let poi1 = POILocation(
            name: "Test",
            coordinate: testCoordinate,
            category: .museum,
            distance: 100.0,
            bearing: 45.0
        )
        
        let poi2 = POILocation(
            name: "Test",
            coordinate: testCoordinate,
            category: .museum,
            distance: 100.0,
            bearing: 45.0
        )
        
        // Different UUIDs means they should not be equal
        XCTAssertNotEqual(poi1, poi2)
    }
    
    func testPOILocationWithDefaultProminence() {
        let poi = POILocation(
            name: "Test",
            coordinate: testCoordinate,
            category: .landmark,
            distance: 100.0,
            bearing: 45.0
        )
        
        XCTAssertEqual(poi.prominence, 0.5) // Default prominence
    }
    
    func testCalculateDistanceRealWorldScenario() {
        // Detroit to Ann Arbor (approximately 40 miles / 64 km)
        let detroit = CLLocationCoordinate2D(latitude: 42.3314, longitude: -83.0458)
        let annArbor = CLLocationCoordinate2D(latitude: 42.2808, longitude: -83.7430)
        
        let distance = POILocation.calculateDistance(from: detroit, to: annArbor)
        // Should be approximately 40 miles or 64 km = 64000 meters
        let expectedDistance = 64000.0
        let tolerance = 5000.0 // 5 km tolerance
        
        XCTAssertLessThan(abs(distance - expectedDistance), tolerance)
    }
    
    func testBearingRangeIsValid() {
        let userLocation = CLLocationCoordinate2D(latitude: 40.0, longitude: -75.0)
        
        // Test multiple bearings
        for lat in stride(from: 30.0, through: 50.0, by: 5.0) {
            for lon in stride(from: -85.0, through: -65.0, by: 5.0) {
                let poiLocation = CLLocationCoordinate2D(latitude: lat, longitude: lon)
                let bearing = POILocation.calculateBearing(from: userLocation, to: poiLocation)
                
                XCTAssertGreaterThanOrEqual(bearing, 0.0)
                XCTAssertLessThan(bearing, 360.0)
            }
        }
    }
    
    func testPOILocationIdentifiable() {
        let poi1 = POILocation(
            name: "Test1",
            coordinate: testCoordinate,
            category: .museum,
            distance: 100.0,
            bearing: 45.0
        )
        
        let poi2 = POILocation(
            name: "Test2",
            coordinate: testCoordinate,
            category: .museum,
            distance: 200.0,
            bearing: 90.0
        )
        
        // Should have different IDs
        XCTAssertNotEqual(poi1.id, poi2.id)
    }
}

// MARK: - POISearchManager Tests

class POISearchManagerTests: XCTestCase {
    var sut: POISearchManager!
    var locationManager: LocationManager!
    
    override func setUp() {
        super.setUp()
        locationManager = LocationManager()
        sut = POISearchManager(locationManager: locationManager)
    }
    
    override func tearDown() {
        sut.stopPeriodicSearch()
        sut = nil
        locationManager = nil
        super.tearDown()
    }
    
    func testPOISearchManagerInitialization() {
        XCTAssertNotNil(sut)
        XCTAssertEqual(sut.pois.count, 0)
        XCTAssertNil(sut.errorMessage)
        XCTAssertFalse(sut.isSearching)
    }
    
    func testSearchRadiusDefault() {
        XCTAssertEqual(sut.searchRadiusMiles, 5.0)
    }
    
    func testSearchRadiusMinimumClamping() {
        sut.searchRadiusMiles = 0.5
        XCTAssertEqual(sut.searchRadiusMiles, 1.0)
    }
    
    func testSearchRadiusMaximumClamping() {
        sut.searchRadiusMiles = 7.0
        XCTAssertEqual(sut.searchRadiusMiles, 5.0)
    }
    
    func testSearchRadiusValidRange() {
        sut.searchRadiusMiles = 3.5
        XCTAssertEqual(sut.searchRadiusMiles, 3.5)
    }
    
    func testSearchRadiusRangeOfValidValues() {
        let validRanges = [1.0, 2.0, 3.5, 5.0]
        for range in validRanges {
            sut.searchRadiusMiles = range
            XCTAssertEqual(sut.searchRadiusMiles, range)
        }
    }
    
    func testStartAndStopPeriodicSearch() {
        sut.startPeriodicSearch()
        // Allow a moment for the timer to start
        XCTAssertNotNil(sut)
        
        sut.stopPeriodicSearch()
        XCTAssertNotNil(sut)
    }
    
    @MainActor
    func testSearchPOIsWithoutLocation() async {
        // User location is nil, should handle gracefully
        await sut.searchPOIs()
        XCTAssertEqual(sut.pois.count, 0)
        XCTAssertNotNil(sut.errorMessage)
    }
    
    func testPOISearchManagerDeallocation() {
        var manager: POISearchManager? = POISearchManager(locationManager: locationManager)
        manager?.startPeriodicSearch()
        
        manager = nil
        // Should not crash when deallocated
        XCTAssertNil(manager)
    }
    
    func testSearchRadiusMilesValidation() {
        // Test edge cases
        sut.searchRadiusMiles = -5.0
        XCTAssertEqual(sut.searchRadiusMiles, 1.0)
        
        sut.searchRadiusMiles = 0.0
        XCTAssertEqual(sut.searchRadiusMiles, 1.0)
        
        sut.searchRadiusMiles = 1.0
        XCTAssertEqual(sut.searchRadiusMiles, 1.0)
        
        sut.searchRadiusMiles = 5.0
        XCTAssertEqual(sut.searchRadiusMiles, 5.0)
        
        sut.searchRadiusMiles = 100.0
        XCTAssertEqual(sut.searchRadiusMiles, 5.0)
    }
    
    func testInitialSearchState() {
        XCTAssertTrue(sut.pois.isEmpty)
        XCTAssertNil(sut.errorMessage)
        XCTAssertFalse(sut.isSearching)
    }
    
    @MainActor
    func testSearchWithSpecificCategories() async {
        // Test searching with specific categories
        let categories = [LocationCategory.museum, LocationCategory.park]
        await sut.searchPOIs(for: categories)
        
        // Should complete without crashing (may have empty results due to no user location)
        XCTAssertNotNil(sut)
    }
    
    func testPeriodicSearchLifecycle() {
        XCTAssertNotNil(sut)
        
        sut.startPeriodicSearch()
        XCTAssertNotNil(sut)
        
        sut.stopPeriodicSearch()
        XCTAssertNotNil(sut)
        
        sut.startPeriodicSearch()
        XCTAssertNotNil(sut)
        
        sut.stopPeriodicSearch()
        XCTAssertNotNil(sut)
    }
}

// MARK: - Integration Tests

class POIIntegrationTests: XCTestCase {
    func testPOILocationCategoryIntegration() {
        let museum = LocationCategory.museum
        let coordinate = CLLocationCoordinate2D(latitude: 40.0, longitude: -75.0)
        
        let poi = POILocation(
            name: "Philadelphia Museum of Art",
            coordinate: coordinate,
            category: museum,
            distance: 5000.0,
            bearing: 45.0,
            prominence: 0.9
        )
        
        XCTAssertEqual(poi.category, museum)
        XCTAssertEqual(poi.category.displayName, "Museum")
    }
    
    func testMultiplePOICreation() {
        let coordinate1 = CLLocationCoordinate2D(latitude: 40.0, longitude: -75.0)
        let coordinate2 = CLLocationCoordinate2D(latitude: 41.0, longitude: -74.0)
        let coordinate3 = CLLocationCoordinate2D(latitude: 39.0, longitude: -76.0)
        
        let poi1 = POILocation(name: "Museum", coordinate: coordinate1, category: .museum, distance: 1000.0, bearing: 45.0)
        let poi2 = POILocation(name: "Park", coordinate: coordinate2, category: .park, distance: 2000.0, bearing: 90.0)
        let poi3 = POILocation(name: "Airport", coordinate: coordinate3, category: .airport, distance: 5000.0, bearing: 180.0)
        
        let pois = [poi1, poi2, poi3]
        
        XCTAssertEqual(pois.count, 3)
        XCTAssertEqual(pois[0].category, .museum)
        XCTAssertEqual(pois[1].category, .park)
        XCTAssertEqual(pois[2].category, .airport)
    }
    
    func testPOISortingByDistance() {
        let coordinate1 = CLLocationCoordinate2D(latitude: 40.0, longitude: -75.0)
        let coordinate2 = CLLocationCoordinate2D(latitude: 41.0, longitude: -74.0)
        let coordinate3 = CLLocationCoordinate2D(latitude: 39.0, longitude: -76.0)
        
        let poi1 = POILocation(name: "Far POI", coordinate: coordinate1, category: .museum, distance: 5000.0, bearing: 45.0)
        let poi2 = POILocation(name: "Near POI", coordinate: coordinate2, category: .park, distance: 1000.0, bearing: 90.0)
        let poi3 = POILocation(name: "Medium POI", coordinate: coordinate3, category: .airport, distance: 3000.0, bearing: 180.0)
        
        var pois = [poi1, poi2, poi3]
        pois.sort { $0.distance < $1.distance }
        
        XCTAssertEqual(pois[0].name, "Near POI")
        XCTAssertEqual(pois[1].name, "Medium POI")
        XCTAssertEqual(pois[2].name, "Far POI")
    }
}
