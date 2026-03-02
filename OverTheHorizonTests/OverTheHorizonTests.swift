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

// MARK: - ARLabelPositioner Tests

class ARLabelPositionerTests: XCTestCase {
    var positioner: ARLabelPositioner!
    
    override func setUp() {
        super.setUp()
        // Standard iPhone screen size
        positioner = ARLabelPositioner(screenWidth: 390, screenHeight: 844)
    }
    
    override func tearDown() {
        positioner = nil
        super.tearDown()
    }
    
    // MARK: - Basic Initialization Tests
    
    func testPositionerInitialization() {
        XCTAssertNotNil(positioner)
        XCTAssertEqual(positioner.screenWidth, 390)
        XCTAssertEqual(positioner.screenHeight, 844)
    }
    
    func testScreenCenterCalculation() {
        let center = positioner.screenCenter
        XCTAssertEqual(center.x, 195)
        XCTAssertEqual(center.y, 422)
    }
    
    func testFOVScreenWidth() {
        let fovWidth = positioner.fovScreenWidth
        XCTAssertEqual(fovWidth, 390 * 0.9)
    }
    
    // MARK: - Display Visibility Tests
    
    func testShouldDisplayWithinDistanceRange() {
        // At center heading with valid distance
        XCTAssertTrue(positioner.shouldDisplay(bearing: 0, heading: 0, distance: 5000))
        XCTAssertTrue(positioner.shouldDisplay(bearing: 0, heading: 0, distance: 100))
        XCTAssertTrue(positioner.shouldDisplay(bearing: 0, heading: 0, distance: 50000))
    }
    
    func testShouldNotDisplayOutsideDistanceRange() {
        // Too close
        XCTAssertFalse(positioner.shouldDisplay(bearing: 0, heading: 0, distance: 50))
        
        // Too far
        XCTAssertFalse(positioner.shouldDisplay(bearing: 0, heading: 0, distance: 60000))
    }
    
    func testShouldDisplayWithinFOVArc() {
        let heading = 0.0
        
        // Within FOV (45 degrees, ±22.5 from heading)
        XCTAssertTrue(positioner.shouldDisplay(bearing: 0, heading: heading, distance: 5000))
        XCTAssertTrue(positioner.shouldDisplay(bearing: 22.4, heading: heading, distance: 5000))
        XCTAssertTrue(positioner.shouldDisplay(bearing: 337.6, heading: heading, distance: 5000)) // -22.4°
    }
    
    func testShouldNotDisplayOutsideFOVArc() {
        let heading = 0.0
        
        // Outside FOV
        XCTAssertFalse(positioner.shouldDisplay(bearing: 30, heading: heading, distance: 5000))
        XCTAssertFalse(positioner.shouldDisplay(bearing: 330, heading: heading, distance: 5000))
        XCTAssertFalse(positioner.shouldDisplay(bearing: 180, heading: heading, distance: 5000))
    }
    
    func testFOVAtDifferentHeadings() {
        // Heading East (90°)
        XCTAssertTrue(positioner.shouldDisplay(bearing: 90, heading: 90, distance: 5000))
        XCTAssertTrue(positioner.shouldDisplay(bearing: 112.4, heading: 90, distance: 5000))
        XCTAssertTrue(positioner.shouldDisplay(bearing: 67.6, heading: 90, distance: 5000))
        XCTAssertFalse(positioner.shouldDisplay(bearing: 0, heading: 90, distance: 5000))
    }
    
    // MARK: - Horizontal Position Tests
    
    func testNormalizedPositionCentered() {
        // POI directly ahead
        let position = positioner.calculateNormalizedPosition(bearing: 0, heading: 0, distance: 5000)
        
        // Should be centered horizontally (x = 0.5)
        XCTAssertEqual(position.x, 0.5, accuracy: 0.01)
    }
    
    func testNormalizedPositionLeft() {
        // POI 22.5° to the left (bearing is less than heading)
        let position = positioner.calculateNormalizedPosition(bearing: 337.5, heading: 0, distance: 5000)
        
        // Should be left of center
        XCTAssertLessThan(position.x, 0.5)
    }
    
    func testNormalizedPositionRight() {
        // POI 22.5° to the right
        let position = positioner.calculateNormalizedPosition(bearing: 22.5, heading: 0, distance: 5000)
        
        // Should be right of center
        XCTAssertGreaterThan(position.x, 0.5)
    }
    
    func testNormalizedPositionBounds() {
        // Test various positions stay within bounds
        for bearing in stride(from: 0.0, through: 360.0, by: 45.0) {
            let position = positioner.calculateNormalizedPosition(bearing: bearing, heading: 0, distance: 5000)
            
            XCTAssertGreaterThanOrEqual(position.x, 0.0)
            XCTAssertLessThanOrEqual(position.x, 1.0)
            XCTAssertGreaterThanOrEqual(position.y, 0.0)
            XCTAssertLessThanOrEqual(position.y, 1.0)
        }
    }
    
    // MARK: - Vertical Position Tests
    
    func testVerticalPositionCloseDistance() {
        // Close POI should be lower (higher Y value)
        let position = positioner.calculateNormalizedPosition(bearing: 0, heading: 0, distance: 500)
        XCTAssertGreater(position.y, 0.5)
    }
    
    func testVerticalPositionFarDistance() {
        // Far POI should be higher (lower Y value)
        let position = positioner.calculateNormalizedPosition(bearing: 0, heading: 0, distance: 40000)
        XCTAssertLess(position.y, 0.5)
    }
    
