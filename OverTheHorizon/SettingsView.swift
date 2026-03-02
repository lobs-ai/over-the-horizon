//
//  SettingsView.swift
//  OverTheHorizon
//
//  Created by Programmer Agent
//

import SwiftUI

/// A modal view for managing location category filter settings.
struct SettingsView: View {
    @ObservedObject var settingsManager: SettingsManager
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.opacity(0.95)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    HStack {
                        Text("Category Filters")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Button(action: { isPresented = false }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                                .font(.title3)
                        }
                    }
                    .padding()
                    .background(Color.black.opacity(0.9))
                    
                    ScrollView {
                        VStack(spacing: 24) {
                            ForEach(LocationCategory.Group.allCases, id: \.self) { group in
                                CategoryGroupSection(
                                    group: group,
                                    settingsManager: settingsManager
                                )
                            }
                        }
                        .padding()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

// MARK: - CategoryGroupSection

struct CategoryGroupSection: View {
    let group: LocationCategory.Group
    @ObservedObject var settingsManager: SettingsManager
    
    var categoriesInGroup: [LocationCategory] {
        LocationCategory.allCases.filter { $0.group == group }
            .sorted { $0.displayName < $1.displayName }
    }
    
    var groupEnabledCount: Int {
        categoriesInGroup.filter { settingsManager.isEnabled($0) }.count
    }
    
    var allGroupEnabled: Bool {
        groupEnabledCount == categoriesInGroup.count
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Group Header with toggle
            HStack {
                Text(group.rawValue)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.cyan)
                
                Spacer()
                
                // Group toggle to enable/disable all in group
                Toggle("", isOn: Binding(
                    get: { allGroupEnabled },
                    set: { enabled in
                        for category in categoriesInGroup {
                            settingsManager.setEnabled(category, enabled)
                        }
                    }
                ))
                .tint(.cyan)
            }
            
            // Category toggles
            VStack(alignment: .leading, spacing: 10) {
                ForEach(categoriesInGroup, id: \.self) { category in
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(
                                settingsManager.isEnabled(category) ? .cyan : .gray
                            )
                            .font(.body)
                        
                        Text(category.displayName)
                            .font(.caption)
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Toggle("", isOn: Binding(
                            get: { settingsManager.isEnabled(category) },
                            set: { enabled in
                                settingsManager.setEnabled(category, enabled)
                            }
                        ))
                        .tint(.cyan)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .background(
                        settingsManager.isEnabled(category)
                            ? Color.cyan.opacity(0.1)
                            : Color.gray.opacity(0.05)
                    )
                    .cornerRadius(4)
                }
            }
        }
        .padding(12)
        .background(Color.white.opacity(0.05))
        .cornerRadius(8)
    }
}

#Preview {
    SettingsView(
        settingsManager: SettingsManager(),
        isPresented: .constant(true)
    )
}
