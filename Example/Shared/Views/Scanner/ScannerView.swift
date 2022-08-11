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