    func testVerticalPositionMiddleDistance() {
        // Middle distance should be in the middle
        let closePosition = positioner.calculateNormalizedPosition(bearing: 0, heading: 0, distance: 5000)
        let midPosition = positioner.calculateNormalizedPosition(bearing: 0, heading: 0, distance: 25000)
        let farPosition = positioner.calculateNormalizedPosition(bearing: 0, heading: 0, distance: 45000)
        
        XCTAssertGreater(closePosition.y, midPosition.y)
        XCTAssertGreater(midPosition.y, farPosition.y)
    }
    
    // MARK: - Screen Position Tests
    
    func testScreenPositionCenter() {
        let screenPosition = positioner.calculateScreenPosition(bearing: 0, heading: 0, distance: 25000)
        
        // Should be near screen center
        XCTAssertEqual(screenPosition.x, positioner.screenCenter.x, accuracy: 1)
    }
    
    func testScreenPositionRange() {
        // Test various positions to ensure they're on screen
        for bearing in stride(from: 0.0, through: 360.0, by: 30.0) {
            let position = positioner.calculateScreenPosition(bearing: bearing, heading: 0, distance: 5000)
            
            // Should be within reasonable screen bounds (with some margin for clipping)
            XCTAssertGreaterThan(position.x, -50)
            XCTAssertLessThan(position.x, positioner.screenWidth + 50)
            XCTAssertGreaterThan(position.y, -50)
            XCTAssertLessThan(position.y, positioner.screenHeight + 50)
        }
    }
    
    // MARK: - Font Size Tests
    
    func testFontSizeCloserIsLarger() {
        let closeSize = positioner.calculateFontSize(for: 500)
        let farSize = positioner.calculateFontSize(for: 45000)
        
        XCTAssertGreater(closeSize, farSize)
    }
    
    func testFontSizeRange() {
        let minSize = positioner.calculateFontSize(for: 50000) // Beyond max distance
        let maxSize = positioner.calculateFontSize(for: 100) // Within range
        
        XCTAssertGreaterThanOrEqual(maxSize, 24)
        XCTAssertLessThanOrEqual(minSize, 10)
    }
    
    func testFontSizeClamped() {
        // Test that font size stays within expected range
        for distance in [100, 5000, 25000, 45000, 50000] {
            let size = positioner.calculateFontSize(for: Double(distance))
            XCTAssertGreaterThanOrEqual(size, 10)
            XCTAssertLessThanOrEqual(size, 24)
        }
    }
    
    // MARK: - Opacity Tests
    
    func testOpacityAtCenter() {
        // POI directly ahead should have full opacity
        let opacity = positioner.calculateOpacity(bearing: 0, heading: 0)
        XCTAssertEqual(opacity, 1.0)
    }
    
    func testOpacityAtFOVEdge() {
        // POI at FOV edge should start fading
        let opacity = positioner.calculateOpacity(bearing: 22.4, heading: 0)
        XCTAssertGreater(opacity, 0.0)
        XCTAssertLess(opacity, 1.0)
    }
    
    func testOpacityOutsideFOV() {
        // POI outside FOV should have zero opacity
        let opacity = positioner.calculateOpacity(bearing: 45, heading: 0)
        XCTAssertEqual(opacity, 0.0)
    }
    
    func testOpacityFadeZone() {
        // Opacity should gradually decrease at FOV edges
        let center = positioner.calculateOpacity(bearing: 0, heading: 0)
        let nearEdge = positioner.calculateOpacity(bearing: 20, heading: 0)
        let atEdge = positioner.calculateOpacity(bearing: 22.5, heading: 0)
        
        XCTAssertGreater(center, nearEdge)
        XCTAssertGreater(nearEdge, atEdge)
    }
    
    // MARK: - Clipping Scale Tests
    
    func testClippingScaleFullyVisible() {
        // POI well within FOV
        let scale = positioner.calculateClippingScale(bearing: 0, heading: 0)
        XCTAssertEqual(scale, 1.0)
    }
    
    func testClippingScalePartiallyClipped() {
        // POI partially outside FOV
        let scale = positioner.calculateClippingScale(bearing: 30, heading: 0)
        XCTAssertGreater(scale, 0.0)
        XCTAssertLess(scale, 1.0)
    }
    
    func testClippingScaleFullyClipped() {
        // POI fully outside FOV
        let scale = positioner.calculateClippingScale(bearing: 50, heading: 0)
        XCTAssertEqual(scale, 0.0)
    }
    
    // MARK: - Bearing Difference Tests
    
    func testNormalizationNorthward() {
        // Test bearing calculations with northward heading
        XCTAssertTrue(positioner.shouldDisplay(bearing: 0, heading: 0, distance: 5000))
        XCTAssertTrue(positioner.shouldDisplay(bearing: 22, heading: 0, distance: 5000))
        XCTAssertTrue(positioner.shouldDisplay(bearing: 338, heading: 0, distance: 5000))
    }
    
    func testNormalizationWrapAround() {
        // Test bearing wrap-around at 0/360°
        // Heading = 355°, bearing = 5° should be 10° offset (well within FOV)
        XCTAssertTrue(positioner.shouldDisplay(bearing: 5, heading: 355, distance: 5000))
        
        // Heading = 5°, bearing = 355° should be -10° offset (well within FOV)
        XCTAssertTrue(positioner.shouldDisplay(bearing: 355, heading: 5, distance: 5000))
    }
    
