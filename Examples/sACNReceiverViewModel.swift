import Foundation
import SwiftUI
import sACNKit

@MainActor
class sACNReceiverViewModel: ObservableObject, sACNReceiverDelegate {
    @Published var universe: UInt16 = 1
    @Published var isListening: Bool = false
    @Published var dmxData: [UInt8] = Array(repeating: 0, count: 512)
    @Published var activeSources: [UUID] = []
    @Published var sourceCount: Int = 0
    @Published var errorMessage: String?
    @Published var statusMessage: String = "Ready to receive"
    @Published var isSampling: Bool = false
    
    private var receiver: sACNReceiver?
    private let delegateQueue = DispatchQueue(label: "sACNReceiverDelegate")
    
    var addressRange: ClosedRange<Int> = 1...512
    
    func startReceiving(universe: UInt16, startAddress: Int = 1, endAddress: Int = 512) {
        guard !isListening else { return }
        
        self.universe = universe
        self.addressRange = startAddress...endAddress
        
        do {
            receiver = sACNReceiver(
                ipMode: .ipv4Only,
                interfaces: [],
                universe: universe,
                sourceLimit: 8,
                filterPreviewData: true,
                filterCIDs: [],
                delegateQueue: delegateQueue
            )
            
            guard let receiver = receiver else {
                errorMessage = "Failed to create receiver for universe \(universe)"
                return
            }
            
            receiver.setDelegate(self)
            try receiver.start()
            
            isListening = true
            errorMessage = nil
            statusMessage = "Listening on universe \(universe), addresses \(startAddress)-\(endAddress)"
            
        } catch {
            errorMessage = "Failed to start receiver: \(error.localizedDescription)"
            statusMessage = "Error starting receiver"
        }
    }
    
    func stopReceiving() {
        receiver?.stop()
        receiver = nil
        isListening = false
        statusMessage = "Stopped listening"
        activeSources.removeAll()
        sourceCount = 0
        isSampling = false
    }
    
    func getChannelValue(at address: Int) -> UInt8 {
        guard address >= 1 && address <= 512 else { return 0 }
        return dmxData[address - 1]
    }
    
    func getChannelPercentage(at address: Int) -> Double {
        let value = getChannelValue(at: address)
        return Double(value) / 255.0
    }
    
    // MARK: - sACNReceiverDelegate
    
    func receiver(_ receiver: sACNReceiver, interface: String?, socketDidCloseWithError error: Error?) {
        Task { @MainActor in
            if let error = error {
                errorMessage = "Socket error: \(error.localizedDescription)"
                statusMessage = "Connection lost"
            }
            isListening = false
        }
    }
    
    func receiverMergedData(_ receiver: sACNReceiver, mergedData: sACNReceiverMergedData) {
        Task { @MainActor in
            dmxData = mergedData.levels
            activeSources = mergedData.activeSources
            sourceCount = mergedData.numberOfActiveSources
            
            if !isSampling {
                statusMessage = "Receiving data from \(sourceCount) source\(sourceCount == 1 ? "" : "s")"
            }
        }
    }
    
    func receiverStartedSampling(_ receiver: sACNReceiver) {
        Task { @MainActor in
            isSampling = true
            statusMessage = "Sampling sources..."
        }
    }
    
    func receiverEndedSampling(_ receiver: sACNReceiver) {
        Task { @MainActor in
            isSampling = false
            statusMessage = "Sampling complete"
        }
    }
    
    func receiver(_ receiver: sACNReceiver, lostSources: [UUID]) {
        Task { @MainActor in
            statusMessage = "Lost \(lostSources.count) source\(lostSources.count == 1 ? "" : "s")"
        }
    }
    
    func receiverExceededSources(_ receiver: sACNReceiver) {
        Task { @MainActor in
            errorMessage = "Too many sources detected"
            statusMessage = "Source limit exceeded"
        }
    }
}