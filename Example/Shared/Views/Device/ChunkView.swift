//
//  ChunkView.swift
//  nRF Memfault
//
//  Created by Dinesh Harjani on 18/8/22.
//

import SwiftUI

// MARK: - ChunkView

struct ChunkView: View {
    
    // MARK: Environment Variables
    
    @EnvironmentObject var appData: AppData
    @EnvironmentObject var device: Device
    
    // MARK: Private
    
    static let timestampFormatter: RelativeDateTimeFormatter = {
        let relativeFormatter = RelativeDateTimeFormatter()
        relativeFormatter.dateTimeStyle = .named
        return relativeFormatter
    }()
    
    private let chunk: Chunk
    
    @State private var showFullData = false
    
    // MARK: Init
    
    init(_ chunk: Chunk) {
        self.chunk = chunk
    }
    
    // MARK: View
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text("#\(chunk.sequenceNumber)")
                
                Text("\(chunk.data.count) bytes")
                    .foregroundColor(.nordicLightGrey)
                
                Spacer()
                
                switch chunk.status {
                case .ready, .errorUploading:
                    Button(action: {
                        tryToUpload()
                    }) {
                        if chunk.status == .errorUploading {
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
                
                Button(action: {
                    showFullData.toggle()
                }) {
                    Image(systemName: showFullData ? "chevron.up" : "chevron.down")
                        .foregroundColor(.nordicBlue)
                }
                .padding(.leading, 8)
            }
            
            if showFullData {
                Text(chunk.data.hexEncodedString(options: [.upperCase]))
                    .font(.caption)
                    .foregroundColor(.nordicMiddleGrey)
            }
            
            HStack {
                Text("Received")
                
                TimelineView(.periodic(from: .now, by: 15.0)) { context in
                    Text(ChunkView.timestampFormatter.string(for: chunk.timestamp) ?? "Unable to parse Timestamp.")
                        .foregroundColor(.nordicMiddleGrey)
                }
                
                Spacer()
            }
            .font(.caption)
        }
        .contextMenu {
            Button(action: {
                UIPasteboard.general.string = chunk.data.hexEncodedString()
            }) {
                Text("Copy to clipboard")
                Image(systemName: "doc.on.doc")
            }
         }
    }
    
    // MARK: API
    
    func tryToUpload() {
        guard chunk.status != .success else { return }
        
        Task {
            do {
                try await appData.upload(chunk, from: device)
            } catch {
                appData.encounteredError(error)
            }
        }
    }
}