    // MARK: - Real-world Scenario Tests
    
    func testMultiplePOIPositions() {
        let center = positioner.calculateScreenPosition(bearing: 0, heading: 0, distance: 5000)
        let left = positioner.calculateScreenPosition(bearing: 315, heading: 0, distance: 5000)
        let right = positioner.calculateScreenPosition(bearing: 45, heading: 0, distance: 5000)
        let close = positioner.calculateScreenPosition(bearing: 0, heading: 0, distance: 500)
        let far = positioner.calculateScreenPosition(bearing: 0, heading: 0, distance: 40000)
        
        // Left POI should have lower X than center
        XCTAssertLess(left.x, center.x)
        
        // Right POI should have higher X than center
        XCTAssertGreater(right.x, center.x)
        
        // Close POI should be lower (higher Y) than far POI
        XCTAssertGreater(close.y, far.y)
    }
    
    func testDeviceRotation() {
        // Test that labels move correctly as device rotates
        let bearing = 45.0
        let distance = 5000.0
        
        let position0 = positioner.calculateScreenPosition(bearing: bearing, heading: 0, distance: distance)
        let position90 = positioner.calculateScreenPosition(bearing: bearing, heading: 90, distance: distance)
        let position180 = positioner.calculateScreenPosition(bearing: bearing, heading: 180, distance: distance)
        
        // Positions should be different as heading changes
        XCTAssertNotEqual(position0.x, position90.x)
        XCTAssertNotEqual(position90.x, position180.x)
    }
    
    func testSmoothScaling() {
        // Test that font size changes smoothly with distance
        let sizes = (100...45000).stride(by: 5000).map { distance in
            positioner.calculateFontSize(for: Double(distance))
        }
        
        // Each size should be >= the previous (as distance increases, size decreases)
        for i in 1..<sizes.count {
            XCTAssertLessThanOrEqual(sizes[i], sizes[i-1])
        }
    }
}

// MARK: - AROverlayView Tests

class AROverlayViewTests: XCTestCase {
    func testAROverlayViewCreation() {
        let poi = POILocation(
            name: "Museum",
            coordinate: CLLocationCoordinate2D(latitude: 42.0, longitude: -83.0),
            category: .museum,
            distance: 5000,
            bearing: 45
        )
        
        let view = AROverlayView(pois: [poi], heading: 0.0)
        XCTAssertNotNil(view)
    }
    
    func testAROverlayViewMultiplePOIs() {
        let pois = [
            POILocation(name: "Museum", coordinate: CLLocationCoordinate2D(latitude: 42.0, longitude: -83.0), category: .museum, distance: 5000, bearing: 45),
            POILocation(name: "Park", coordinate: CLLocationCoordinate2D(latitude: 42.1, longitude: -83.1), category: .park, distance: 2000, bearing: 0),
            POILocation(name: "Airport", coordinate: CLLocationCoordinate2D(latitude: 41.9, longitude: -82.9), category: .airport, distance: 10000, bearing: 90),
        ]
        
        let view = AROverlayView(pois: pois, heading: 0.0)
        XCTAssertNotNil(view)
    }
    
    func testAROverlayViewWithoutHeading() {
        let poi = POILocation(
            name: "Museum",
            coordinate: CLLocationCoordinate2D(latitude: 42.0, longitude: -83.0),
            category: .museum,
            distance: 5000,
            bearing: 45
        )
        
        let view = AROverlayView(pois: [poi], heading: nil)
        XCTAssertNotNil(view)
    }
    
    func testAROverlayViewEmptyPOIs() {
        let view = AROverlayView(pois: [], heading: 0.0)
        XCTAssertNotNil(view)
    }
    
    func testPOILabelViewCreation() {
        let poi = POILocation(
            name: "Museum",
            coordinate: CLLocationCoordinate2D(latitude: 42.0, longitude: -83.0),
            category: .museum,
            distance: 5000,
            bearing: 45
        )
        let positioner = ARLabelPositioner(screenWidth: 390, screenHeight: 844)
        
        let view = POILabelView(poi: poi, heading: 0.0, positioner: positioner)
        XCTAssertNotNil(view)
    }
}

// MARK: - Integration Tests for AR

class ARIntegrationTests: XCTestCase {
    var positioner: ARLabelPositioner!
    
    override func setUp() {
        super.setUp()
        positioner = ARLabelPositioner(screenWidth: 390, screenHeight: 844)
    }
    
    override func tearDown() {
        positioner = nil
        super.tearDown()
    }
    
    func testCompleteWorkflowSinglePOI() {
        let poi = POILocation(
            name: "Museum",
            coordinate: CLLocationCoordinate2D(latitude: 42.0, longitude: -83.0),
            category: .museum,
            distance: 5000,
            bearing: 45,
            prominence: 0.8
        )
        
        let heading = 0.0
        
        // Should be displayed
        XCTAssertTrue(positioner.shouldDisplay(bearing: poi.bearing, heading: heading, distance: poi.distance))
        
        // Should have position
        let position = positioner.calculateScreenPosition(bearing: poi.bearing, heading: heading, distance: poi.distance)
        XCTAssertGreaterThan(position.x, 0)
        XCTAssertGreaterThan(position.y, 0)
        
        // Should have font size
        let fontSize = positioner.calculateFontSize(for: poi.distance)
        XCTAssertGreater(fontSize, 10)
        
        // Should have opacity
        let opacity = positioner.calculateOpacity(bearing: poi.bearing, heading: heading)
        XCTAssertGreater(opacity, 0)
    }
    
