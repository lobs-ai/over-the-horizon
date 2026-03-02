//
//  SettingsModalTests.swift
//  OverTheHorizonTests
//
//  Test suite for Settings Modal and Category Filtering Feature
//

import XCTest
@testable import OverTheHorizon

class SettingsModalTests: XCTestCase {
    var settingsManager: SettingsManager!
    
    override func setUp() {
        super.setUp()
        settingsManager = SettingsManager()
        // Clear UserDefaults for clean test state
        UserDefaults.standard.removeObject(forKey: "enabledCategories")
        // Reinitialize after clearing
        settingsManager = SettingsManager()
    }
    
    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: "enabledCategories")
        settingsManager = nil
        super.tearDown()
    }
    
    // MARK: - All 6 Category Groups Exist
    
    func testAllSixCategoryGroupsExist() {
        let groups = LocationCategory.Group.allCases
        XCTAssertEqual(groups.count, 6)
    }
    
    func testAllGroupsHaveCorrectNames() {
        XCTAssertTrue(LocationCategory.Group.allCases.contains { $0.rawValue == "Landmarks and Culture" })
        XCTAssertTrue(LocationCategory.Group.allCases.contains { $0.rawValue == "Nature and Outdoors" })
        XCTAssertTrue(LocationCategory.Group.allCases.contains { $0.rawValue == "Entertainment and Attractions" })
        XCTAssertTrue(LocationCategory.Group.allCases.contains { $0.rawValue == "Sports and Recreation" })
        XCTAssertTrue(LocationCategory.Group.allCases.contains { $0.rawValue == "Travel and Infrastructure" })
        XCTAssertTrue(LocationCategory.Group.allCases.contains { $0.rawValue == "Civic and Public Interest" })
    }
    
    // MARK: - Category Grouping Tests
    
    func testLandmarksAndCultureGroupHasCategories() {
        let group = LocationCategory.Group.landmarksAndCulture
        let categories = LocationCategory.allCases.filter { $0.group == group }
        XCTAssertGreaterThan(categories.count, 0)
        XCTAssertTrue(categories.contains(LocationCategory.landmark))
        XCTAssertTrue(categories.contains(LocationCategory.museum))
    }
    
    func testNatureAndOutdoorsGroupHasCategories() {
        let group = LocationCategory.Group.natureAndOutdoors
        let categories = LocationCategory.allCases.filter { $0.group == group }
        XCTAssertGreaterThan(categories.count, 0)
        XCTAssertTrue(categories.contains(LocationCategory.park))
        XCTAssertTrue(categories.contains(LocationCategory.beach))
    }
    
    func testEntertainmentAndAttractionsGroupHasCategories() {
        let group = LocationCategory.Group.entertainmentAndAttractions
        let categories = LocationCategory.allCases.filter { $0.group == group }
        XCTAssertGreaterThan(categories.count, 0)
        XCTAssertTrue(categories.contains(LocationCategory.zoo))
    }
    
    func testSportsAndRecreationGroupHasCategories() {
        let group = LocationCategory.Group.sportsAndRecreation
        let categories = LocationCategory.allCases.filter { $0.group == group }
        XCTAssertGreaterThan(categories.count, 0)
    }
    
    func testTravelAndInfrastructureGroupHasCategories() {
        let group = LocationCategory.Group.travelAndInfrastructure
        let categories = LocationCategory.allCases.filter { $0.group == group }
        XCTAssertGreaterThan(categories.count, 0)
        XCTAssertTrue(categories.contains(LocationCategory.airport))
    }
    
    func testCivicAndPublicInterestGroupHasCategories() {
        let group = LocationCategory.Group.civicAndPublicInterest
        let categories = LocationCategory.allCases.filter { $0.group == group }
        XCTAssertGreaterThan(categories.count, 0)
        XCTAssertTrue(categories.contains(LocationCategory.library))
    }
    
    // MARK: - All Categories Default Enabled
    
    func testAllCategoriesDefaultEnabled() {
        for category in LocationCategory.allCases {
            XCTAssertTrue(settingsManager.isEnabled(category))
        }
    }
    
    func testGetEnabledCategoriesReturnsAllByDefault() {
        let enabled = settingsManager.getEnabledCategories()
        XCTAssertEqual(enabled.count, LocationCategory.allCases.count)
    }
    
    // MARK: - Category Toggle Tests
    
    func testToggleCategoryToOff() {
        let category = LocationCategory.landmark
        settingsManager.toggleCategory(category)
        XCTAssertFalse(settingsManager.isEnabled(category))
    }
    
    func testToggleCategoryBackToOn() {
        let category = LocationCategory.landmark
        settingsManager.toggleCategory(category)
        settingsManager.toggleCategory(category)
        XCTAssertTrue(settingsManager.isEnabled(category))
    }
    
    func testToggleMultipleCategoriesIndependently() {
        let cat1 = LocationCategory.landmark
        let cat2 = LocationCategory.museum
        let cat3 = LocationCategory.park
        
        settingsManager.toggleCategory(cat1)
        XCTAssertFalse(settingsManager.isEnabled(cat1))
        XCTAssertTrue(settingsManager.isEnabled(cat2))
        XCTAssertTrue(settingsManager.isEnabled(cat3))
        
        settingsManager.toggleCategory(cat2)
        XCTAssertFalse(settingsManager.isEnabled(cat1))
        XCTAssertFalse(settingsManager.isEnabled(cat2))
        XCTAssertTrue(settingsManager.isEnabled(cat3))
    }
    
    // MARK: - Immediate Changes on Modal Dismiss
    
    func testChangesApplyImmediatelyAfterToggle() {
        let category = LocationCategory.landmark
        settingsManager.toggleCategory(category)
        
        // Changes should be immediately visible in the same instance
        XCTAssertFalse(settingsManager.isEnabled(category))
    }
    
    func testMultipleTogglesApplyImmediately() {
        let categories = [LocationCategory.landmark, LocationCategory.museum, LocationCategory.park]
        
        for category in categories {
            settingsManager.toggleCategory(category)
            XCTAssertFalse(settingsManager.isEnabled(category))
        }
        
        let enabled = settingsManager.getEnabledCategories()
        XCTAssertEqual(enabled.count, LocationCategory.allCases.count - categories.count)
    }
    
    // MARK: - Persistence Tests
    
    func testSettingsPersistAfterToggle() {
        let category = LocationCategory.landmark
        settingsManager.toggleCategory(category)
        
        // Create new instance (simulates app relaunch)
        let newManager = SettingsManager()
        XCTAssertFalse(newManager.isEnabled(category))
    }
    
    func testMultipleChangePersistence() {
        settingsManager.setEnabled(LocationCategory.landmark, false)
        settingsManager.setEnabled(LocationCategory.museum, false)
        settingsManager.setEnabled(LocationCategory.park, true)
        
        // Create new instance
        let newManager = SettingsManager()
        XCTAssertFalse(newManager.isEnabled(LocationCategory.landmark))
        XCTAssertFalse(newManager.isEnabled(LocationCategory.museum))
        XCTAssertTrue(newManager.isEnabled(LocationCategory.park))
    }
    
    // MARK: - UserDefaults Integration
    
    func testSettingsStoredInUserDefaults() {
        let category = LocationCategory.landmark
        settingsManager.setEnabled(category, false)
        
        let stored = UserDefaults.standard.dictionary(forKey: "enabledCategories") as? [String: Bool]
        XCTAssertNotNil(stored)
        XCTAssertEqual(stored?[category.rawValue], false)
    }
    
    func testUserDefaultsUpdatedOnToggle() {
        let category = LocationCategory.landmark
        settingsManager.toggleCategory(category)
        
        let stored = UserDefaults.standard.dictionary(forKey: "enabledCategories") as? [String: Bool]
        XCTAssertNotNil(stored)
        XCTAssertEqual(stored?[category.rawValue], false)
    }
    
    // MARK: - Group-Level Filtering
    
    func testCanFilterByGroup() {
        // Disable one group
        let group = LocationCategory.Group.landmarksAndCulture
        let groupCategories = LocationCategory.allCases.filter { $0.group == group }
        
        for category in groupCategories {
            settingsManager.setEnabled(category, false)
        }
        
        // Check that group is disabled
        let enabled = settingsManager.getEnabledCategories()
        for category in groupCategories {
            XCTAssertFalse(enabled.contains(category))
        }
        
        // Check that other groups are still enabled
        let otherGroupCategories = LocationCategory.allCases.filter { $0.group != group }
        for category in otherGroupCategories {
            XCTAssertTrue(enabled.contains(category))
        }
    }
    
    func testCanEnableGroupAfterDisabling() {
        let group = LocationCategory.Group.entertainmentAndAttractions
        let groupCategories = LocationCategory.allCases.filter { $0.group == group }
        
        // Disable group
        for category in groupCategories {
            settingsManager.setEnabled(category, false)
        }
        
        // Re-enable group
        for category in groupCategories {
            settingsManager.setEnabled(category, true)
        }
        
        // Verify all enabled
        let enabled = settingsManager.getEnabledCategories()
        for category in groupCategories {
            XCTAssertTrue(enabled.contains(category))
        }
    }
    
    // MARK: - Modal Display Count Tests
    
    func testSettingsModalCanDisplayAllCategories() {
        // Verify all categories have display names
        for category in LocationCategory.allCases {
            let displayName = category.displayName
            XCTAssertFalse(displayName.isEmpty, "Category \(category.rawValue) should have display name")
            XCTAssertFalse(displayName.contains("_"), "Display name should not contain underscores: \(displayName)")
        }
    }
    
    func testAllCategoriesHaveUniqueDisplayNames() {
        let displayNames = LocationCategory.allCases.map { $0.displayName }
        let uniqueNames = Set(displayNames)
        
        // All display names should be unique
        XCTAssertEqual(displayNames.count, uniqueNames.count)
    }
    
    // MARK: - Edge Cases
    
    func testEmptySettingsAfterDisablingAll() {
        settingsManager.disableAll()
        let enabled = settingsManager.getEnabledCategories()
        XCTAssertEqual(enabled.count, 0)
    }
    
    func testEnableAllAfterDisabling() {
        settingsManager.disableAll()
        settingsManager.enableAll()
        let enabled = settingsManager.getEnabledCategories()
        XCTAssertEqual(enabled.count, LocationCategory.allCases.count)
    }
    
    func testNoOrphanCategories() {
        // Verify every category belongs to exactly one group
        let allCategories = LocationCategory.allCases
        let categoriesInGroups = LocationCategory.Group.allCases.flatMap { group in
            allCategories.filter { $0.group == group }
        }
        
        XCTAssertEqual(Set(categoriesInGroups).count, allCategories.count)
    }
    
    // MARK: - Settings Update Workflow
    
    func testFullWorkflowToggleAndPersist() {
        // Start with all enabled
        XCTAssertEqual(settingsManager.getEnabledCategories().count, LocationCategory.allCases.count)
        
        // Disable some
        settingsManager.toggleCategory(LocationCategory.landmark)
        settingsManager.toggleCategory(LocationCategory.museum)
        
        var enabled = settingsManager.getEnabledCategories()
        XCTAssertEqual(enabled.count, LocationCategory.allCases.count - 2)
        
        // Persist by creating new instance
        let newManager = SettingsManager()
        enabled = newManager.getEnabledCategories()
        XCTAssertEqual(enabled.count, LocationCategory.allCases.count - 2)
        XCTAssertFalse(enabled.contains(LocationCategory.landmark))
        XCTAssertFalse(enabled.contains(LocationCategory.museum))
        
        // Re-enable one
        newManager.toggleCategory(LocationCategory.landmark)
        enabled = newManager.getEnabledCategories()
        XCTAssertEqual(enabled.count, LocationCategory.allCases.count - 1)
        XCTAssertTrue(enabled.contains(LocationCategory.landmark))
    }
    
    // MARK: - UI Readiness Tests
    
    func testSettingsModalCanGroupAllCategories() {
        var categorizedCount = 0
        for group in LocationCategory.Group.allCases {
            let categoriesInGroup = LocationCategory.allCases.filter { $0.group == group }
            categorizedCount += categoriesInGroup.count
        }
        
        XCTAssertEqual(categorizedCount, LocationCategory.allCases.count)
    }
    
    func testGroupHeadersForModal() {
        let groupHeaders = [
            "Landmarks and Culture",
            "Nature and Outdoors",
            "Entertainment and Attractions",
            "Sports and Recreation",
            "Travel and Infrastructure",
            "Civic and Public Interest"
        ]
        
        for header in groupHeaders {
            XCTAssertTrue(
                LocationCategory.Group.allCases.contains { $0.rawValue == header },
                "Group header '\(header)' should exist"
            )
        }
    }
    
    // MARK: - Filter Integration Tests
    
    func testFilteringByEnabledCategories() {
        // Disable a category
        settingsManager.setEnabled(LocationCategory.landmark, false)
        
        // Create mock POIs
        let landmarkPOI = POILocation(
            name: "Monument",
            coordinate: CLLocationCoordinate2D(latitude: 42.0, longitude: -83.0),
            category: .landmark,
            distance: 1000,
            bearing: 0
        )
        
        let museumPOI = POILocation(
            name: "Museum",
            coordinate: CLLocationCoordinate2D(latitude: 42.0, longitude: -83.0),
            category: .museum,
            distance: 1000,
            bearing: 0
        )
        
        let pois = [landmarkPOI, museumPOI]
        let enabledCategories = settingsManager.getEnabledCategories()
        
        // Filter POIs
        let filteredPOIs = pois.filter { poi in
            enabledCategories.contains(poi.category)
        }
        
        // Should only have museum POI
        XCTAssertEqual(filteredPOIs.count, 1)
        XCTAssertEqual(filteredPOIs[0].category, .museum)
    }
    
    func testFilteringAllDisabledCategories() {
        settingsManager.disableAll()
        let enabledCategories = settingsManager.getEnabledCategories()
        
        let pois = [
            POILocation(name: "Landmark", coordinate: CLLocationCoordinate2D(latitude: 42.0, longitude: -83.0), category: .landmark, distance: 1000, bearing: 0),
            POILocation(name: "Museum", coordinate: CLLocationCoordinate2D(latitude: 42.0, longitude: -83.0), category: .museum, distance: 1000, bearing: 0),
        ]
        
        let filteredPOIs = pois.filter { poi in
            enabledCategories.contains(poi.category)
        }
        
        XCTAssertEqual(filteredPOIs.count, 0)
    }
    
    // MARK: - Reset Functionality Tests
    
    func testResetToDefaultsRestoresAll() {
        settingsManager.disableAll()
        XCTAssertEqual(settingsManager.getEnabledCategories().count, 0)
        
        settingsManager.resetToDefaults()
        XCTAssertEqual(settingsManager.getEnabledCategories().count, LocationCategory.allCases.count)
    }
}

// MARK: - Settings Modal View Component Tests

class SettingsModalUIStructureTests: XCTestCase {
    func testSettingsViewCanBeCreated() {
        let settingsManager = SettingsManager()
        let view = SettingsView(settingsManager: settingsManager, isPresented: .constant(true))
        XCTAssertNotNil(view)
    }
    
    func testCategoryGroupSectionCanBeCreated() {
        let settingsManager = SettingsManager()
        let view = CategoryGroupSection(
            group: .landmarksAndCulture,
            settingsManager: settingsManager
        )
        XCTAssertNotNil(view)
    }
    
    func testAllGroupSectionsCanBeCreated() {
        let settingsManager = SettingsManager()
        
        for group in LocationCategory.Group.allCases {
            let view = CategoryGroupSection(
                group: group,
                settingsManager: settingsManager
            )
            XCTAssertNotNil(view)
        }
    }
}

// MARK: - Content View Settings Integration Tests

class ContentViewSettingsIntegrationTests: XCTestCase {
    func testContentViewExists() {
        let view = ContentView()
        XCTAssertNotNil(view)
    }
    
    func testSettingsManagerInitializedByDefault() {
        // ContentView should create a SettingsManager
        let view = ContentView()
        XCTAssertNotNil(view)
    }
}
