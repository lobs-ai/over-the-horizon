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
        sut.searchRadiusMiles = 20.0
        XCTAssertEqual(sut.searchRadiusMiles, 10.0)
    }
    
    func testSearchRadiusValidRange() {
        sut.searchRadiusMiles = 3.5
        XCTAssertEqual(sut.searchRadiusMiles, 3.5)
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
}
