//
//  AboutView.swift
//  nRF Memfault
//
//  Created by Dinesh Harjani on 25/8/22.
//

import SwiftUI
import iOS_Common_Libraries

// MARK: - AboutView

struct AboutView: View {
    
    // MARK: Environment Values
    
    @Environment(\.dismiss) var dismiss
    
    // MARK: View
    
    var body: some View {
        VStack(spacing: 16) {
            Text("nRF Memfault")
                .font(.title)
                .bold()
            
            AppIconView()

            Text("An iOS Example App + Library that can connect to a Bluetooth LE device with the Memfault Diagnostic Service, receive Chunks of Data, and upload them to the [Memfault console](https://memfault.com/).")
            
            Text("As noted above, this Example App / Library requires that the connected Device implement the Memfault Diagnostic Service.")
            
            Text("An Internet connection is required to upload Data back to the [Memfault console](https://docs.memfault.com/docs/android/introduction). **If uploading a Chunk fails, the BLE connection with the device will be dropped** to minimise data loss.")
            
            Button("Start", action: {
                dismiss()
            })
            .foregroundColor(.nordicBlue)
            .padding(.vertical)
        }
        .padding(.horizontal, 16)
    }
}

// MARK: - Preview

#if DEBUG
struct AboutView_Previews: PreviewProvider {
    
    static var previews: some View {
        AboutView()
    }
}
#endif