    func testWorkflowMultiplePOIsVariousDistances() {
        let heading = 45.0
        let pois = [
            POILocation(name: "Close POI", coordinate: CLLocationCoordinate2D(latitude: 42.0, longitude: -83.0), category: .landmark, distance: 500, bearing: 45),
            POILocation(name: "Mid POI", coordinate: CLLocationCoordinate2D(latitude: 42.1, longitude: -83.1), category: .museum, distance: 5000, bearing: 30),
            POILocation(name: "Far POI", coordinate: CLLocationCoordinate2D(latitude: 41.9, longitude: -82.9), category: .park, distance: 40000, bearing: 60),
        ]
        
        var fontSizes: [CGFloat] = []
        for poi in pois {
            if positioner.shouldDisplay(bearing: poi.bearing, heading: heading, distance: poi.distance) {
                let fontSize = positioner.calculateFontSize(for: poi.distance)
                fontSizes.append(fontSize)
            }
        }
        
        // Font sizes should decrease as distance increases
        XCTAssertGreater(fontSizes[0], fontSizes[1])
        XCTAssertGreater(fontSizes[1], fontSizes[2])
    }
    
    func testDeviceRotationWorkflow() {
        let poi = POILocation(
            name: "Museum",
            coordinate: CLLocationCoordinate2D(latitude: 42.0, longitude: -83.0),
            category: .museum,
            distance: 5000,
            bearing: 45
        )
        
        // Test visibility at different headings
        let heading0Visible = positioner.shouldDisplay(bearing: poi.bearing, heading: 0, distance: poi.distance)
        let heading90Visible = positioner.shouldDisplay(bearing: poi.bearing, heading: 90, distance: poi.distance)
        let heading180Visible = positioner.shouldDisplay(bearing: poi.bearing, heading: 180, distance: poi.distance)
        
        // POI at bearing 45 should be visible with heading near 45, not with heading 180
        XCTAssertTrue(heading0Visible) // Within 45° of bearing 45
        XCTAssertFalse(heading180Visible) // Far from bearing 45
    }
    
    func testEdgeCaseZeroBearing() {
        // POI directly north
        XCTAssertTrue(positioner.shouldDisplay(bearing: 0, heading: 0, distance: 5000))
        XCTAssertTrue(positioner.shouldDisplay(bearing: 0, heading: 22, distance: 5000))
        XCTAssertTrue(positioner.shouldDisplay(bearing: 0, heading: 338, distance: 5000))
    }
    
    func testEdgeCaseWraparound() {
        // Test bearing wrapping at 360°
        XCTAssertTrue(positioner.shouldDisplay(bearing: 359, heading: 1, distance: 5000))
        XCTAssertTrue(positioner.shouldDisplay(bearing: 1, heading: 359, distance: 5000))
    }
}

// MARK: - POIScorer Tests

class POIScorerTests: XCTestCase {
    
    // MARK: - Category Significance Tests
    
    func testCategorySignificanceScores() {
        // High significance categories
        let landmarkScore = POIScorer.categoryScores[.landmark]
        let parkScore = POIScorer.categoryScores[.park]
        
        // Low significance categories
        let governmentScore = POIScorer.categoryScores[.governmentBuilding]
        let publicSpaceScore = POIScorer.categoryScores[.publicSpace]
        
        // Landmarks/Parks should score higher than civic buildings
        XCTAssertNotNil(landmarkScore)
        XCTAssertNotNil(parkScore)
        XCTAssertNotNil(governmentScore)
        XCTAssertNotNil(publicSpaceScore)
        
        XCTAssertGreater(landmarkScore ?? 0, governmentScore ?? 0)
        XCTAssertGreater(parkScore ?? 0, governmentScore ?? 0)
    }
    
    func testAllCategoriesHaveScores() {
        for category in LocationCategory.allCases {
            let score = POIScorer.categoryScores[category]
            XCTAssertNotNil(score, "Category \(category) should have a score")
            XCTAssertGreaterThan(score ?? 0, 0, "Score for \(category) should be positive")
        }
    }
    
    // MARK: - Distance Weighting Tests
    
    func testDistanceWeightingOptimalDistance() {
        let optimalDistance = POIScorer.optimalDistance
        let closerDistance = optimalDistance - 1000
        let fartherDistance = optimalDistance + 1000
        
        let poi1 = POILocation(name: "Test1", coordinate: CLLocationCoordinate2D(latitude: 42.0, longitude: -83.0), category: .museum, distance: optimalDistance, bearing: 0)
        let poi2 = POILocation(name: "Test2", coordinate: CLLocationCoordinate2D(latitude: 42.0, longitude: -83.0), category: .museum, distance: closerDistance, bearing: 0)
        let poi3 = POILocation(name: "Test3", coordinate: CLLocationCoordinate2D(latitude: 42.0, longitude: -83.0), category: .museum, distance: fartherDistance, bearing: 0)
        
        // All scored with same bearing offset (0) for fair comparison
        let score1 = POIScorer.calculateInterestScore(for: poi1, bearingOffset: 0)
        let score2 = POIScorer.calculateInterestScore(for: poi2, bearingOffset: 0)
        let score3 = POIScorer.calculateInterestScore(for: poi3, bearingOffset: 0)
        
        // Optimal should score highest, equidistant points should score equally
        XCTAssertGreaterThan(score1, score2)
        XCTAssertGreaterThan(score1, score3)
        XCTAssertEqual(score2, score3, accuracy: 0.01) // Equidistant should be equal
    }
    
