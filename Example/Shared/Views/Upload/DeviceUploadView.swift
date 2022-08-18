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
                ForEach(device.chunks) { chunk in
                    Text("\(chunk.data.count) bytes.")
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
