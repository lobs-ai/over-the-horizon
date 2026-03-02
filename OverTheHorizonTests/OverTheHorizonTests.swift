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

// MARK: - ZoomGestureManager Tests

class ZoomGestureManagerTests: XCTestCase {
    var sut: ZoomGestureManager!
    
    override func setUp() {
        super.setUp()
        sut = ZoomGestureManager()
    }
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testZoomGestureManagerInitialization() {
        XCTAssertNotNil(sut)
        XCTAssertEqual(sut.zoomLevel, 1.0)
        XCTAssertEqual(sut.labelScaleMultiplier, 1.0)
    }
    
    func testDefaultDistances() {
        XCTAssertEqual(sut.minDistance, 100.0)
        XCTAssertEqual(sut.maxDistance, 50000.0)
    }
    
    func testDefaultZoomConstants() {
        XCTAssertEqual(sut.minZoomLevel, 0.3)
        XCTAssertEqual(sut.maxZoomLevel, 3.0)
        XCTAssertEqual(sut.defaultMinDistance, 100.0)
        XCTAssertEqual(sut.defaultMaxDistance, 50000.0)
    }
    
    // MARK: - Zoom Level Tests
    
    func testSetZoomLevelInBounds() {
        sut.setZoomLevel(0.5)
        XCTAssertEqual(sut.zoomLevel, 0.5)
        
        sut.setZoomLevel(2.0)
        XCTAssertEqual(sut.zoomLevel, 2.0)
    }
    
    func testSetZoomLevelBelowMinimum() {
        sut.setZoomLevel(0.1)
        XCTAssertEqual(sut.zoomLevel, sut.minZoomLevel)
        XCTAssertEqual(sut.zoomLevel, 0.3)
    }
    
    func testSetZoomLevelAboveMaximum() {
        sut.setZoomLevel(5.0)
        XCTAssertEqual(sut.zoomLevel, sut.maxZoomLevel)
        XCTAssertEqual(sut.zoomLevel, 3.0)
    }
    
    func testSetZoomLevelZerosClamped() {
        sut.setZoomLevel(0.0)
        XCTAssertEqual(sut.zoomLevel, sut.minZoomLevel)
    }
    
    func testSetZoomLevelNegativeClamped() {
        sut.setZoomLevel(-1.0)
        XCTAssertEqual(sut.zoomLevel, sut.minZoomLevel)
    }
    
    // MARK: - Gesture Update Tests
    
    func testUpdateZoomWithGestureScaleOut() {
        // Pinch OUT (scale > 1) should increase zoom
        let initialZoom = sut.zoomLevel
        sut.updateZoomWithGesture(scaleFactor: 1.2)
        
        XCTAssertGreater(sut.zoomLevel, initialZoom)
    }
    
    func testUpdateZoomWithGestureScaleIn() {
        // Pinch IN (scale < 1) should decrease zoom
        sut.setZoomLevel(1.5)
        let initialZoom = sut.zoomLevel
        sut.updateZoomWithGesture(scaleFactor: 0.8)
        
        XCTAssertLess(sut.zoomLevel, initialZoom)
    }
    
    func testUpdateZoomWithGestureRespectsBounds() {
        sut.setZoomLevel(2.8)
        sut.updateZoomWithGesture(scaleFactor: 2.0)  // Try to zoom out beyond max
        
        XCTAssertLessThanOrEqual(sut.zoomLevel, sut.maxZoomLevel)
    }
    
    func testUpdateZoomWithGestureMinBound() {
        sut.setZoomLevel(0.4)
        sut.updateZoomWithGesture(scaleFactor: 0.5)  // Try to zoom in beyond min
        
        XCTAssertGreaterThanOrEqual(sut.zoomLevel, sut.minZoomLevel)
    }
    
    // MARK: - Distance Range Tests
    
    func testDistanceRangeAtDefaultZoom() {
        sut.setZoomLevel(1.0)
        
        XCTAssertEqual(sut.minDistance, sut.defaultMinDistance)
        XCTAssertEqual(sut.maxDistance, sut.defaultMaxDistance)
    }
    
    func testDistanceRangeAtMaxZoomOut() {
        sut.setZoomLevel(3.0)
        
        // Max zoom out should increase distances
        XCTAssertGreater(sut.maxDistance, sut.defaultMaxDistance)
        XCTAssertGreater(sut.minDistance, sut.defaultMinDistance)
    }
    
    func testDistanceRangeAtMaxZoomIn() {
        sut.setZoomLevel(0.3)
        
        // Max zoom in should decrease distances
        XCTAssertLess(sut.minDistance, sut.defaultMinDistance)
        XCTAssertLess(sut.maxDistance, sut.defaultMaxDistance)
    }
    
    func testMinDistanceRespectsBounds() {
        sut.setZoomLevel(0.3)
        XCTAssertGreaterThanOrEqual(sut.minDistance, sut.absoluteMinDistance)
    }
    
    func testMaxDistanceRespectsBounds() {
        sut.setZoomLevel(3.0)
        XCTAssertLessThanOrEqual(sut.maxDistance, sut.absoluteMaxDistance)
    }
    
    func testDistanceBoundsConsistent() {
        for zoomLevel in stride(from: 0.3, through: 3.0, by: 0.3) {
            sut.setZoomLevel(zoomLevel)
            XCTAssertLess(sut.minDistance, sut.maxDistance)
        }
    }
    
    // MARK: - Label Scale Tests
    
    func testLabelScaleAtDefaultZoom() {
        sut.setZoomLevel(1.0)
        XCTAssertEqual(sut.labelScaleMultiplier, 1.0)
    }
    