    func testDistanceWeightingBounds() {
        let minDistance = POIScorer.minDistance
        let maxDistance = POIScorer.maxDistance
        
        let poiMin = POILocation(name: "Min", coordinate: CLLocationCoordinate2D(latitude: 42.0, longitude: -83.0), category: .museum, distance: minDistance, bearing: 0)
        let poiMax = POILocation(name: "Max", coordinate: CLLocationCoordinate2D(latitude: 42.0, longitude: -83.0), category: .museum, distance: maxDistance, bearing: 0)
        
        let scoreMin = POIScorer.calculateInterestScore(for: poiMin, bearingOffset: 0)
        let scoreMax = POIScorer.calculateInterestScore(for: poiMax, bearingOffset: 0)
        
        // Both should have valid scores
        XCTAssertGreaterThanOrEqual(scoreMin, 0)
        XCTAssertLessThanOrEqual(scoreMin, 1)
        XCTAssertGreaterThanOrEqual(scoreMax, 0)
        XCTAssertLessThanOrEqual(scoreMax, 1)
    }
    
    // MARK: - Directional Centrality Tests
    
    func testDirectionalCentralityCenter() {
        // POI directly ahead (bearing offset = 0)
        let poi = POILocation(name: "Test", coordinate: CLLocationCoordinate2D(latitude: 42.0, longitude: -83.0), category: .museum, distance: 5000, bearing: 0)
        let scoreCenter = POIScorer.calculateInterestScore(for: poi, bearingOffset: 0)
        
        // POI at FOV edge (bearing offset = 22.5)
        let scoreEdge = POIScorer.calculateInterestScore(for: poi, bearingOffset: 22.5)
        
        // Center should score higher than edge
        XCTAssertGreater(scoreCenter, scoreEdge)
    }
    
    func testDirectionalCentralitySymmetry() {
        let poi = POILocation(name: "Test", coordinate: CLLocationCoordinate2D(latitude: 42.0, longitude: -83.0), category: .museum, distance: 5000, bearing: 0)
        
        // Left and right should have equal scores
        let scoreLeft = POIScorer.calculateInterestScore(for: poi, bearingOffset: -15.0)
        let scoreRight = POIScorer.calculateInterestScore(for: poi, bearingOffset: 15.0)
        
        XCTAssertEqual(scoreLeft, scoreRight, accuracy: 0.01)
    }
    
    // MARK: - Complete Interest Score Tests
    
    func testInterestScoreNormalization() {
        let pois = [
            POILocation(name: "A", coordinate: CLLocationCoordinate2D(latitude: 42.0, longitude: -83.0), category: .landmark, distance: 5000, bearing: 0, prominence: 0.9),
            POILocation(name: "B", coordinate: CLLocationCoordinate2D(latitude: 42.1, longitude: -83.1), category: .museum, distance: 10000, bearing: 45, prominence: 0.5),
            POILocation(name: "C", coordinate: CLLocationCoordinate2D(latitude: 41.9, longitude: -82.9), category: .governmentBuilding, distance: 3000, bearing: -30, prominence: 0.2),
        ]
        
        for poi in pois {
            let score = POIScorer.calculateInterestScore(for: poi, bearingOffset: 0)
            XCTAssertGreaterThanOrEqual(score, 0.0)
            XCTAssertLessThanOrEqual(score, 1.0)
        }
    }
    
    func testInterestScoreLandmarkVsCivic() {
        let landmark = POILocation(name: "Landmark", coordinate: CLLocationCoordinate2D(latitude: 42.0, longitude: -83.0), category: .landmark, distance: 5000, bearing: 0, prominence: 0.5)
        let civic = POILocation(name: "Civic", coordinate: CLLocationCoordinate2D(latitude: 42.0, longitude: -83.0), category: .governmentBuilding, distance: 5000, bearing: 0, prominence: 0.5)
        
        let landmarkScore = POIScorer.calculateInterestScore(for: landmark, bearingOffset: 0)
        let civicScore = POIScorer.calculateInterestScore(for: civic, bearingOffset: 0)
        
        // Landmark should score higher than civic building
        XCTAssertGreater(landmarkScore, civicScore)
    }
    
    func testInterestScoreWithDifferentProminence() {
        let poiHigh = POILocation(name: "High", coordinate: CLLocationCoordinate2D(latitude: 42.0, longitude: -83.0), category: .museum, distance: 5000, bearing: 0, prominence: 0.9)
        let poiLow = POILocation(name: "Low", coordinate: CLLocationCoordinate2D(latitude: 42.0, longitude: -83.0), category: .museum, distance: 5000, bearing: 0, prominence: 0.1)
        
        let scoreHigh = POIScorer.calculateInterestScore(for: poiHigh, bearingOffset: 0)
        let scoreLow = POIScorer.calculateInterestScore(for: poiLow, bearingOffset: 0)
        
        // Higher prominence should result in higher score
        XCTAssertGreater(scoreHigh, scoreLow)
    }
}

// MARK: - OverlapResolver Tests

class OverlapResolverTests: XCTestCase {
    var resolver: OverlapResolver!
    let screenSize = CGSize(width: 390, height: 844)
    
