//
//  ContentView.swift
//  OverTheHorizon
//
//  Created by Programmer Agent
//

import SwiftUI
import CoreLocation
import CoreMotion

struct ContentView: View {
    @StateObject private var cameraManager = CameraManager()
    @StateObject private var locationManager = LocationManager()
    @StateObject private var motionManager = MotionManager()

    var body: some View {
        ZStack {
            // Live camera feed as background
            CameraPreviewView(manager: cameraManager)
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 8) {
                Text("Over the Horizon")
                    .font(.headline)
                    .foregroundColor(.white)

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

                if let heading = motionManager.heading {
                    Text(String(format: "Heading: %.1f°", heading))
                        .font(.caption)
                        .foregroundColor(.white)
                } else {
                    Text("Heading: —")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            .padding()
            .background(Color.black.opacity(0.5))
            .cornerRadius(8)
            .padding()
        }
        .onAppear {
            cameraManager.requestCameraPermission()
            locationManager.requestLocationPermission()
            motionManager.startUpdates()
        }
        .onDisappear {
            cameraManager.stop()
            motionManager.stopUpdates()
        }
    }
}

#Preview {
    ContentView()
}