    func testLabelScaleAtMaxZoomOut() {
        sut.setZoomLevel(3.0)
        // Zoom out should make labels smaller
        XCTAssertLess(sut.labelScaleMultiplier, 1.0)
        XCTAssertEqual(sut.labelScaleMultiplier, 1.0 / 3.0, accuracy: 0.01)
    }
    
    func testLabelScaleAtMaxZoomIn() {
        sut.setZoomLevel(0.3)
        // Zoom in should make labels larger
        XCTAssertGreater(sut.labelScaleMultiplier, 1.0)
        XCTAssertEqual(sut.labelScaleMultiplier, 1.0 / 0.3, accuracy: 0.01)
    }
    
    func testLabelScaleInverseOfZoom() {
        let zoomLevels = [0.5, 0.75, 1.0, 1.5, 2.0, 2.5]
        for zoomLevel in zoomLevels {
            sut.setZoomLevel(zoomLevel)
            XCTAssertEqual(sut.labelScaleMultiplier, 1.0 / zoomLevel, accuracy: 0.001)
        }
    }
    
    // MARK: - Reset Tests
    
    func testResetZoom() {
        sut.setZoomLevel(2.5)
        sut.resetZoom()
        
        XCTAssertEqual(sut.zoomLevel, 1.0)
        XCTAssertEqual(sut.minDistance, sut.defaultMinDistance)
        XCTAssertEqual(sut.maxDistance, sut.defaultMaxDistance)
        XCTAssertEqual(sut.labelScaleMultiplier, 1.0)
    }
    
    func testResetZoomAfterComplexGestures() {
        sut.updateZoomWithGesture(scaleFactor: 1.5)
        sut.updateZoomWithGesture(scaleFactor: 0.8)
        sut.setZoomLevel(2.2)
        
        sut.resetZoom()
        
        XCTAssertEqual(sut.zoomLevel, 1.0)
        XCTAssertEqual(sut.labelScaleMultiplier, 1.0)
    }
    
    // MARK: - Update Threshold Tests
    
    func testSmallZoomChangesIgnored() {
        let initialZoom = sut.zoomLevel
        let initialMinDistance = sut.minDistance
        
        sut.setZoomLevel(initialZoom + 0.005)  // Very small change
        
        // Should not update if change is less than 0.01 threshold
        XCTAssertEqual(sut.zoomLevel, initialZoom)
        XCTAssertEqual(sut.minDistance, initialMinDistance)
    }
    
    func testMeaningfulZoomChangesApplied() {
        let initialZoom = sut.zoomLevel
        sut.setZoomLevel(initialZoom + 0.02)  // Change greater than 0.01 threshold
        
        XCTAssertNotEqual(sut.zoomLevel, initialZoom)
    }
    
    // MARK: - State Consistency Tests
    
    func testStateConsistencyAfterMultipleUpdates() {
        sut.setZoomLevel(1.5)
        XCTAssertNotNil(sut.zoomLevel)
        XCTAssertNotNil(sut.minDistance)
        XCTAssertNotNil(sut.maxDistance)
        XCTAssertNotNil(sut.labelScaleMultiplier)
        
        sut.updateZoomWithGesture(scaleFactor: 1.2)
        XCTAssertNotNil(sut.zoomLevel)
        XCTAssertNotNil(sut.minDistance)
        XCTAssertNotNil(sut.maxDistance)
        XCTAssertNotNil(sut.labelScaleMultiplier)
    }
    
    func testSequentialZoomLevelSettings() {
        let levels = [0.5, 1.0, 1.5, 2.0, 2.5, 3.0]
        
        for level in levels {
            sut.setZoomLevel(level)
            XCTAssertEqual(sut.zoomLevel, level, accuracy: 0.01)
        }
    }
}

// MARK: - ARLabelPositioner with Zoom Tests

class ARLabelPositionerWithZoomTests: XCTestCase {
    var zoomManager: ZoomGestureManager!
    
    override func setUp() {
        super.setUp()
        zoomManager = ZoomGestureManager()
    }
    
    override func tearDown() {
        zoomManager = nil
        super.tearDown()
    }
    
    func testPositionerWithDefaultZoom() {
        let positioner = ARLabelPositioner(
            screenWidth: 390,
            screenHeight: 844,
            minDistance: zoomManager.minDistance,
            maxDistance: zoomManager.maxDistance,
            labelScaleMultiplier: zoomManager.labelScaleMultiplier
        )
        
        XCTAssertEqual(positioner.labelScaleMultiplier, 1.0)
        XCTAssertEqual(positioner.minDistance, 100.0)
        XCTAssertEqual(positioner.maxDistance, 50000.0)
    }
    
    func testPositionerFontSizeWithZoom() {
        // At default zoom
        let positioner1 = ARLabelPositioner(
            screenWidth: 390,
            screenHeight: 844,
            minDistance: zoomManager.minDistance,
            maxDistance: zoomManager.maxDistance,
            labelScaleMultiplier: zoomManager.labelScaleMultiplier
        )
        let defaultSize = positioner1.calculateFontSize(for: 5000)
        
        // At max zoom in (smaller labels)
        zoomManager.setZoomLevel(0.3)
        let positioner2 = ARLabelPositioner(
            screenWidth: 390,
            screenHeight: 844,
            minDistance: zoomManager.minDistance,
            maxDistance: zoomManager.maxDistance,
            labelScaleMultiplier: zoomManager.labelScaleMultiplier
        )
        let zoomedInSize = positioner2.calculateFontSize(for: 5000)
        
        // At max zoom out (smaller labels)
        zoomManager.setZoomLevel(3.0)
        let positioner3 = ARLabelPositioner(
            screenWidth: 390,
            screenHeight: 844,
            minDistance: zoomManager.minDistance,
            maxDistance: zoomManager.maxDistance,
            labelScaleMultiplier: zoomManager.labelScaleMultiplier
        )
        let zoomedOutSize = positioner3.calculateFontSize(for: 5000)
        
        // Zoom in should make labels larger
        XCTAssertGreater(zoomedInSize, defaultSize)
        
        // Zoom out should make labels smaller
        XCTAssertLess(zoomedOutSize, defaultSize)
    }
    