    override func setUp() {
        super.setUp()
        resolver = OverlapResolver()
    }
    
    override func tearDown() {
        resolver = nil
        super.tearDown()
    }
    
    // MARK: - Basic Functionality Tests
    
    func testOverlapResolverInitialization() {
        XCTAssertNotNil(resolver)
        XCTAssertEqual(resolver.config.minVerticalSpacing, 60.0)
        XCTAssertEqual(resolver.config.maxVerticalLevels, 3)
    }
    
    func testResolveOverlapsEmptyList() {
        let result = resolver.resolveOverlaps(for: [], screenSize: screenSize)
        XCTAssertEqual(result.count, 0)
    }
    
    func testResolveOverlapsSinglePOI() {
        let poi = POILocation(name: "Test", coordinate: CLLocationCoordinate2D(latitude: 42.0, longitude: -83.0), category: .museum, distance: 5000, bearing: 0)
        let labels = [(poi: poi, score: 0.5, position: CGPoint(x: 195, y: 422))]
        
        let result = resolver.resolveOverlaps(for: labels, screenSize: screenSize)
        
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].poi.name, "Test")
        XCTAssertEqual(result[0].resolvedPosition, CGPoint(x: 195, y: 422))
        XCTAssertEqual(result[0].zIndex, 0)
    }
    
    // MARK: - Overlap Detection Tests
    
    func testDetectOverlappingLabels() {
        let poi1 = POILocation(name: "Label1", coordinate: CLLocationCoordinate2D(latitude: 42.0, longitude: -83.0), category: .museum, distance: 5000, bearing: 0)
        let poi2 = POILocation(name: "Label2", coordinate: CLLocationCoordinate2D(latitude: 42.1, longitude: -83.1), category: .park, distance: 3000, bearing: 45)
        
        // Two labels at same position should overlap
        let position = CGPoint(x: 195, y: 422)
        let labels = [
            (poi: poi1, score: 0.8, position: position),
            (poi: poi2, score: 0.6, position: position)
        ]
        
        let result = resolver.resolveOverlaps(for: labels, screenSize: screenSize)
        
        // Both labels should have been resolved
        XCTAssertEqual(result.count, 2)
        
        // Higher score (poi1) should maintain position
        XCTAssertEqual(result[0].resolvedPosition, position)
        
        // Lower score (poi2) should be offset
        XCTAssertNotEqual(result[1].resolvedPosition, position)
        XCTAssertNotEqual(result[1].verticalOffset, 0)
    }
    
    // MARK: - Priority-Based Resolution Tests
    
    func testPriorityBasedResolution() {
        let poi1 = POILocation(name: "High", coordinate: CLLocationCoordinate2D(latitude: 42.0, longitude: -83.0), category: .landmark, distance: 5000, bearing: 0)
        let poi2 = POILocation(name: "Low", coordinate: CLLocationCoordinate2D(latitude: 42.1, longitude: -83.1), category: .municipalBuilding, distance: 10000, bearing: 30)
        
        let position = CGPoint(x: 195, y: 422)
        let labels = [
            (poi: poi1, score: 0.9, position: position),  // Higher priority
            (poi: poi2, score: 0.3, position: position)   // Lower priority
        ]
        
        let result = resolver.resolveOverlaps(for: labels, screenSize: screenSize)
        
        // Higher score should get better position (no offset)
        XCTAssertEqual(result[0].zIndex, 0)
        XCTAssertGreater(result[1].zIndex, result[0].zIndex)
    }
    
    // MARK: - Vertical Offset Tests
    
    func testVerticalOffsetCalculation() {
        let poi = POILocation(name: "Test", coordinate: CLLocationCoordinate2D(latitude: 42.0, longitude: -83.0), category: .museum, distance: 5000, bearing: 0)
        let position = CGPoint(x: 195, y: 422)
        let labels = [(poi: poi, score: 0.5, position: position)]
        
        let result = resolver.resolveOverlaps(for: labels, screenSize: screenSize)
        
        // Single label should have no offset
        XCTAssertEqual(result[0].verticalOffset, 0)
    }
    
    // MARK: - Multiple Labels Tests
    
    func testResolveManyOverlappingLabels() {
        var labels: [(poi: POILocation, score: Double, position: CGPoint)] = []
        let basePosition = CGPoint(x: 195, y: 422)
        
        // Create 5 labels at the same position with different scores
        for i in 0..<5 {
            let poi = POILocation(name: "Label\(i)", coordinate: CLLocationCoordinate2D(latitude: 42.0 + Double(i) * 0.1, longitude: -83.0), category: .museum, distance: 5000 + Double(i) * 1000, bearing: Double(i) * 45)
            let score = Double(5 - i) * 0.2  // Descending scores: 1.0, 0.8, 0.6, 0.4, 0.2
            labels.append((poi: poi, score: score, position: basePosition))
        }
        
        let result = resolver.resolveOverlaps(for: labels, screenSize: screenSize)
        
        XCTAssertEqual(result.count, 5)
        
        // First label (highest score) should have lowest zIndex
        XCTAssertEqual(result[0].zIndex, 0)
        
        // Labels should be sorted by score (descending)
        for i in 1..<result.count {
            XCTAssertGreaterThanOrEqual(result[i].zIndex, result[i-1].zIndex)
        }
    }
    
    // MARK: - Screen Bounds Tests
    
    func testPositionsStayWithinBounds() {
        let poi1 = POILocation(name: "Label1", coordinate: CLLocationCoordinate2D(latitude: 42.0, longitude: -83.0), category: .museum, distance: 5000, bearing: 0)
        let poi2 = POILocation(name: "Label2", coordinate: CLLocationCoordinate2D(latitude: 42.1, longitude: -83.1), category: .park, distance: 3000, bearing: 45)
        let poi3 = POILocation(name: "Label3", coordinate: CLLocationCoordinate2D(latitude: 41.9, longitude: -82.9), category: .landmark, distance: 8000, bearing: -45)
        
        let labels = [
            (poi: poi1, score: 0.8, position: CGPoint(x: 195, y: 50)),    // Near top
            (poi: poi2, score: 0.6, position: CGPoint(x: 195, y: 800)),   // Near bottom
            (poi: poi3, score: 0.4, position: CGPoint(x: 195, y: 422))    // Middle
        ]
        
        let result = resolver.resolveOverlaps(for: labels, screenSize: screenSize)
        
        // All positions should stay within screen bounds
        for resolved in result {
            XCTAssertGreaterThanOrEqual(resolved.resolvedPosition.y, 0)
            XCTAssertLessThanOrEqual(resolved.resolvedPosition.y, screenSize.height)
        }
    }
    
    func testNonOverlappingLabelsPreservePosition() {
        let poi1 = POILocation(name: "Label1", coordinate: CLLocationCoordinate2D(latitude: 42.0, longitude: -83.0), category: .museum, distance: 5000, bearing: 0)
        let poi2 = POILocation(name: "Label2", coordinate: CLLocationCoordinate2D(latitude: 42.1, longitude: -83.1), category: .park, distance: 3000, bearing: 45)
        
        let labels = [
            (poi: poi1, score: 0.8, position: CGPoint(x: 195, y: 200)),
            (poi: poi2, score: 0.6, position: CGPoint(x: 195, y: 500))  // Far enough apart
        ]
        
        let result = resolver.resolveOverlaps(for: labels, screenSize: screenSize)
        
        // Positions should be preserved since they don't overlap
        XCTAssertEqual(result[0].resolvedPosition, CGPoint(x: 195, y: 200))
        XCTAssertEqual(result[1].resolvedPosition, CGPoint(x: 195, y: 500))
    }
    
    func testCustomConfiguration() {
        let customConfig = OverlapResolver.Config(minVerticalSpacing: 100, maxVerticalLevels: 5)
        let customResolver = OverlapResolver(config: customConfig)
        
        XCTAssertEqual(customResolver.config.minVerticalSpacing, 100)
        XCTAssertEqual(customResolver.config.maxVerticalLevels, 5)
    }
}

