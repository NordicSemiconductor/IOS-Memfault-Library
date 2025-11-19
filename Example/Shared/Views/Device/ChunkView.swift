//
//  ChunkView.swift
//  nRF Memfault
//
//  Created by Dinesh Harjani on 18/8/22.
//

import SwiftUI
import iOSOtaLibrary

// MARK: - ChunkView

struct ChunkView: View {
    
    // MARK: Static
    
    static let timeFormatter: DateFormatter = {
        let timeFormatter = DateFormatter()
        timeFormatter.dateStyle = .none
        timeFormatter.timeStyle = .medium
        return timeFormatter
    }()
    
    static let relativeTimestampFormatter: RelativeDateTimeFormatter = {
        let relativeFormatter = RelativeDateTimeFormatter()
        relativeFormatter.dateTimeStyle = .named
        return relativeFormatter
    }()
    
    static let byteCountFormatter: ByteCountFormatter = {
        let byteCountFormatter = ByteCountFormatter()
        byteCountFormatter.countStyle = .file
        return byteCountFormatter
    }()
    
    // MARK: Environment Variables
    
    @EnvironmentObject var appData: AppData
    
    // MARK: Private
    
    private let device: Device
    private let chunk: ObservabilityChunk
    private let byteCountString: String
    private let hexString: String
    
    @State private var showFullData = false
    
    // MARK: Init
    
    init(device: Device, chunk: ObservabilityChunk) {
        self.device = device
        self.chunk = chunk
        self.byteCountString = Self.byteCountFormatter.string(fromByteCount: Int64(chunk.data.count))
        self.hexString = chunk.data.hexEncodedString(options: [.upperCase, .twoByteSpacing])
    }
    
    // MARK: view
    
    var body: some View {
        DisclosureGroup(isExpanded: $showFullData) {
            Text(hexString)
                .font(.caption)
                .monospaced()
                .foregroundColor(.nordicMiddleGrey)
                .contextMenu {
                    Button(action: {
                        UIPasteboard.general.string = chunk.data.hexEncodedString()
                    }) {
                        Text("Copy to clipboard")
                        Image(systemName: "doc.on.doc")
                    }
                 }
        } label: {
            VStack(spacing: 4.0) {
                HStack {
                    Text("#\(chunk.sequenceNumber)")

                    Text(byteCountString)
                        .foregroundColor(.nordicMiddleGrey)

                    Spacer()

                    switch chunk.status {
                    case .pendingUpload, .uploadError:
                        Button(action: {
                            retryUpload()
                        }) {
                            if chunk.status == .uploadError {
                                Text("Unable to Upload")
                                    .font(.caption)
                                    .foregroundColor(.nordicRed)
                            } else {
                                Image(systemName: "arrow.up")
                                    .foregroundColor(.nordicBlue)
                            }
                        }
                    case .uploading:
                        ProgressView()
                            .frame(width: 8, height: 8)
                    case .success:
                        Image(systemName: "checkmark.circle")
                            .foregroundColor(.nordicPower)
                    }
                }
                
                HStack {
                    Text("Received at ").bold() + Text(ChunkView.timeFormatter.string(for: chunk.timestamp) ?? "N/A")

                    TimelineView(.periodic(from: .now, by: 15.0)) { context in
                        Text("(\(ChunkView.relativeTimestampFormatter.string(for: chunk.timestamp) ?? "N/A"))")
                            .foregroundColor(.nordicMiddleGrey)
                    }

                    Spacer()
                }
                .font(.caption)
            }
        }
        .disclosureGroupStyle(.fixedOnTheRight)
    }
    
    // MARK: API
    
    func retryUpload() {
        guard chunk.status != .success else { return }
        Task(name: #function) {
            do {
                try await appData.upload(chunk, from: device)
            } catch {
                appData.encounteredError(error)
            }
        }
    }
}