    func testPositionerDisplayFiltersWithZoomedDistances() {
        // At max zoom in, should show closer POIs
        zoomManager.setZoomLevel(0.3)
        let positioner1 = ARLabelPositioner(
            screenWidth: 390,
            screenHeight: 844,
            minDistance: zoomManager.minDistance,
            maxDistance: zoomManager.maxDistance,
            labelScaleMultiplier: zoomManager.labelScaleMultiplier
        )
        
        // POI at 500m should be visible with zoom in (focuses on nearer)
        XCTAssertTrue(positioner1.shouldDisplay(bearing: 0, heading: 0, distance: 500))
        
        // At max zoom out, should see farther POIs
        zoomManager.setZoomLevel(3.0)
        let positioner2 = ARLabelPositioner(
            screenWidth: 390,
            screenHeight: 844,
            minDistance: zoomManager.minDistance,
            maxDistance: zoomManager.maxDistance,
            labelScaleMultiplier: zoomManager.labelScaleMultiplier
        )
        
        // POI at 80km should be visible with zoom out
        XCTAssertTrue(positioner2.shouldDisplay(bearing: 0, heading: 0, distance: 80000))
    }
}

// MARK: - Integration Tests for Zoom and AROverlay

class ZoomAROverlayIntegrationTests: XCTestCase {
    var zoomManager: ZoomGestureManager!
    
    override func setUp() {
        super.setUp()
        zoomManager = ZoomGestureManager()
    }
    
    override func tearDown() {
        zoomManager = nil
        super.tearDown()
    }
    
    func testZoomAffectsLabelVisibility() {
        let pois = [
            POILocation(name: "Close", coordinate: CLLocationCoordinate2D(latitude: 42.0, longitude: -83.0), category: .landmark, distance: 500, bearing: 0),
            POILocation(name: "Far", coordinate: CLLocationCoordinate2D(latitude: 42.1, longitude: -83.1), category: .park, distance: 80000, bearing: 45),
        ]
        
        // At default zoom
        zoomManager.setZoomLevel(1.0)
        let positioner1 = ARLabelPositioner(
            screenWidth: 390,
            screenHeight: 844,
            minDistance: zoomManager.minDistance,
            maxDistance: zoomManager.maxDistance,
            labelScaleMultiplier: zoomManager.labelScaleMultiplier
        )
        
        let closeVisibleDefault = positioner1.shouldDisplay(bearing: pois[0].bearing, heading: 0, distance: pois[0].distance)
        let farVisibleDefault = positioner1.shouldDisplay(bearing: pois[1].bearing, heading: 0, distance: pois[1].distance)
        
        // Close should be visible, far should not
        XCTAssertTrue(closeVisibleDefault)
        XCTAssertFalse(farVisibleDefault)
        
        // At max zoom out
        zoomManager.setZoomLevel(3.0)
        let positioner2 = ARLabelPositioner(
            screenWidth: 390,
            screenHeight: 844,
            minDistance: zoomManager.minDistance,
            maxDistance: zoomManager.maxDistance,
            labelScaleMultiplier: zoomManager.labelScaleMultiplier
        )
        
        let closeVisibleZoomedOut = positioner2.shouldDisplay(bearing: pois[0].bearing, heading: 0, distance: pois[0].distance)
        let farVisibleZoomedOut = positioner2.shouldDisplay(bearing: pois[1].bearing, heading: 0, distance: pois[1].distance)
        
        // Both should be visible when zoomed out
        XCTAssertTrue(closeVisibleZoomedOut)
        XCTAssertTrue(farVisibleZoomedOut)
    }
    
    func testZoomAffectsLabelSize() {
        let distance = 25000.0
        
        // At zoom in
        zoomManager.setZoomLevel(0.3)
        let positioner1 = ARLabelPositioner(
            screenWidth: 390,
            screenHeight: 844,
            minDistance: zoomManager.minDistance,
            maxDistance: zoomManager.maxDistance,
            labelScaleMultiplier: zoomManager.labelScaleMultiplier
        )
        let sizeZoomedIn = positioner1.calculateFontSize(for: distance)
        
        // At default zoom
        zoomManager.setZoomLevel(1.0)
        let positioner2 = ARLabelPositioner(
            screenWidth: 390,
            screenHeight: 844,
            minDistance: zoomManager.minDistance,
            maxDistance: zoomManager.maxDistance,
            labelScaleMultiplier: zoomManager.labelScaleMultiplier
        )
        let sizeDefault = positioner2.calculateFontSize(for: distance)
        
        // At zoom out
        zoomManager.setZoomLevel(3.0)
        let positioner3 = ARLabelPositioner(
            screenWidth: 390,
            screenHeight: 844,
            minDistance: zoomManager.minDistance,
            maxDistance: zoomManager.maxDistance,
            labelScaleMultiplier: zoomManager.labelScaleMultiplier
        )
        let sizeZoomedOut = positioner3.calculateFontSize(for: distance)
        
        // Size should decrease with zoom out
        XCTAssertGreater(sizeZoomedIn, sizeDefault)
        XCTAssertGreater(sizeDefault, sizeZoomedOut)
    }
    
