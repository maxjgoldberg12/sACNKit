# sACNKit

A comprehensive Swift implementation of ANSI E1.31-2018 Entertainment Technology - Lightweight streaming protocol for transport of DMX512 using ACN (sACN).

[![Swift Package Manager compatible](https://img.shields.io/badge/Swift%20Package%20Manager-compatible-brightgreen.svg)](https://github.com/apple/swift-package-manager)
[![Platform](https://img.shields.io/badge/platform-iOS%2012%2B%20%7C%20macOS%2011%2B-lightgrey.svg)](https://developer.apple.com/swift/)
[![Swift](https://img.shields.io/badge/Swift-5.5+-orange.svg)](https://swift.org)

## Overview

sACNKit provides a complete implementation of the sACN (streaming ACN) protocol, commonly used in professional lighting control systems to transmit DMX512 data over IP networks. The library supports both IPv4 and IPv6, handles multicast communication, and provides comprehensive data merging capabilities.

## Features

- ✅ **Full E1.31-2018 Compliance**: Complete implementation of the ANSI E1.31-2018 standard
- ✅ **Dual Stack Support**: IPv4, IPv6, and dual-stack operation
- ✅ **Source & Receiver**: Both transmit and receive sACN data
- ✅ **Universe Discovery**: Automatic discovery of available universes
- ✅ **Data Merging**: HTP (Highest Takes Precedence) and priority-based merging
- ✅ **Per-Address Priority**: Support for per-channel priority data
- ✅ **Multiple Interfaces**: Bind to specific network interfaces
- ✅ **Thread Safe**: Asynchronous operations with delegate callbacks
- ✅ **Error Handling**: Comprehensive error reporting and validation

## Installation

### Swift Package Manager

Add sACNKit to your project using Xcode:

1. In Xcode, go to **File → Add Package Dependencies...**
2. Enter the repository URL: `https://github.com/dsmurfin/sACNKit`
3. Select the version requirements and add to your target

Or add it to your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/dsmurfin/sACNKit", from: "1.0.0")
],
targets: [
    .target(
        name: "YourTarget",
        dependencies: ["sACNKit"]
    )
]
```

## Quick Start

### Transmitting sACN Data (Source)

```swift
import sACNKit

// Create a source with a unique CID
let source = sACNSource(
    name: "My Lighting Console",
    cid: UUID(),
    delegateQueue: DispatchQueue.main
)

// Create a universe with DMX data
var universe = sACNSourceUniverse(
    number: 1,
    priority: 100,
    levels: [255, 128, 0, 255] // First 4 channels
)

do {
    // Add universe to source
    try source.addUniverse(universe)
    
    // Start transmitting
    try source.start()
    
    // Update channel levels
    try source.updateSlot(slot: 0, in: 1, level: 200)
    
} catch {
    print("Error: \(error)")
}
```

### Receiving sACN Data (Single Universe)

```swift
import sACNKit

class MyReceiver: sACNReceiverDelegate {
    let receiver: sACNReceiver
    
    init() {
        receiver = sACNReceiver(
            universe: 1,
            delegateQueue: DispatchQueue.main
        )!
        receiver.setDelegate(self)
    }
    
    func startReceiving() {
        do {
            try receiver.start()
        } catch {
            print("Failed to start receiver: \(error)")
        }
    }
    
    // MARK: - sACNReceiverDelegate
    
    func receiverMergedData(_ receiver: sACNReceiver, mergedData: sACNReceiverMergedData) {
        print("Universe \(mergedData.universe): \(mergedData.levels.prefix(10))")
        print("Active sources: \(mergedData.numberOfActiveSources)")
    }
    
    func receiver(_ receiver: sACNReceiver, lostSources: [UUID]) {
        print("Lost \(lostSources.count) sources")
    }
    
    func receiverStartedSampling(_ receiver: sACNReceiver) {
        print("Started sampling")
    }
    
    func receiverEndedSampling(_ receiver: sACNReceiver) {
        print("Ended sampling")
    }
    
    func receiverExceededSources(_ receiver: sACNReceiver) {
        print("Too many sources detected")
    }
    
    func receiver(_ receiver: sACNReceiver, interface: String?, socketDidCloseWithError error: Error?) {
        if let error = error {
            print("Socket error: \(error)")
        }
    }
}
```

### Receiving Multiple Universes

```swift
import sACNKit

class MultiUniverseReceiver: sACNReceiverGroupDelegate {
    let receiverGroup: sACNReceiverGroup
    
    init() {
        receiverGroup = sACNReceiverGroup(
            sourceLimit: 8,
            delegateQueue: DispatchQueue.main
        )
        receiverGroup.setDelegate(self)
    }
    
    func startReceiving() {
        do {
            // Add multiple universes
            try receiverGroup.add(universe: 1)
            try receiverGroup.add(universe: 2)
            try receiverGroup.add(universe: 3)
        } catch {
            print("Failed to add universes: \(error)")
        }
    }
    
    // MARK: - sACNReceiverGroupDelegate
    
    func receiverGroupMergedData(_ receiverGroup: sACNReceiverGroup, mergedData: sACNReceiverMergedData) {
        print("Universe \(mergedData.universe): \(mergedData.levels.prefix(5))")
    }
    
    func receiverGroup(_ receiverGroup: sACNReceiverGroup, lostSources: [UUID], forUniverse universe: UInt16) {
        print("Universe \(universe) lost \(lostSources.count) sources")
    }
    
    func receiverGroupStartedSampling(_ receiverGroup: sACNReceiverGroup, forUniverse universe: UInt16) {
        print("Universe \(universe) started sampling")
    }
    
    func receiverGroupEndedSampling(_ receiverGroup: sACNReceiverGroup, forUniverse universe: UInt16) {
        print("Universe \(universe) ended sampling")
    }
    
    func receiverGroupExceededSources(_ receiverGroup: sACNReceiverGroup, forUniverse universe: UInt16) {
        print("Universe \(universe) exceeded source limit")
    }
    
    func receiverGroup(_ receiverGroup: sACNReceiverGroup, interface: String?, socketDidCloseWithError error: Error?, forUniverse universe: UInt16) {
        if let error = error {
            print("Universe \(universe) socket error: \(error)")
        }
    }
}
```

### Universe Discovery

```swift
import sACNKit

class UniverseDiscovery: sACNDiscoveryReceiverDelegate {
    let discoveryReceiver: sACNDiscoveryReceiver
    
    init() {
        discoveryReceiver = sACNDiscoveryReceiver(
            delegateQueue: DispatchQueue.main
        )
        discoveryReceiver.setDelegate(self)
    }
    
    func startDiscovery() {
        do {
            try discoveryReceiver.start()
        } catch {
            print("Failed to start discovery: \(error)")
        }
    }
    
    // MARK: - sACNDiscoveryReceiverDelegate
    
    func discoveryReceiverReceivedInfo(_ receiver: sACNDiscoveryReceiver, sourceInformation: sACNDiscoveryReceiverSource) {
        print("Source: \(sourceInformation.name)")
        print("CID: \(sourceInformation.cid)")
        print("Universes: \(sourceInformation.universes)")
    }
    
    func discoveryReceiver(_ receiver: sACNDiscoveryReceiver, lostSources: [UUID]) {
        print("Lost \(lostSources.count) discovery sources")
    }
    
    func discoveryReceiver(_ receiver: sACNDiscoveryReceiver, interface: String?, socketDidCloseWithError error: Error?) {
        if let error = error {
            print("Discovery socket error: \(error)")
        }
    }
}
```

## Advanced Usage

### Per-Address Priority

```swift
// Create universe with per-address priority
var universe = sACNSourceUniverse(
    number: 1,
    priority: 100,
    levels: Array(repeating: 0, count: 512),
    priorities: Array(repeating: 100, count: 512)
)

// Update specific channel priorities
try source.updateSlot(slot: 0, in: 1, level: 255, priority: 200)
```

### Network Interface Binding

```swift
// Bind to specific interfaces
let source = sACNSource(
    name: "Console",
    interfaces: ["en0", "192.168.1.100"],
    delegateQueue: DispatchQueue.main
)

// IPv6 support
let receiver = sACNReceiver(
    ipMode: .ipv6Only,
    interfaces: ["en0"],
    universe: 1,
    delegateQueue: DispatchQueue.main
)
```

### Raw Data Access

```swift
class RawDataReceiver: sACNReceiverRawDelegate {
    let rawReceiver: sACNReceiverRaw
    
    init() {
        rawReceiver = sACNReceiverRaw(
            universe: 1,
            delegateQueue: DispatchQueue.main
        )!
        rawReceiver.setDelegate(self)
    }
    
    // Access raw, unmerged data from individual sources
    func receiverReceivedUniverseData(_ receiver: sACNReceiverRaw, sourceData: sACNReceiverRawSourceData) {
        print("Source \(sourceData.cid): \(sourceData.values.prefix(10))")
        print("Priority: \(sourceData.priority)")
        print("Start Code: \(sourceData.startCode)")
    }
}
```

## Core Classes

### Sources (Transmitters)

- **`sACNSource`**: Main source class for transmitting sACN data
- **`sACNSourceUniverse`**: Universe data container with levels and priorities

### Receivers

- **`sACNReceiver`**: Single universe receiver with automatic merging
- **`sACNReceiverGroup`**: Multi-universe receiver management
- **`sACNReceiverRaw`**: Low-level receiver for raw, unmerged data
- **`sACNDiscoveryReceiver`**: Universe discovery message receiver

### Advanced Components

- **`sACNMerger`**: Standalone data merging engine
- **Protocol Layers**: `RootLayer`, `DataFramingLayer`, `DMPLayer`, etc.

## Error Handling

sACNKit provides comprehensive error handling through specific error types:

```swift
do {
    try source.addUniverse(universe)
} catch sACNSourceValidationError.universeExists {
    print("Universe already exists")
} catch sACNSourceValidationError.invalidSlotNumber {
    print("Invalid DMX channel number")
} catch sACNComponentSocketError.couldNotBind(let message) {
    print("Network error: \(message)")
}
```

## Key Concepts

### Universe
A universe represents a collection of 512 DMX channels (addresses 1-512). Valid universe numbers range from 1-63999.

### Priority
sACN supports both per-universe priority (0-200) and per-address priority for sophisticated merging scenarios.

### Sampling Period
When receivers start, they enter a sampling period to discover all available sources before beginning data merging.

### CID (Component Identifier)
Each sACN source is identified by a unique UUID that should persist across application launches.

## Requirements

- iOS 12.0+ / macOS 11.0+
- Swift 5.5+
- Xcode 13.0+

## Dependencies

- [CocoaAsyncSocket](https://github.com/robbiehanson/CocoaAsyncSocket): UDP networking

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

sACNKit is available under the MIT license. See the LICENSE file for more info.

## Standards Compliance

This library implements ANSI E1.31-2018 "Entertainment Technology - Lightweight streaming protocol for transport of DMX512 using ACN".