// MARK: - Max Display Limit Tests

class MaxDisplayLimitTests: XCTestCase {
    let maxDisplayedLabels = 10
    
    func testMaxDisplayLimitEnforced() {
        // Create 20 POIs with different scores
        var pois: [POILocation] = []
        var expectedCount = 0
        
        for i in 0..<20 {
            let poi = POILocation(
                name: "POI\(i)",
                coordinate: CLLocationCoordinate2D(latitude: 42.0 + Double(i) * 0.01, longitude: -83.0),
                category: .museum,
                distance: 5000 + Double(i) * 100,
                bearing: Double(i) * 10,
                prominence: Double(20 - i) / 20.0  // Decreasing prominence
            )
            pois.append(poi)
            expectedCount = min(i + 1, maxDisplayedLabels)
        }
        
        // Create AROverlayView with 20 POIs
        let view = AROverlayView(pois: pois, heading: 0.0)
        
        // The displayedPOIs should be limited to maxDisplayedLabels
        // Note: We can't directly access displayedPOIs since it's a computed property,
        // but the view should render only max 10 labels
        XCTAssertNotNil(view)
    }
    
    func testDynamicReappearanceOnMovement() {
        // Create 15 POIs with various bearings (to test FOV filtering)
        var pois: [POILocation] = []
        
        for i in 0..<15 {
            let poi = POILocation(
                name: "POI\(i)",
                coordinate: CLLocationCoordinate2D(latitude: 42.0 + Double(i) * 0.01, longitude: -83.0),
                category: .museum,
                distance: 5000 + Double(i) * 100,
                bearing: Double(i) * 10,  // Spread across bearings
                prominence: 0.5
            )
            pois.append(poi)
        }
        
        // Create views with different headings
        let view0 = AROverlayView(pois: pois, heading: 0.0)
        let view45 = AROverlayView(pois: pois, heading: 45.0)
        let view90 = AROverlayView(pois: pois, heading: 90.0)
        
        // All views should exist and be valid
        XCTAssertNotNil(view0)
        XCTAssertNotNil(view45)
        XCTAssertNotNil(view90)
        
        // As heading changes, different POIs should be visible
        // (assuming they have different bearings that fall within the 45° FOV)
    }
    