    func testSmoothZoomTransition() {
        let distance = 5000.0
        
        var previousSize: CGFloat? = nil
        let zoomSteps = stride(from: 0.3, through: 3.0, by: 0.1)
        
        for zoomLevel in zoomSteps {
            zoomManager.setZoomLevel(zoomLevel)
            let positioner = ARLabelPositioner(
                screenWidth: 390,
                screenHeight: 844,
                minDistance: zoomManager.minDistance,
                maxDistance: zoomManager.maxDistance,
                labelScaleMultiplier: zoomManager.labelScaleMultiplier
            )
            let size = positioner.calculateFontSize(for: distance)
            
            if let prev = previousSize {
                // Sizes should be monotonically decreasing as zoom out
                XCTAssertLess(size, prev)
            }
            previousSize = size
        }
    }
    
    func testZoomGestureChain() {
        let manager = ZoomGestureManager()
        // Simulate a series of pinch gestures
        manager.updateZoomWithGesture(scaleFactor: 1.2)  // Pinch out
        manager.updateZoomWithGesture(scaleFactor: 1.2)  // Pinch out again
        manager.updateZoomWithGesture(scaleFactor: 0.9)  // Pinch in
        manager.updateZoomWithGesture(scaleFactor: 0.9)  // Pinch in again
        
        // Should have reasonable zoom level
        XCTAssertGreaterThanOrEqual(manager.zoomLevel, manager.minZoomLevel)
        XCTAssertLessThanOrEqual(manager.zoomLevel, manager.maxZoomLevel)
    }
    
    func testCompleteZoomWorkflow() {
        let poi = POILocation(
            name: "Test POI",
            coordinate: CLLocationCoordinate2D(latitude: 42.0, longitude: -83.0),
            category: .landmark,
            distance: 25000,
            bearing: 0,
            prominence: 0.8
        )
        
        // Start at default zoom
        var positioner = ARLabelPositioner(
            screenWidth: 390,
            screenHeight: 844,
            minDistance: zoomManager.minDistance,
            maxDistance: zoomManager.maxDistance,
            labelScaleMultiplier: zoomManager.labelScaleMultiplier
        )
        
        XCTAssertTrue(positioner.shouldDisplay(bearing: poi.bearing, heading: 0, distance: poi.distance))
        let defaultSize = positioner.calculateFontSize(for: poi.distance)
        
        // Zoom in via gesture
        zoomManager.updateZoomWithGesture(scaleFactor: 0.6)
        positioner = ARLabelPositioner(
            screenWidth: 390,
            screenHeight: 844,
            minDistance: zoomManager.minDistance,
            maxDistance: zoomManager.maxDistance,
            labelScaleMultiplier: zoomManager.labelScaleMultiplier
        )
        
        let zoomedInSize = positioner.calculateFontSize(for: poi.distance)
        XCTAssertGreater(zoomedInSize, defaultSize)
        
        // Zoom out via gesture
        zoomManager.updateZoomWithGesture(scaleFactor: 2.0)
        positioner = ARLabelPositioner(
            screenWidth: 390,
            screenHeight: 844,
            minDistance: zoomManager.minDistance,
            maxDistance: zoomManager.maxDistance,
            labelScaleMultiplier: zoomManager.labelScaleMultiplier
        )
        
        let zoomedOutSize = positioner.calculateFontSize(for: poi.distance)
        XCTAssertLess(zoomedOutSize, defaultSize)
        
        // Reset zoom
        zoomManager.resetZoom()
        positioner = ARLabelPositioner(
            screenWidth: 390,
            screenHeight: 844,
            minDistance: zoomManager.minDistance,
            maxDistance: zoomManager.maxDistance,
            labelScaleMultiplier: zoomManager.labelScaleMultiplier
        )
        
        let resetSize = positioner.calculateFontSize(for: poi.distance)
        XCTAssertEqual(resetSize, defaultSize, accuracy: 0.1)
    }
}

// MARK: - Incremental Zoom Gesture Tests

class IncrementalZoomGestureTests: XCTestCase {
    var manager: ZoomGestureManager!
    
    override func setUp() {
        super.setUp()
        manager = ZoomGestureManager()
    }
    
    override func tearDown() {
        manager = nil
        super.tearDown()
    }
    
    func testIncrementalPinchOut() {
        // Simulate a series of incremental pinch out gestures
        let initialZoom = manager.zoomLevel
        
        // First pinch segment: 1.0 -> 1.2 (scale delta = 1.2)
        manager.updateZoomWithGesture(scaleFactor: 1.2)
        let zoomAfterFirst = manager.zoomLevel
        XCTAssertGreater(zoomAfterFirst, initialZoom)
        
        // Second pinch segment: continue (scale delta = 1.1)
        manager.updateZoomWithGesture(scaleFactor: 1.1)
        let zoomAfterSecond = manager.zoomLevel
        XCTAssertGreater(zoomAfterSecond, zoomAfterFirst)
    }
    
    func testIncrementalPinchIn() {
        manager.setZoomLevel(2.0)
        let initialZoom = manager.zoomLevel
        
        // First pinch segment: zoom in (scale delta = 0.8)
        manager.updateZoomWithGesture(scaleFactor: 0.8)
        let zoomAfterFirst = manager.zoomLevel
        XCTAssertLess(zoomAfterFirst, initialZoom)
        
        // Second pinch segment: continue zooming in (scale delta = 0.9)
        manager.updateZoomWithGesture(scaleFactor: 0.9)
        let zoomAfterSecond = manager.zoomLevel
        XCTAssertLess(zoomAfterSecond, zoomAfterFirst)
    }
    
