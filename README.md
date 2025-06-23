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

let token = try await myAccessTokenClient.fetchAccessToken()
humeClient = HumeClient(options: .accessToken(token: token))

let voiceProvider = VoiceProvider(client: humeClient)
voiceProvider.delegate = myDelegate

// Request permission to record audio. Be sure to add `Privacy - Microphone Usage Description`
// to your Info.plist
let granted = await MicrophonePermission.requestPermissions()
guard granted else { return }

let sessionSettings = SessionSettings(
    systemPrompt: "my optional system prompt",
    variables: ["myCustomVariable": myValue, "datetime": Date().formattedForSessionSettings()])

try await voiceProvider.connect(
    configId: myConfigId,
    configVersion: nil,
    sessionSettings: sessionSettings)

// Sending user text input manually
await self.voiceProvider.sendUserInput(message: "Hey, how are you?")
```

### Listening for VoiceProvider updates
Implement `VoiceProviderDelegate` methods to be notified of events, errors, meter data, state, etc.  


## Beta Status
This SDK is in beta, and there may be breaking changes between versions without a major 
version update. Therefore, we recommend pinning the package version to a specific version. 
This way, you can install the same version each time without breaking changes.
