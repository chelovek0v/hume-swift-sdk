//
//  SessionSettings.swift
//
//
//  Created by Daniel Rees on 5/19/24.
//

import Foundation


public struct SessionSettings: Codable {
    public let customSessionId: String?
    public let audio: AudioConfiguration?
    public let languageModelApiKey: String?
    public let systemPrompt: String?
    public let type: String
    public let tools: [Tool]?
    public let variables: [String: String]
    
    public init(
        customSessionId: String?,
        audio: AudioConfiguration?,
        languageModelApiKey: String?,
        systemPrompt: String?,
        tools: [Tool]?,
        variables: [String: String] = [:]
    ) {
        self.customSessionId = customSessionId
        self.audio = audio
        self.languageModelApiKey = languageModelApiKey
        self.systemPrompt = systemPrompt
        self.type = "session_settings"
        self.tools = tools
        self.variables = variables
    }
}

public extension SessionSettings {
    static func withAudioConfiguration(
        _ audioConfiguration: AudioConfiguration,
        customSessionId: String? = nil,
        languageModelApiKey: String? = nil,
        systemPrompt: String? = nil,
        tools: [Tool]? = nil,
        variables: [String: String] = [:]) -> SessionSettings {
        return SessionSettings(customSessionId: customSessionId,
                               audio: audioConfiguration,
                               languageModelApiKey: languageModelApiKey,
                               systemPrompt: systemPrompt,
                               tools: tools,
                               variables: variables)
    }
}
