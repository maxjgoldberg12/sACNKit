# sACN Receiver SwiftUI Example

This example demonstrates how to receive sACN data in a SwiftUI application using sACNKit.

## Files

- `sACNReceiverApp.swift` - Main app entry point
- `sACNReceiverView.swift` - SwiftUI view with three display modes (Grid, List, Faders)
- `sACNReceiverViewModel.swift` - ObservableObject that manages sACN receiver and data

## Features

- **Universe Selection**: Configure which sACN universe to listen to (1-63999)
- **Address Range**: Specify which DMX addresses to monitor (1-512)
- **Real-time Updates**: Live display of DMX channel values
- **Multiple Display Modes**:
  - **Grid**: 16x32 grid showing all channels with visual intensity
  - **List**: Scrollable list with progress bars and percentage values
  - **Faders**: Horizontal fader-style display
- **Source Monitoring**: Shows number of active sACN sources
- **Status Updates**: Real-time connection status and error handling
- **Sampling Indicator**: Visual feedback during the initial sampling period

## Usage

1. Enter a universe number (1-63999)
2. Optionally specify an address range (default is 1-512 for all channels)
3. Tap "Start Receiving" to begin listening for sACN data
4. Switch between display modes using the segmented control
5. Monitor channel values in real-time as they change

## Network Requirements

- Ensure your device is connected to the same network as sACN sources
- The app listens on IPv4 multicast addresses according to E1.31 specification
- Firewall settings should allow UDP traffic on the sACN port ranges

## Integration

To integrate this into your own app:

1. Add sACNKit as a dependency to your project
2. Copy the ViewModel and adapt it to your needs
3. Create your own SwiftUI views or use the provided examples
4. Handle the delegate methods to process received DMX data

## Example Use Cases

- **Lighting Control Monitoring**: Monitor DMX values being sent to lighting fixtures
- **Visualizers**: Create real-time lighting visualizations
- **Debugging Tools**: Troubleshoot sACN network issues
- **Educational**: Learn about DMX and sACN protocols