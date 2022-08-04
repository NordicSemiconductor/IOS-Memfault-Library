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
            let scannedDevicesList = Array(appData.scannedDevices)
            ForEach(scannedDevicesList) { scannedDevice in
                DeviceView(scannedDevice)
            }
        }
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
