//
//  ScannerView.swift
//  nRF Memfault
//
//  Created by Dinesh Harjani on 3/8/22.
//

import SwiftUI

// MARK: - ScannerView

struct ScannerView: View {
    
    @EnvironmentObject var appData: AppData
    
    var body: some View {
        List {
            ForEach(appData.scannedDevices) { scannedDevice in
                DeviceView(scannedDevice)
            }
            
            if let openDevice = appData.openDevice {
                let openDeviceView = DeviceUploadView()
                    .environmentObject(openDevice)
                NavigationLink(destination: openDeviceView, tag: openDevice, selection: $appData.openDevice, label: {
                    EmptyView()
                })
                .hidden()
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Menu(content: {
                    Toggle("Show Only Memfault Devices", isOn: $appData.showOnlyMDSDevices)
                    Toggle("Show Only Connectable Devices", isOn: $appData.showOnlyConnectableDevices)
                }, label: {
                    Image(systemName: "slider.horizontal.3")
                })
              }
        }
        .onAppear() {
            appData.openDevice = nil
        }
        #if os(iOS)
        .refreshable {
            appData.refresh()
        }
        #endif
    }
}

// MARK: - Preview

#if DEBUG
struct ScannerView_Previews: PreviewProvider {
    
    static var previews: some View {
        ScannerView()
    }
}
#endif
