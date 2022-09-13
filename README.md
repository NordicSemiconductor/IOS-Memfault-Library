# iOS nRF Memfault Library + Example App

A Swift-based library for iOS/iPadOS/macOS can connects to a Bluetooth LE device supporting the Memfault Diagnostic Service, downloads data Chunks and uploads them to [the Memfault Console](https://docs.memfault.com).

The device is expected to support the Memfault Diagnostic Service, [as defined here](https://memfault.notion.site/Memfault-Diagnostic-GATT-Service-MDS-ffd5a430062649cd9bf6edbf64e2563b).

# Library

## Minimum OS Requirements

* iOS: 15.0
* macOS: 12.0

In all cases, **the Library requires an active Internet connection**. If an Error is encountered when uploading a Chunk of Data, **the BLE connection to the device will be dropped immediately** to ensure the least amount of Chunks of Data are lost.

## Basic Usage

```swift

let memfaultManager = MemfaultManager()
// Connects to the Device and begins automagically streaming / uploading data.
await memfaultManager.connect(to: device)

// To stop / disconnect.
await memfaultManager.disconnect(from: device)
```

Memfault's APIs take a `BluetoothDevice`, which is a very simple protocol requiring only the UUID String of a Device. A `CBPeripheral` extension is provided as part of the library, so you're free to pass-in your scanned `CBPeripheral` with no issues. 

## Advanced Usage

It is possible to listen to all state changes & errors as they occur from the Memfault Library, like so:

```swift

let memfaultManager = MemfaultManager()

let connectionStream = await memfaultManager.connect(to: device)
do {
    for try await newEvent in connectionStream {
        switch newEvent.event {
            // Logic for each Event.
        }
    }
} catch {
    // Error handling.
}

// Disconnect when needed.
await memfaultManager.disconnect(from: device)
```

Furthermore, it's also possible to manually ask the framework to upload a specific Chunk if an error were to happen:

```swift
try await memfaultManager.upload(chunk, with: chunkAuth)
```

This requires passing-in the `MemfaultChunkAuth` struct, which is received through an autentication event from the connection stream (`AsyncSequence`).

# Example App

The aforementioned Advanced Usage is what enables a UI-based app to inform the user of what the underlying Memfault Library is doing, as well as providing manual control of connection / disconnection and forcing a Memfault Chunk of Data to be uploaded in case an error occurs.
