//
//  ReceivingNewChunksView.swift
//  nRF Memfault
//
//  Created by Dinesh Harjani on 24/8/22.
//

import SwiftUI
import iOS_Common_Libraries

// MARK: - ReceivingNewChunksView

struct ReceivingNewChunksView: View {
    
    // MARK: View
    
    var body: some View {
        HStack {
            Spacer()
           
            ProgressView()
                .fixedCircularProgressView()
            
            Text("Receiving new Chunks...")
                .padding(.horizontal)
            
            Spacer()
        }
        .font(.caption)
    }
}
