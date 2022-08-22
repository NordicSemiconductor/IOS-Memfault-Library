//
//  DeviceUploadView.swift
//  nRF Memfault
//
//  Created by Dinesh Harjani on 16/8/22.
//

import SwiftUI

struct DeviceUploadView: View {
    
    @EnvironmentObject var device: Device
    
    // MARK: View
    
    var body: some View {
        List {
            Section("Chunks") {
                if device.chunks.isEmpty {
                    VStack(alignment: .center) {
                        Image(systemName: "eyedropper")
                            .resizable()
                            .frame(width: 40, height: 40)
                            .foregroundColor(.nordicMiddleGrey)
                        
                        Text("No Chunks have been received at this time.")
                            .font(.subheadline)
                            .foregroundColor(.nordicMiddleGrey)
                    }
                } else {
                    ForEach(device.chunks) { chunk in
                        ChunkView(chunk)
                    }
                }
            }
        }
        .navigationTitle(device.name)
    }
}

#if DEBUG
struct DeviceUploadView_Previews: PreviewProvider {
    
    static var previews: some View {
        NavigationView {
            DeviceUploadView()
                .environmentObject(Device.sample(for: .connected))
        }
    }
}
#endif
