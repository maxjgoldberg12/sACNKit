# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

sACNKit is a Swift library implementing ANSI E1.31-2018 (Entertainment Technology - Lightweight streaming protocol for transport of DMX512 using ACN). This is commonly known as sACN (streaming ACN), used in lighting control systems to transmit DMX512 data over IP networks.

## Build and Test Commands

This is a Swift Package Manager project. Common commands:

```bash
# Build the project
swift build

# Run tests
swift test

# Build for release
swift build -c release

# Generate Xcode project (if needed)
swift package generate-xcodeproj
```

## Architecture Overview

The codebase follows a layered protocol architecture matching the E1.31-2018 specification:

### Core Components

- **sACNSource**: Transmits sACN messages to the network
- **sACNReceiver**: Receives and merges sACN messages from a single universe  
- **sACNReceiverGroup**: Manages multiple receivers for different universes
- **sACNReceiverRaw**: Low-level receiver without merging
- **sACNDiscoveryReceiver**: Handles universe discovery messages
- **sACNMerger**: Merges DMX data from multiple sources with priority handling

### Protocol Layers

Located in `Sources/sACNKit/Layers/`:
- **RootLayer**: Base E1.31 protocol layer with packet identification
- **DataFramingLayer**: Contains DMX universe data and metadata
- **UniverseDiscoveryFramingLayer**: For universe discovery messages
- **UniverseDiscoveryLayer**: Lists available universes
- **DMPLayer**: Device Management Protocol layer for actual DMX data

### Networking

- **ComponentSocket**: UDP socket wrapper using CocoaAsyncSocket
- Supports IPv4, IPv6, and dual-stack operation
- Handles multicast group management for sACN

### Key Concepts

- **Universe**: A collection of 512 DMX channels (1-63999 valid range)
- **Source**: An entity that transmits sACN data (identified by UUID)
- **Priority**: Per-universe and per-address priority for merging
- **Sampling**: Initial period where receivers collect sources before merging

## Dependencies

- **CocoaAsyncSocket**: UDP socket implementation for network communication
- Minimum deployment: iOS 12+, macOS 11+
- Swift 5.5+ required

## File Organization

- `Sources/sACNKit/Source/`: Source (transmitter) implementation
- `Sources/sACNKit/Receiver/`: Receiver implementations and delegates
- `Sources/sACNKit/Merger/`: Data merging logic
- `Sources/sACNKit/Layers/`: Protocol layer implementations  
- `Sources/sACNKit/Shared/`: Common utilities, DMX definitions, network helpers
- `Sources/sACNKit/Vendor/`: Third-party code (dispatch utilities)
- `Tests/sACNKitTests/`: Unit tests

## Important Notes

- All network operations are asynchronous using GCD
- Thread-safe access patterns using dispatch queues
- Delegate-based notification system for events
- Extensive error handling with custom error types
- Memory management uses weak references for delegates