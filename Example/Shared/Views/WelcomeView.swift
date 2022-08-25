//
//  WelcomeView.swift
//  nRF Memfault
//
//  Created by Dinesh Harjani on 25/8/22.
//

import SwiftUI

// MARK: - WelcomeView

struct WelcomeView: View {
    
    // MARK: Environment Values
    
    @Environment(\.dismiss) var dismiss
    
    // MARK: View
    
    var body: some View {
        VStack(spacing: 16) {
            Text("nRF Memfault")
                .font(.title)
                .bold()
            
            Image("AppIcon")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 150, height: 150)
            
            Text("An iOS Example App + Library that can connect to a Bluetooth LE device with the Memfault Service, receive Chunks of Data, and upload them to the Memfault console.")
            
            Text("As noted above, this Example App / Library requires that the connected Device implement the Memfault Service.")
            
            Text("An Internet connection is required to upload Data back to the Memfault console. If an error is encountered during Upload, the BLE connection with the device is dropped to minimise data loss.")
            
            Button("Start", action: {
                dismiss()
            })
            .padding(.vertical)
        }
        .padding(.horizontal)
    }
}

// MARK: - Preview

#if DEBUG
struct WelcomeView_Previews: PreviewProvider {
    static var previews: some View {
        WelcomeView()
    }
}
#endif
