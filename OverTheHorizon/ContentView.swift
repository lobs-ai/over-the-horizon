//
//  ContentView.swift
//  OverTheHorizon
//
//  Created by Programmer Agent
//

import SwiftUI
import CoreLocation
import CoreMotion
import MapKit

struct ContentView: View {
    @StateObject private var cameraManager = CameraManager()
    @StateObject private var locationManager = LocationManager()
    @StateObject private var motionManager = MotionManager()
    @StateObject private var zoomGestureManager = ZoomGestureManager()
    @StateObject private var poiSearchManager: POISearchManager
    
    // UI State
    @State private var showPOIList = false
    
    init() {
        let locationMgr = LocationManager()
        _locationManager = StateObject(wrappedValue: locationMgr)
        _poiSearchManager = StateObject(wrappedValue: POISearchManager(locationManager: locationMgr))
        _cameraManager = StateObject(wrappedValue: CameraManager())
        _motionManager = StateObject(wrappedValue: MotionManager())
        _zoomGestureManager = StateObject(wrappedValue: ZoomGestureManager())
    }

    var body: some View {
        ZStack {
            // Live camera feed as background
            CameraPreviewView(manager: cameraManager)
                .ignoresSafeArea()
            
            // AR overlay with POI labels
            AROverlayView(
                pois: poiSearchManager.pois,
                heading: motionManager.heading,
                zoomGestureManager: zoomGestureManager
            )
            .ignoresSafeArea()
            // Add pinch zoom gesture to the AR overlay
            .gesture(
                MagnificationGesture()
                    .onChanged { value in
                        zoomGestureManager.updateZoomWithGesture(scaleFactor: value)
                    }
            )

            VStack(alignment: .leading, spacing: 8) {
                // Header
                HStack {
                    Text("Over the Horizon")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    // POI button
                    Button(action: { showPOIList.toggle() }) {
                        Image(systemName: "mappin.circle.fill")
                            .foregroundColor(.white)
                    }
                }

                // Location Display
                if let location = locationManager.userLocation {
                    Text(String(format: "Lat: %.4f, Lon: %.4f", 
                                location.coordinate.latitude, 
                                location.coordinate.longitude))
                        .font(.caption)
                        .foregroundColor(.white)
                } else {
                    Text("Location: —")
                        .font(.caption)
                        .foregroundColor(.gray)
                }

                // Heading Display
                if let heading = motionManager.heading {
                    Text(String(format: "Heading: %.1f°", heading))
                        .font(.caption)
                        .foregroundColor(.white)
                } else {
                    Text("Heading: —")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                // Zoom Level Display
                Text(String(format: "Zoom: %.2f (%.0f - %.0fm)", 
                            zoomGestureManager.zoomLevel,
                            zoomGestureManager.minDistance,
                            zoomGestureManager.maxDistance / 1000))
                    .font(.caption2)
                    .foregroundColor(.cyan)
                
                // POI Search Status
                if poiSearchManager.isSearching {
                    Text("Searching for POIs...")
                        .font(.caption2)
                        .foregroundColor(.yellow)
                } else if let error = poiSearchManager.errorMessage {
                    Text("Error: \(error)")
                        .font(.caption2)
                        .foregroundColor(.red)
                } else if !poiSearchManager.pois.isEmpty {
                    Text("\(poiSearchManager.pois.count) POIs found")
                        .font(.caption2)
                        .foregroundColor(.green)
                }
            }
            .padding()
            .background(Color.black.opacity(0.6))
            .cornerRadius(8)
            .padding()

            // POI List Sheet
            if showPOIList {
                POIListView(poiSearchManager: poiSearchManager, showPOIList: $showPOIList)
                    .transition(.move(edge: .trailing))
            }
        }
        .onAppear {
            cameraManager.requestCameraPermission()
            locationManager.requestLocationPermission()
            motionManager.startUpdates()
            poiSearchManager.startPeriodicSearch()
        }
        .onDisappear {
            cameraManager.stop()
            motionManager.stopUpdates()
            poiSearchManager.stopPeriodicSearch()
        }
    }
}

// MARK: - POIListView

struct POIListView: View {
    @ObservedObject var poiSearchManager: POISearchManager
    @Binding var showPOIList: Bool
    @State private var selectedCategory: LocationCategory? = nil
    
    var filteredPOIs: [POILocation] {
        if let category = selectedCategory {
            return poiSearchManager.pois.filter { $0.category == category }
        }
        return poiSearchManager.pois
    }
    
    var uniqueCategories: [LocationCategory] {
        Array(Set(poiSearchManager.pois.map { $0.category })).sorted { a, b in
            a.displayName < b.displayName
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Points of Interest")
                    .font(.headline)
                
                Spacer()
                
                Button(action: { showPOIList = false }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
            .padding()
            .background(Color.black.opacity(0.8))
            
            // Category Filter
            if !uniqueCategories.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        Button(action: { selectedCategory = nil }) {
                            Text("All")
                                .font(.caption)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(selectedCategory == nil ? Color.blue : Color.gray.opacity(0.3))
                                .foregroundColor(.white)
                                .cornerRadius(4)
                        }
                        
                        ForEach(uniqueCategories, id: \.self) { category in
                            Button(action: { selectedCategory = category }) {
                                Text(category.displayName)
                                    .font(.caption)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(selectedCategory == category ? Color.blue : Color.gray.opacity(0.3))
                                    .foregroundColor(.white)
                                    .cornerRadius(4)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 8)
            }
            
            // POI List
            if filteredPOIs.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "mappin.slash")
                        .font(.title)
                        .foregroundColor(.gray)
                    
                    Text("No Points of Interest Found")
                        .foregroundColor(.gray)
                    
                    Text("Adjust your search radius or location")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black.opacity(0.4))
            } else {
                List(filteredPOIs) { poi in
                    POIRowView(poi: poi)
                        .listRowBackground(Color.black.opacity(0.5))
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
        .background(Color.black.opacity(0.9))
        .foregroundColor(.white)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
    }
}

// MARK: - POIRowView

struct POIRowView: View {
    let poi: POILocation
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(poi.name)
                        .font(.headline)
                        .lineLimit(1)
                    
                    Text(poi.category.displayName)
                        .font(.caption)
                        .foregroundColor(.blue)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text(String(format: "%.1f km", poi.distance / 1000.0))
                        .font(.caption)
                        .foregroundColor(.green)
                    
                    Text(String(format: "%.0f°", poi.bearing))
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
            }
            
            HStack {
                Text(String(format: "Lat: %.4f", poi.coordinate.latitude))
                    .font(.caption2)
                    .foregroundColor(.gray)
                
                Spacer()
                
                Text(String(format: "Lon: %.4f", poi.coordinate.longitude))
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
            
            if poi.prominence > 0.6 {
                Text("★ High Prominence")
                    .font(.caption2)
                    .foregroundColor(.yellow)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    ContentView()
}