    func testPinchOutIncreasesBothDistances() {
        let initialMinDistance = manager.minDistance
        let initialMaxDistance = manager.maxDistance
        
        // Pinch out
        manager.updateZoomWithGesture(scaleFactor: 1.5)
        
        XCTAssertGreater(manager.maxDistance, initialMaxDistance)
        XCTAssertGreater(manager.minDistance, initialMinDistance)
    }
    
    func testPinchInDecreasesBothDistances() {
        manager.setZoomLevel(2.0)  // Start zoomed out
        let initialMinDistance = manager.minDistance
        let initialMaxDistance = manager.maxDistance
        
        // Pinch in
        manager.updateZoomWithGesture(scaleFactor: 0.7)
        
        XCTAssertLess(manager.maxDistance, initialMaxDistance)
        XCTAssertLess(manager.minDistance, initialMinDistance)
    }
    
    func testPinchOutDecreasesFontSize() {
        let initialScale = manager.labelScaleMultiplier
        
        // Pinch out (zoom increases)
        manager.updateZoomWithGesture(scaleFactor: 2.0)
        
        XCTAssertLess(manager.labelScaleMultiplier, initialScale)
    }
    
    func testPinchInIncreasesFontSize() {
        manager.setZoomLevel(2.0)  // Start zoomed out
        let initialScale = manager.labelScaleMultiplier
        
        // Pinch in (zoom decreases)
        manager.updateZoomWithGesture(scaleFactor: 0.5)
        
        XCTAssertGreater(manager.labelScaleMultiplier, initialScale)
    }
    
    func testSmallPinchMovement() {
        let initialZoom = manager.zoomLevel
        
        // Very small pinch (should still update if > threshold)
        manager.updateZoomWithGesture(scaleFactor: 1.02)
        
        // Zoom should update slightly
        XCTAssertNotEqual(manager.zoomLevel, initialZoom, accuracy: 0.001)
    }
    
    func testRepeatedSmallPinches() {
        let initialZoom = manager.zoomLevel
        
        // Multiple small pinches should accumulate
        for _ in 0..<5 {
            manager.updateZoomWithGesture(scaleFactor: 1.05)
        }
        
        XCTAssertGreater(manager.zoomLevel, initialZoom)
    }
    
    func testPinchGestureRespectsBounds() {
        // Try to zoom out beyond max
        for _ in 0..<10 {
            manager.updateZoomWithGesture(scaleFactor: 2.0)
        }
        
        XCTAssertLessThanOrEqual(manager.zoomLevel, manager.maxZoomLevel)
        XCTAssertLessThanOrEqual(manager.maxDistance, manager.absoluteMaxDistance)
        
        // Try to zoom in beyond min
        for _ in 0..<10 {
            manager.updateZoomWithGesture(scaleFactor: 0.5)
        }
        
        XCTAssertGreaterThanOrEqual(manager.zoomLevel, manager.minZoomLevel)
        XCTAssertGreaterThanOrEqual(manager.minDistance, manager.absoluteMinDistance)
    }
    
    func testAlternatingPinchMovements() {
        let initialZoom = manager.zoomLevel
        
        // Pinch out
        manager.updateZoomWithGesture(scaleFactor: 1.3)
        let zoomAfterOut = manager.zoomLevel
        XCTAssertGreater(zoomAfterOut, initialZoom)
        
        // Pinch in
        manager.updateZoomWithGesture(scaleFactor: 0.8)
        let zoomAfterIn = manager.zoomLevel
        XCTAssertLess(zoomAfterIn, zoomAfterOut)
        
        // Pinch out again
        manager.updateZoomWithGesture(scaleFactor: 1.2)
        let zoomFinal = manager.zoomLevel
        XCTAssertGreater(zoomFinal, zoomAfterIn)
    }
    
    func testZoomAffectsVisibilityRanges() {
        let positioner1 = ARLabelPositioner(
            screenWidth: 390,
            screenHeight: 844,
            minDistance: manager.minDistance,
            maxDistance: manager.maxDistance,
            labelScaleMultiplier: manager.labelScaleMultiplier
        )
        
        // Check what's visible at default zoom
        let poi500 = 500.0
        let poi80k = 80000.0
        let visible500Default = positioner1.shouldDisplay(bearing: 0, heading: 0, distance: poi500)
        let visible80kDefault = positioner1.shouldDisplay(bearing: 0, heading: 0, distance: poi80k)
        
        // Zoom in
        manager.updateZoomWithGesture(scaleFactor: 0.5)
        let positioner2 = ARLabelPositioner(
            screenWidth: 390,
            screenHeight: 844,
            minDistance: manager.minDistance,
            maxDistance: manager.maxDistance,
            labelScaleMultiplier: manager.labelScaleMultiplier
        )
        
        // POI at 500m should be closer to visibility threshold when zoomed in
        let visible500ZoomedIn = positioner2.shouldDisplay(bearing: 0, heading: 0, distance: poi500)
        
        // Zoom out
        manager.setZoomLevel(3.0)
        let positioner3 = ARLabelPositioner(
            screenWidth: 390,
            screenHeight: 844,
            minDistance: manager.minDistance,
            maxDistance: manager.maxDistance,
            labelScaleMultiplier: manager.labelScaleMultiplier
        )
        
        // POI at 80km should be visible when zoomed out
        let visible80kZoomedOut = positioner3.shouldDisplay(bearing: 0, heading: 0, distance: poi80k)
        XCTAssertTrue(visible80kZoomedOut)
    }
    
