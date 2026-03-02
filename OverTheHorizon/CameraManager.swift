//
//  CameraManager.swift
//  OverTheHorizon
//
//  Created by Programmer Agent
//

import AVFoundation
import SwiftUI

class CameraManager: NSObject, ObservableObject {
    @Published var authorizationStatus: AVAuthorizationStatus = .notDetermined
    
    private var captureSession: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    
    override init() {
        super.init()
    }
    
    func requestCameraPermission() {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        
        switch status {
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    self?.authorizationStatus = granted ? .authorized : .denied
                    if granted {
                        self?.setupCamera()
                    }
                }
            }
        case .authorized:
            authorizationStatus = .authorized
            setupCamera()
        case .denied, .restricted:
            authorizationStatus = status
        @unknown default:
            break
        }
    }
    
    private func setupCamera() {
        let session = AVCaptureSession()
        session.sessionPreset = .high
        
        guard let rearCamera = AVCaptureDevice.default(.builtInWideAngleCamera, 
                                                       for: .video, 
                                                       position: .back) else {
            return
        }
        
        do {
            let input = try AVCaptureDeviceInput(device: rearCamera)
            if session.canAddInput(input) {
                session.addInput(input)
            }
            
            let output = AVCaptureVideoDataOutput()
            output.setSampleBufferDelegate(self, queue: DispatchQueue(label: "cameraQueue"))
            if session.canAddOutput(output) {
                session.addOutput(output)
            }
            
            self.captureSession = session
            DispatchQueue.global(qos: .background).async {
                session.startRunning()
            }
        } catch {
            print("Error setting up camera: \(error)")
        }
    }
    
    func getPreviewLayer() -> AVCaptureVideoPreviewLayer? {
        guard let session = captureSession else { return nil }
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        return previewLayer
    }
    
    func stop() {
        if let session = captureSession, session.isRunning {
            session.stopRunning()
        }
    }
}

extension CameraManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, 
                      didOutput sampleBuffer: CMSampleBuffer, 
                      from connection: AVCaptureConnection) {
        // Camera feed is being captured and displayed via CameraPreviewView
    }
}
