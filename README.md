<div align="center">
  <img src="https://storage.googleapis.com/hume-public-logos/hume/hume-banner.png">
  <h1>Hume AI Swift SDK</h1>

  <p>
    <strong>Integrate Hume APIs directly into your Swift application</strong>
  </p>

  <br>
  <div>
    <a href="https://buildwithfern.com/"><img src="https://img.shields.io/badge/%F0%9F%8C%BF-SDK%20generated%20by%20Fern-brightgreen">     
  </div>
  <br>
</div>

## Documentation

API reference documentation is available [here](https://dev.hume.ai/reference/).

## Installation

Add to your `Package.swift`

```
    dependencies: [
        .package(url: "https://github.com/HumeAI/hume-swift-sdk.git", from: "x.x.x")
    ]
```

## Usage

The SDK provides a `VoiceProvider` abstraction that you can use to directly integrate
with microphones. 

```swift
import Hume


let voiceProvider = VoiceProvider(
    apiKey: "YOUR_API_KEY",
    clientSecret: "YOUR_CLIENT_SECRET")

voiceProvider.onMessage = { event in
    // Optional handling of the SubscribeEvent. Maybe render in a List
}


// Request permission to record audio. Be sure to add `Privacy - Microphone Usage Description`
// to your Info.plist
AVAudioApplication.requestRecordPermission { granted in
    if granted {
        Task {
            try await voiceProvider.connect()
        }
    }   
}


// Sending user text input
await self.voiceProvider.sendUserInput(message: "Hey, how are you?")
```

## Client Library

The SDK exposes a raw client library that you can use to interface directly with the 
empathic voice WebSocket. 

```swift
var hume = HumeClient(apiKey: "key", clientSecret: "secret")

let socket = try await self.humeClient.empathicVoice.chat
    .connect(
        onOpen: { response in
            print("Socket Opened")
        },
        onClose: { closeCode, reason in
            print("Socket Closed: \(closeCode). Reason: \(String(describing: reason))")
        },
        onError: { error, response in
            print("Socket Errored: \(error). Response: \(String(describing: response))")
        }
    )

await socket?.sendTextInput(text: "message")
```

## Beta Status
This SDK is in beta, and there may be breaking changes between versions without a major 
version update. Therefore, we recommend pinning the package version to a specific version. 
This way, you can install the same version each time without breaking changes.
