//
//  SettingsManager.swift
//  OverTheHorizon
//
//  Created by Programmer Agent
//

import Foundation
import SwiftUI

/// Manages user settings and preferences using UserDefaults.
/// Handles persistence of enabled location categories.
class SettingsManager: ObservableObject {
    // MARK: - Published Properties
    
    /// Dictionary mapping category raw values to their enabled state.
    /// All categories are enabled by default.
    @Published var enabledCategories: [String: Bool] = [:]
    
    // MARK: - Private Properties
    
    private let userDefaults = UserDefaults.standard
    private let enabledCategoriesKey = "enabledCategories"
    
    // MARK: - Initialization
    
    init() {
        loadEnabledCategories()
    }
    
    // MARK: - Public Methods
    
    /// Toggles the enabled state of a category
    /// - Parameter category: The category to toggle
    func toggleCategory(_ category: LocationCategory) {
        let isCurrentlyEnabled = isEnabled(category)
        enabledCategories[category.rawValue] = !isCurrentlyEnabled
        persistEnabledCategories()
    }
    
    /// Sets the enabled state of a category
    /// - Parameters:
    ///   - category: The category to update
    ///   - enabled: Whether the category should be enabled
    func setEnabled(_ category: LocationCategory, _ enabled: Bool) {
        enabledCategories[category.rawValue] = enabled
        persistEnabledCategories()
    }
    
    /// Checks if a category is enabled
    /// - Parameter category: The category to check
    /// - Returns: True if the category is enabled, false otherwise
    func isEnabled(_ category: LocationCategory) -> Bool {
        // Default to true if not set
        return enabledCategories[category.rawValue] ?? true
    }
    
    /// Gets all enabled categories
    /// - Returns: Array of enabled categories
    func getEnabledCategories() -> [LocationCategory] {
        LocationCategory.allCases.filter { isEnabled($0) }
    }
    
    /// Enables all categories
    func enableAll() {
        for category in LocationCategory.allCases {
            enabledCategories[category.rawValue] = true
        }
        persistEnabledCategories()
    }
    
    /// Disables all categories
    func disableAll() {
        for category in LocationCategory.allCases {
            enabledCategories[category.rawValue] = false
        }
        persistEnabledCategories()
    }
    
    /// Resets all settings to default (all categories enabled)
    func resetToDefaults() {
        enableAll()
    }
    
    // MARK: - Private Methods
    
    /// Loads enabled categories from UserDefaults
    private func loadEnabledCategories() {
        // Initialize with all categories enabled by default
        var categories: [String: Bool] = [:]
        for category in LocationCategory.allCases {
            categories[category.rawValue] = true
        }
        
        // Load saved values if they exist
        if let saved = userDefaults.dictionary(forKey: enabledCategoriesKey) as? [String: Bool] {
            categories.merge(saved) { _, new in new }
        }
        
        DispatchQueue.main.async {
            self.enabledCategories = categories
        }
    }
    
    /// Persists enabled categories to UserDefaults
    private func persistEnabledCategories() {
        userDefaults.set(enabledCategories, forKey: enabledCategoriesKey)
    }
}