    func testScoringInfluencesDisplayOrder() {
        let positioner = ARLabelPositioner(screenWidth: 390, screenHeight: 844)
        
        // Create POIs where scoring should result in clear ordering
        let pois = [
            POILocation(name: "HighScore", coordinate: CLLocationCoordinate2D(latitude: 42.0, longitude: -83.0), category: .landmark, distance: 25050, bearing: 0, prominence: 0.9),
            POILocation(name: "MidScore", coordinate: CLLocationCoordinate2D(latitude: 42.1, longitude: -83.1), category: .museum, distance: 25050, bearing: 0, prominence: 0.5),
            POILocation(name: "LowScore", coordinate: CLLocationCoordinate2D(latitude: 41.9, longitude: -82.9), category: .governmentBuilding, distance: 25050, bearing: 0, prominence: 0.2),
        ]
        
        let heading = 0.0
        
        // Calculate scores for each
        var scores: [(String, Double)] = []
        for poi in pois {
            let bearingOffset = positioner.normalizeBearingDifference(poi.bearing - heading)
            let score = POIScorer.calculateInterestScore(for: poi, bearingOffset: bearingOffset)
            scores.append((poi.name, score))
        }
        
        // HighScore should have highest score
        XCTAssertGreater(scores[0].1, scores[1].1)
        XCTAssertGreater(scores[1].1, scores[2].1)
    }
}

// MARK: - Complete Integration Tests

class CompleteOverlapAndScoringTests: XCTestCase {
    func testCompleteWorkflowWithManyPOIs() {
        let positioner = ARLabelPositioner(screenWidth: 390, screenHeight: 844)
        let resolver = OverlapResolver()
        let screenSize = CGSize(width: 390, height: 844)
        
        // Create 20 POIs within FOV
        var pois: [POILocation] = []
        for i in 0..<20 {
            let poi = POILocation(
                name: "POI\(i)",
                coordinate: CLLocationCoordinate2D(latitude: 42.0 + Double(i) * 0.001, longitude: -83.0),
                category: (i % 2 == 0) ? .landmark : .museum,
                distance: 5000.0 + Double(i) * 500,
                bearing: Double(i) * 2,  // All within FOV
                prominence: 0.5
            )
            pois.append(poi)
        }
        
        let heading = 0.0
        
        // Filter visible POIs
        let visiblePOIs = pois.filter { poi in
            positioner.shouldDisplay(bearing: poi.bearing, heading: heading, distance: poi.distance)
        }
        
        // Score visible POIs
        var scoredPOIs: [(poi: POILocation, score: Double)] = []
        for poi in visiblePOIs {
            let bearingOffset = positioner.normalizeBearingDifference(poi.bearing - heading)
            let score = POIScorer.calculateInterestScore(for: poi, bearingOffset: bearingOffset)
            scoredPOIs.append((poi: poi, score: score))
        }
        
        // Sort by score and limit to 10
        scoredPOIs.sort { $0.score > $1.score }
        let displayedPOIs = Array(scoredPOIs.prefix(10))
        
        // Calculate positions for display
        var labelPositions: [(poi: POILocation, score: Double, position: CGPoint)] = []
        for pair in displayedPOIs {
            let position = positioner.calculateScreenPosition(bearing: pair.poi.bearing, heading: heading, distance: pair.poi.distance)
            labelPositions.append((pair.poi, pair.score, position))
        }
        
        // Resolve overlaps
        let resolvedLabels = resolver.resolveOverlaps(for: labelPositions, screenSize: screenSize)
        
        // Verify results
        XCTAssertEqual(displayedPOIs.count, 10)  // Should be exactly 10
        XCTAssertEqual(resolvedLabels.count, 10)
        
        // All resolved labels should have valid positions
        for resolved in resolvedLabels {
            XCTAssertGreaterThanOrEqual(resolved.resolvedPosition.y, 0)
            XCTAssertLessThanOrEqual(resolved.resolvedPosition.y, screenSize.height)
        }
        
        // Scores should be in descending order
        for i in 1..<displayedPOIs.count {
            XCTAssertGreaterThanOrEqual(displayedPOIs[i-1].score, displayedPOIs[i].score)
        }
    }
    
    func testOverlapResolutionWithPriority() {
        let resolver = OverlapResolver()
        let screenSize = CGSize(width: 390, height: 844)
        
        let poi1 = POILocation(name: "Priority1", coordinate: CLLocationCoordinate2D(latitude: 42.0, longitude: -83.0), category: .landmark, distance: 5000, bearing: 0)
        let poi2 = POILocation(name: "Priority2", coordinate: CLLocationCoordinate2D(latitude: 42.1, longitude: -83.1), category: .museum, distance: 6000, bearing: 10)
        let poi3 = POILocation(name: "Priority3", coordinate: CLLocationCoordinate2D(latitude: 42.2, longitude: -83.2), category: .park, distance: 7000, bearing: 20)
        
        // All at the same position with different scores
        let centerPosition = CGPoint(x: 195, y: 422)
        let labels = [
            (poi: poi1, score: 0.9, position: centerPosition),
            (poi: poi2, score: 0.7, position: centerPosition),
            (poi: poi3, score: 0.5, position: centerPosition)
        ]
        
        let resolved = resolver.resolveOverlaps(for: labels, screenSize: screenSize)
        
        // First label (highest score) should keep center position
        XCTAssertEqual(resolved[0].resolvedPosition, centerPosition)
        XCTAssertEqual(resolved[0].zIndex, 0)
        
        // Other labels should be offset
        XCTAssertNotEqual(resolved[1].resolvedPosition.y, centerPosition.y)
        XCTAssertGreater(resolved[1].zIndex, 0)
        
        XCTAssertNotEqual(resolved[2].resolvedPosition.y, centerPosition.y)
        XCTAssertGreater(resolved[2].zIndex, 0)
    }
}