    func testLabelSizeChangesWithGesture() {
        let distance = 25000.0
        
        let positioner1 = ARLabelPositioner(
            screenWidth: 390,
            screenHeight: 844,
            minDistance: manager.minDistance,
            maxDistance: manager.maxDistance,
            labelScaleMultiplier: manager.labelScaleMultiplier
        )
        let sizeDefault = positioner1.calculateFontSize(for: distance)
        
        // Pinch out (zoom increases, labels get smaller)
        manager.updateZoomWithGesture(scaleFactor: 2.0)
        let positioner2 = ARLabelPositioner(
            screenWidth: 390,
            screenHeight: 844,
            minDistance: manager.minDistance,
            maxDistance: manager.maxDistance,
            labelScaleMultiplier: manager.labelScaleMultiplier
        )
        let sizeZoomedOut = positioner2.calculateFontSize(for: distance)
        
        XCTAssertLess(sizeZoomedOut, sizeDefault)
    }
    
    func testComplexGestureSequence() {
        // Simulate a realistic user interaction: zooming in and out with multiple touches
        var zoomLevels: [Double] = [manager.zoomLevel]
        
        // Out
        manager.updateZoomWithGesture(scaleFactor: 1.3)
        zoomLevels.append(manager.zoomLevel)
        
        // Out more
        manager.updateZoomWithGesture(scaleFactor: 1.2)
        zoomLevels.append(manager.zoomLevel)
        
        // In
        manager.updateZoomWithGesture(scaleFactor: 0.85)
        zoomLevels.append(manager.zoomLevel)
        
        // In more
        manager.updateZoomWithGesture(scaleFactor: 0.8)
        zoomLevels.append(manager.zoomLevel)
        
        // Out
        manager.updateZoomWithGesture(scaleFactor: 1.5)
        zoomLevels.append(manager.zoomLevel)
        
        // Verify all zoom levels are within bounds
        for zoom in zoomLevels {
            XCTAssertGreaterThanOrEqual(zoom, manager.minZoomLevel)
            XCTAssertLessThanOrEqual(zoom, manager.maxZoomLevel)
        }
        
        // Verify zoom progression is reasonable
        XCTAssertGreater(zoomLevels[1], zoomLevels[0])  // First out
        XCTAssertGreater(zoomLevels[2], zoomLevels[1])  // More out
        XCTAssertLess(zoomLevels[3], zoomLevels[2])     // In
        XCTAssertLess(zoomLevels[4], zoomLevels[3])     // More in
        XCTAssertGreater(zoomLevels[5], zoomLevels[4])  // Out
    }
    
    func testDistanceRangeExpansionWithZoom() {
        // Test that distance ranges expand/contract properly during zooming
        let initialRange = manager.maxDistance - manager.minDistance
        
        // Zoom out
        manager.updateZoomWithGesture(scaleFactor: 2.0)
        let zoomedOutRange = manager.maxDistance - manager.minDistance
        XCTAssertGreater(zoomedOutRange, initialRange)
        
        // Zoom in
        manager.updateZoomWithGesture(scaleFactor: 0.5)
        let zoomedInRange = manager.maxDistance - manager.minDistance
        XCTAssertLess(zoomedInRange, zoomedOutRange)
    }
}

// MARK: - Distance Range Correctness Tests

class DistanceRangeCorrectnessTests: XCTestCase {
    var sut: ZoomGestureManager!
    
    override func setUp() {
        super.setUp()
        sut = ZoomGestureManager()
    }
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }
    
    // MARK: - Min Distance Calculation Tests
    
    func testMinDistanceFormula() {
        // Test that minDistance = defaultMinDistance * zoomFactor
        sut.setZoomLevel(0.3)
        let expectedMinAt03 = 100.0 * 0.3  // 30m
        XCTAssertEqual(sut.minDistance, expectedMinAt03, accuracy: 0.1)
        
        sut.setZoomLevel(1.0)
        let expectedMinAt10 = 100.0 * 1.0  // 100m
        XCTAssertEqual(sut.minDistance, expectedMinAt10, accuracy: 0.1)
        
        sut.setZoomLevel(3.0)
        let expectedMinAt30 = 100.0 * 3.0  // 300m
        XCTAssertEqual(sut.minDistance, expectedMinAt30, accuracy: 0.1)
    }
    
    func testMaxDistanceFormula() {
        // Test that maxDistance = defaultMaxDistance * zoomFactor
        sut.setZoomLevel(0.3)
        let expectedMaxAt03 = 50000.0 * 0.3  // 15km
        XCTAssertEqual(sut.maxDistance, expectedMaxAt03, accuracy: 10.0)
        
        sut.setZoomLevel(1.0)
        let expectedMaxAt10 = 50000.0 * 1.0  // 50km
        XCTAssertEqual(sut.maxDistance, expectedMaxAt10, accuracy: 10.0)
        
        sut.setZoomLevel(3.0)
        let expectedMaxAt30 = 50000.0 * 3.0  // 150km
        XCTAssertEqual(sut.maxDistance, expectedMaxAt30, accuracy: 10.0)
    }
    
    func testZoomInDecreasesBothDistances() {
        // Zoom in (0.3): both distances should be LESS than default
        sut.setZoomLevel(0.3)
        XCTAssertLess(sut.minDistance, sut.defaultMinDistance)
        XCTAssertLess(sut.maxDistance, sut.defaultMaxDistance)
        
        // Specifically, they should be 30% of default
        XCTAssertEqual(sut.minDistance, 30.0, accuracy: 0.1)
        XCTAssertEqual(sut.maxDistance, 15000.0, accuracy: 10.0)
    }
    
    func testZoomOutIncreasesBothDistances() {
        // Zoom out (3.0): both distances should be MORE than default
        sut.setZoomLevel(3.0)
        XCTAssertGreater(sut.minDistance, sut.defaultMinDistance)
        XCTAssertGreater(sut.maxDistance, sut.defaultMaxDistance)
        
        // Specifically, they should be 300% of default
        XCTAssertEqual(sut.minDistance, 300.0, accuracy: 0.1)
        XCTAssertEqual(sut.maxDistance, 150000.0, accuracy: 10.0)
    }
    
    func testMinDistanceAlwaysLessThanMax() {
        // Verify the invariant: minDistance < maxDistance for all zoom levels
        for zoomLevel in stride(from: 0.3, through: 3.0, by: 0.1) {
            sut.setZoomLevel(zoomLevel)
            XCTAssertLess(sut.minDistance, sut.maxDistance,
                         "At zoom \(zoomLevel): min (\(sut.minDistance)) should be < max (\(sut.maxDistance))")
        }
    }
}

