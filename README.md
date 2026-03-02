# Over the Horizon

A landscape-only iOS app (iOS 17+) that displays a live camera feed with real-time location and heading information using SwiftUI.

## Features

- **Live Camera Feed**: Full-screen video capture from the rear camera using AVCaptureSession
- **Location Services**: Displays user's current latitude and longitude using CoreLocation
- **Heading Detection**: Shows compass heading using CMMotionManager (device motion with gyroscope and accelerometer)
- **SwiftUI Interface**: Modern, clean UI with dark theme
- **Privacy Compliant**: Includes all required Info.plist privacy keys for camera, location, and motion

## Project Structure

```
OverTheHorizon/
├── OverTheHorizonApp.swift      # App entry point (@main)
├── ContentView.swift             # Main UI with camera, location, and heading display
├── CameraManager.swift           # AVCaptureSession management
├── CameraPreviewView.swift       # UIViewRepresentable for camera feed
├── LocationManager.swift         # CoreLocation and user location tracking
├── MotionManager.swift           # CMMotionManager for heading/orientation
└── Info.plist                    # Configuration with privacy keys

OverTheHorizonTests/
└── OverTheHorizonTests.swift     # Unit and integration tests

OverTheHorizon.xcodeproj/
└── project.pbxproj              # Xcode project configuration
```

## Requirements

- Xcode 15.0+
- iOS 17.0+
- Swift 5.0+

## Build Instructions

1. Open `OverTheHorizon.xcodeproj` in Xcode
2. Select a simulator or device targeting iOS 17+
3. Build and run (⌘R)

## Permissions Required

The app requests the following permissions:
- **Camera**: For live video feed display
- **Location (When In Use)**: For user location tracking
- **Motion**: For device heading and orientation

All permissions are declared in `Info.plist` with user-friendly descriptions.

## Architecture

### Camera Management (CameraManager)
- Uses AVCaptureSession with rear camera (wide-angle)
- Handles authorization and setup
- Manages session lifecycle

### Location Services (LocationManager)
- Implements CLLocationManagerDelegate
- Requests "When In Use" location authorization
- Updates user location in real-time
- Handles authorization changes

### Motion & Heading (MotionManager)
- Uses CMMotionManager for device motion
- Calculates heading from device attitude (yaw component)
- Provides continuous heading updates (0-360°)
- Gracefully handles unavailable motion hardware

### UI (ContentView & CameraPreviewView)
- SwiftUI main view with dark theme
- Camera preview as full-screen background
- Overlay showing location and heading info
- Responsive to lifecycle events (onAppear/onDisappear)

## Testing

The project includes unit tests covering:
- Manager initialization
- Permission requests
- Lifecycle methods (start/stop)

To run tests in Xcode:
1. Press ⌘U or select Product > Test
2. View results in the Test Navigator

## Future Enhancements

- Overlay rendering (AR layer for horizon visualization)
- Gyroscope-based motion parallax
- Heading history visualization
- Performance optimizations
- Advanced camera controls (focus, exposure)

## Notes

- The app is landscape-only as specified in Info.plist
- Camera feed is optimized for rear-facing camera
- Heading calculation uses device attitude (pitch/roll/yaw)
- All managers are @ObservedObject in SwiftUI for reactive updates
