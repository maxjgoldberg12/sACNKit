import SwiftUI
import sACNKit

struct sACNReceiverView: View {
    @StateObject private var viewModel = sACNReceiverViewModel()
    @State private var universeInput: String = "1"
    @State private var startAddressInput: String = "1"
    @State private var endAddressInput: String = "512"
    @State private var selectedDisplayMode: DisplayMode = .grid
    
    enum DisplayMode: String, CaseIterable {
        case grid = "Grid"
        case list = "List"
        case faders = "Faders"
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                controlsSection
                statusSection
                displayModeSelector
                dataDisplaySection
            }
            .padding()
            .navigationTitle("sACN Receiver")
        }
    }
    
    private var controlsSection: some View {
        GroupBox("Connection Settings") {
            VStack(spacing: 12) {
                HStack {
                    Text("Universe:")
                        .frame(width: 80, alignment: .leading)
                    TextField("Universe (1-63999)", text: $universeInput)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.numberPad)
                        .disabled(viewModel.isListening)
                }
                
                HStack {
                    Text("Start Address:")
                        .frame(width: 80, alignment: .leading)
                    TextField("Start (1-512)", text: $startAddressInput)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.numberPad)
                        .disabled(viewModel.isListening)
                    
                    Text("End:")
                    TextField("End (1-512)", text: $endAddressInput)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.numberPad)
                        .disabled(viewModel.isListening)
                }
                
                Button(action: toggleReceiver) {
                    HStack {
                        Image(systemName: viewModel.isListening ? "stop.circle.fill" : "play.circle.fill")
                        Text(viewModel.isListening ? "Stop Receiving" : "Start Receiving")
                    }
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(viewModel.isListening ? Color.red : Color.green)
                    .cornerRadius(8)
                }
            }
            .padding()
        }
    }
    
    private var statusSection: some View {
        GroupBox("Status") {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Status:")
                    Spacer()
                    Text(viewModel.statusMessage)
                        .foregroundColor(viewModel.isListening ? .green : .secondary)
                }
                
                if viewModel.isListening {
                    HStack {
                        Text("Universe:")
                        Spacer()
                        Text("\(viewModel.universe)")
                    }
                    
                    HStack {
                        Text("Active Sources:")
                        Spacer()
                        Text("\(viewModel.sourceCount)")
                    }
                    
                    if viewModel.isSampling {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Sampling...")
                                .foregroundColor(.orange)
                        }
                    }
                }
                
                if let errorMessage = viewModel.errorMessage {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                        Text(errorMessage)
                            .foregroundColor(.red)
                    }
                }
            }
            .padding()
        }
    }
    
    private var displayModeSelector: some View {
        Picker("Display Mode", selection: $selectedDisplayMode) {
            ForEach(DisplayMode.allCases, id: \.self) { mode in
                Text(mode.rawValue).tag(mode)
            }
        }
        .pickerStyle(SegmentedPickerStyle())
    }
    
    @ViewBuilder
    private var dataDisplaySection: some View {
        if viewModel.isListening {
            switch selectedDisplayMode {
            case .grid:
                gridView
            case .list:
                listView
            case .faders:
                fadersView
            }
        } else {
            Text("Start receiving to view DMX data")
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
    
    private var gridView: some View {
        ScrollView {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 2), count: 16), spacing: 2) {
                ForEach(viewModel.addressRange, id: \.self) { address in
                    let value = viewModel.getChannelValue(at: address)
                    let intensity = viewModel.getChannelPercentage(at: address)
                    
                    VStack(spacing: 2) {
                        Text("\(address)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        Rectangle()
                            .fill(Color.white.opacity(intensity))
                            .frame(height: 30)
                            .overlay(
                                Text("\(value)")
                                    .font(.caption2)
                                    .foregroundColor(intensity > 0.5 ? .black : .white)
                            )
                            .border(Color.gray, width: 0.5)
                    }
                }
            }
            .padding()
        }
    }
    
    private var listView: some View {
        List(viewModel.addressRange, id: \.self) { address in
            let value = viewModel.getChannelValue(at: address)
            let percentage = viewModel.getChannelPercentage(at: address)
            
            HStack {
                Text("Ch \(address)")
                    .font(.system(.body, design: .monospaced))
                    .frame(width: 60, alignment: .leading)
                
                Spacer()
                
                ProgressView(value: percentage)
                    .frame(width: 100)
                
                Spacer()
                
                Text("\(value)")
                    .font(.system(.body, design: .monospaced))
                    .frame(width: 40, alignment: .trailing)
                
                Text("(\(Int(percentage * 100))%)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(width: 50, alignment: .trailing)
            }
        }
    }
    
    private var fadersView: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 10) {
                ForEach(viewModel.addressRange, id: \.self) { address in
                    let value = viewModel.getChannelValue(at: address)
                    let percentage = viewModel.getChannelPercentage(at: address)
                    
                    VStack {
                        Text("\(value)")
                            .font(.caption)
                            .frame(height: 20)
                        
                        GeometryReader { geometry in
                            ZStack(alignment: .bottom) {
                                Rectangle()
                                    .fill(Color.gray.opacity(0.3))
                                
                                Rectangle()
                                    .fill(Color.blue)
                                    .frame(height: geometry.size.height * percentage)
                            }
                        }
                        .frame(width: 30, height: 200)
                        .cornerRadius(4)
                        
                        Text("\(address)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
        }
    }
    
    private func toggleReceiver() {
        if viewModel.isListening {
            viewModel.stopReceiving()
        } else {
            guard let universe = UInt16(universeInput),
                  let startAddress = Int(startAddressInput),
                  let endAddress = Int(endAddressInput),
                  universe >= 1 && universe <= 63999,
                  startAddress >= 1 && startAddress <= 512,
                  endAddress >= startAddress && endAddress <= 512 else {
                viewModel.errorMessage = "Invalid universe or address range"
                return
            }
            
            viewModel.startReceiving(universe: universe, startAddress: startAddress, endAddress: endAddress)
        }
    }
}

#Preview {
    sACNReceiverView()
}