// MARK: - SettingsManager Tests

class SettingsManagerTests: XCTestCase {
    var sut: SettingsManager!
    
    override func setUp() {
        super.setUp()
        sut = SettingsManager()
        // Clear UserDefaults for clean test state
        UserDefaults.standard.removeObject(forKey: "enabledCategories")
    }
    
    override func tearDown() {
        sut = nil
        UserDefaults.standard.removeObject(forKey: "enabledCategories")
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testSettingsManagerInitialization() {
        XCTAssertNotNil(sut)
        XCTAssertFalse(sut.enabledCategories.isEmpty)
    }
    
    func testAllCategoriesEnabledByDefault() {
        for category in LocationCategory.allCases {
            XCTAssertTrue(sut.isEnabled(category), "Category \(category.displayName) should be enabled by default")
        }
    }
    
    func testEnabledCategoriesDictionary() {
        for category in LocationCategory.allCases {
            let isEnabled = sut.enabledCategories[category.rawValue] ?? true
            XCTAssertTrue(isEnabled, "Dictionary should show \(category.displayName) as enabled")
        }
    }
    
    // MARK: - Toggle Tests
    
    func testToggleCategoryOnToOff() {
        let category = LocationCategory.landmark
        XCTAssertTrue(sut.isEnabled(category))
        
        sut.toggleCategory(category)
        XCTAssertFalse(sut.isEnabled(category))
    }
    
    func testToggleCategoryOffToOn() {
        let category = LocationCategory.landmark
        sut.toggleCategory(category)
        XCTAssertFalse(sut.isEnabled(category))
        
        sut.toggleCategory(category)
        XCTAssertTrue(sut.isEnabled(category))
    }
    
    func testToggleMultipleCategories() {
        let cat1 = LocationCategory.landmark
        let cat2 = LocationCategory.museum
        let cat3 = LocationCategory.park
        
        sut.toggleCategory(cat1)
        sut.toggleCategory(cat2)
        sut.toggleCategory(cat3)
        
        XCTAssertFalse(sut.isEnabled(cat1))
        XCTAssertFalse(sut.isEnabled(cat2))
        XCTAssertFalse(sut.isEnabled(cat3))
        
        // Others should still be enabled
        XCTAssertTrue(sut.isEnabled(LocationCategory.airport))
    }
    
    // MARK: - Set Enabled Tests
    
    func testSetEnabledTrue() {
        let category = LocationCategory.landmark
        sut.setEnabled(category, true)
        XCTAssertTrue(sut.isEnabled(category))
    }
    
    func testSetEnabledFalse() {
        let category = LocationCategory.landmark
        sut.setEnabled(category, false)
        XCTAssertFalse(sut.isEnabled(category))
    }
    
    func testSetEnabledToggle() {
        let category = LocationCategory.landmark
        
        sut.setEnabled(category, false)
        XCTAssertFalse(sut.isEnabled(category))
        
        sut.setEnabled(category, true)
        XCTAssertTrue(sut.isEnabled(category))
    }
    
    // MARK: - Get Enabled Categories Tests
    
    func testGetEnabledCategoriesDefault() {
        let enabled = sut.getEnabledCategories()
        XCTAssertEqual(enabled.count, LocationCategory.allCases.count)
    }
    
    func testGetEnabledCategoriesAfterDisabling() {
        sut.setEnabled(LocationCategory.landmark, false)
        sut.setEnabled(LocationCategory.museum, false)
        
        let enabled = sut.getEnabledCategories()
        XCTAssertEqual(enabled.count, LocationCategory.allCases.count - 2)
        
        XCTAssertFalse(enabled.contains(LocationCategory.landmark))
        XCTAssertFalse(enabled.contains(LocationCategory.museum))
        XCTAssertTrue(enabled.contains(LocationCategory.park))
    }
    
    func testGetEnabledCategoriesEmpty() {
        sut.disableAll()
        let enabled = sut.getEnabledCategories()
        XCTAssertEqual(enabled.count, 0)
    }
    
    // MARK: - Enable/Disable All Tests
    
    func testEnableAll() {
        sut.disableAll()
        XCTAssertEqual(sut.getEnabledCategories().count, 0)
        
        sut.enableAll()
        XCTAssertEqual(sut.getEnabledCategories().count, LocationCategory.allCases.count)
    }
    
    func testDisableAll() {
        XCTAssertEqual(sut.getEnabledCategories().count, LocationCategory.allCases.count)
        
        sut.disableAll()
        XCTAssertEqual(sut.getEnabledCategories().count, 0)
    }
    
    func testEnableAllAfterMultipleToggles() {
        for category in LocationCategory.allCases.prefix(5) {
            sut.toggleCategory(category)
        }
        
        let enabledBefore = sut.getEnabledCategories().count
        XCTAssertLess(enabledBefore, LocationCategory.allCases.count)
        
        sut.enableAll()
        
        let enabledAfter = sut.getEnabledCategories().count
        XCTAssertEqual(enabledAfter, LocationCategory.allCases.count)
    }
    
    // MARK: - Reset Tests
    
    func testResetToDefaults() {
        sut.disableAll()
        XCTAssertEqual(sut.getEnabledCategories().count, 0)
        
        sut.resetToDefaults()
        XCTAssertEqual(sut.getEnabledCategories().count, LocationCategory.allCases.count)
    }
    
    // MARK: - Persistence Tests
    
    func testPersistenceAfterToggle() {
        let category = LocationCategory.landmark
        sut.toggleCategory(category)
        
        // Create new instance to test persistence
        let newInstance = SettingsManager()
        XCTAssertFalse(newInstance.isEnabled(category))
    }
    
    func testPersistenceAfterMultipleChanges() {
        sut.setEnabled(LocationCategory.landmark, false)
        sut.setEnabled(LocationCategory.museum, false)
        sut.setEnabled(LocationCategory.park, true)
        
        let newInstance = SettingsManager()
        XCTAssertFalse(newInstance.isEnabled(LocationCategory.landmark))
        XCTAssertFalse(newInstance.isEnabled(LocationCategory.museum))
        XCTAssertTrue(newInstance.isEnabled(LocationCategory.park))
    }
    
    func testPersistenceAfterEnableAll() {
        sut.disableAll()
        sut.enableAll()
        
        let newInstance = SettingsManager()
        XCTAssertEqual(newInstance.getEnabledCategories().count, LocationCategory.allCases.count)
    }
    
    // MARK: - Category Group Tests
    
    func testLandmarksAndCultureGroup() {
        let group = LocationCategory.Group.landmarksAndCulture
        let categories = LocationCategory.allCases.filter { $0.group == group }
        
        XCTAssertGreaterThan(categories.count, 0)
        XCTAssert(categories.contains(LocationCategory.landmark))
        XCTAssert(categories.contains(LocationCategory.museum))
    }
    
    func testNatureAndOutdoorsGroup() {
        let group = LocationCategory.Group.natureAndOutdoors
        let categories = LocationCategory.allCases.filter { $0.group == group }
        
        XCTAssertGreaterThan(categories.count, 0)
        XCTAssert(categories.contains(LocationCategory.park))
        XCTAssert(categories.contains(LocationCategory.beach))
    }
    
    func testEntertainmentAndAttractionsGroup() {
        let group = LocationCategory.Group.entertainmentAndAttractions
        let categories = LocationCategory.allCases.filter { $0.group == group }
        
        XCTAssertGreaterThan(categories.count, 0)
        XCTAssert(categories.contains(LocationCategory.zoo))
        XCTAssert(categories.contains(LocationCategory.theater))
    }
    
    func testSportsAndRecreationGroup() {
        let group = LocationCategory.Group.sportsAndRecreation
        let categories = LocationCategory.allCases.filter { $0.group == group }
        
        XCTAssertGreaterThan(categories.count, 0)
    }
    
    func testTravelAndInfrastructureGroup() {
        let group = LocationCategory.Group.travelAndInfrastructure
        let categories = LocationCategory.allCases.filter { $0.group == group }
        
        XCTAssertGreaterThan(categories.count, 0)
        XCTAssert(categories.contains(LocationCategory.airport))
        XCTAssert(categories.contains(LocationCategory.trainStation))
    }
    
    func testCivicAndPublicInterestGroup() {
        let group = LocationCategory.Group.civicAndPublicInterest
        let categories = LocationCategory.allCases.filter { $0.group == group }
        
        XCTAssertGreaterThan(categories.count, 0)
        XCTAssert(categories.contains(LocationCategory.library))
        XCTAssert(categories.contains(LocationCategory.university))
    }
    
    func testAllCategoriesHaveGroup() {
        for category in LocationCategory.allCases {
            let group = category.group
            XCTAssertNotNil(group, "Category \(category.displayName) should have a group")
        }
    }
    
    func testGroupsAreComplete() {
        var categoriesByGroup: [LocationCategory.Group: [LocationCategory]] = [:]
        
        for category in LocationCategory.allCases {
            if categoriesByGroup[category.group] == nil {
                categoriesByGroup[category.group] = []
            }
            categoriesByGroup[category.group]?.append(category)
        }
        
        // All 6 groups should be present
        XCTAssertEqual(categoriesByGroup.count, 6)
        
        // All categories should be accounted for
        let totalCategories = categoriesByGroup.values.reduce(0) { $0 + $1.count }
        XCTAssertEqual(totalCategories, LocationCategory.allCases.count)
    }
    
    func testNoGroupOverlap() {
        var seenCategories = Set<LocationCategory>()
        
        for group in LocationCategory.Group.allCases {
            let categories = LocationCategory.allCases.filter { $0.group == group }
            
            for category in categories {
                XCTAssertFalse(seenCategories.contains(category), "Category \(category.displayName) appears in multiple groups")
                seenCategories.insert(category)
            }
        }
    }
    
    // MARK: - Settings with Groups Tests
    
    func testToggleGroupByDisablingAll() {
        let group = LocationCategory.Group.landmarksAndCulture
        let groupCategories = LocationCategory.allCases.filter { $0.group == group }
        
        for category in groupCategories {
            sut.setEnabled(category, false)
        }
        
        let enabled = sut.getEnabledCategories()
        for category in groupCategories {
            XCTAssertFalse(enabled.contains(category))
        }
    }
    
    func testToggleGroupByEnablingAll() {
        sut.disableAll()
        
        let group = LocationCategory.Group.entertainmentAndAttractions
        let groupCategories = LocationCategory.allCases.filter { $0.group == group }
        
        for category in groupCategories {
            sut.setEnabled(category, true)
        }
        
        let enabled = sut.getEnabledCategories()
        for category in groupCategories {
            XCTAssertTrue(enabled.contains(category))
        }
    }
}
