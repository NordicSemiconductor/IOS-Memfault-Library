//
//  ChunkView.swift
//  nRF Memfault
//
//  Created by Dinesh Harjani on 18/8/22.
//

import SwiftUI

struct ChunkView: View {
    
    private let chunk: Chunk
    
    init(_ chunk: Chunk) {
        self.chunk = chunk
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(chunk.data.hexEncodedString(options: [.upperCase]))
            
            Text("\(chunk.data.count) bytes.")
                .font(.caption)
                .foregroundColor(.nordicMiddleGrey)
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
