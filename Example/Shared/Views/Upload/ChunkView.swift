//
//  ChunkView.swift
//  nRF Memfault
//
//  Created by Dinesh Harjani on 18/8/22.
//

import SwiftUI

struct ChunkView: View {
    
    static let timestampFormatter: RelativeDateTimeFormatter = {
        let relativeFormatter = RelativeDateTimeFormatter()
        relativeFormatter.dateTimeStyle = .named
        return relativeFormatter
    }()
    
    private let chunk: Chunk
    
    @State private var showFullData = false
    
    init(_ chunk: Chunk) {
        self.chunk = chunk
    }
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text("#\(chunk.sequenceNumber)")
                
                
                Text("\(chunk.data.count) bytes")
                    .foregroundColor(.nordicLightGrey)
                
                Spacer()
                
                switch chunk.status {
                case .ready:
                    Button(action: {
                        // To-Do
                    }) {
                        Image(systemName: "arrow.up")
                            .foregroundColor(.nordicBlue)
                    }
                    EmptyView()
                case .uploading:
                    ProgressView()
                        .frame(width: 8, height: 8)
                case .errorUploading:
                    Text("Error")
                        .font(.caption)
                        .foregroundColor(.nordicRed)
                case .success:
                    Image(systemName: "checkmark.circle")
                        .foregroundColor(.nordicGrass)
                }
                
                Button(action: {
                    showFullData.toggle()
                }) {
                    Image(systemName: showFullData ? "chevron.up" : "chevron.down")
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
}

//#if DEBUG
//struct ChunkView_Previews: PreviewProvider {
//    static var previews: some View {
//        ChunkView()
//    }
//}
//#endif
