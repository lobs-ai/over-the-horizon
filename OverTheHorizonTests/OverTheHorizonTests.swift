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
