//
//  MotionManager.swift
//  OverTheHorizon
//
//  Created by Programmer Agent
//

import CoreMotion
import SwiftUI

class MotionManager: NSObject, ObservableObject {
    @Published var heading: Double? = nil
    
    private let motionManager = CMMotionManager()
    private let locationManager = CoreMotion.CMHeadingFilterValueDefault
    
    override init() {
        super.init()
        checkMotionManagerAvailability()
    }
    
    func startUpdates() {
        guard motionManager.isDeviceMotionAvailable else {
            print("Device motion not available")
            return
        }
        
        motionManager.deviceMotionUpdateInterval = 0.1
        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, error in
            guard let motion = motion else {
                print("Motion error: \(String(describing: error))")
                return
            }
            
            // Calculate heading from device attitude
            let attitude = motion.attitude
            let heading = self?.calculateHeading(from: attitude) ?? 0.0
            
            DispatchQueue.main.async {
                self?.heading = heading
            }
        }
    }
    
    func stopUpdates() {
        motionManager.stopDeviceMotionUpdates()
    }
    
    private func checkMotionManagerAvailability() {
        if !motionManager.isDeviceMotionAvailable {
            print("Warning: Device motion is not available")
        }
    }
    
    private func calculateHeading(from attitude: CMAttitude) -> Double {
        let roll = attitude.roll
        let pitch = attitude.pitch
        let yaw = attitude.yaw
        
        // Simple heading calculation from yaw component
        // Yaw ranges from -π to π, convert to 0-360°
        let heading = (yaw * 180.0 / Double.pi) + 180.0
        return heading.truncatingRemainder(dividingBy: 360.0)
    }
}
