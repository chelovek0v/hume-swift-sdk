//
//  VoiceProviderDelegate.swift
//  Hume
//
//  Created by Chris on 6/12/25.
//

import Foundation

public protocol VoiceProviderDelegate: AnyObject {
    func voiceProvider(_ voiceProvider: any VoiceProvidable, didProduceEvent event: SubscribeEvent)
    func voiceProvider(_ voiceProvider: any VoiceProvidable, didProduceError error: VoiceProviderError)
    /// Handler for meter data from the microphone. Note: This is disabled. TODO: make it configurable to set this
    func voiceProvider(_ voiceProvider: any VoiceProvidable, didReceieveAudioInputMeter audioInputMeter: Float)
    func voiceProvider(_ voiceProvider: any VoiceProvidable, didReceieveAudioOutputMeter audioInputMeter: Float)
    func voiceProviderDidDisconnect(_ voiceProvider: any VoiceProvidable)
    /// Called when the provider has connected and is ready for use.
    func voiceProviderDidConnect(_ voiceProvider: any VoiceProvidable)
    /// Called when a sound clip is played.
    func voiceProvider(_ voiceProvider: any VoiceProvidable, didPlayClip clip: SoundClip)
}
