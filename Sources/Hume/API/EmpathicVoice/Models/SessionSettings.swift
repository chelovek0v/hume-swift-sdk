//
//  SessionSettings.swift
//
//
//  Created by Daniel Rees on 5/19/24.
//

import Foundation

/// Temporary settings applied to the current chat session.
///
/// Read more about [Session Settings](https://dev.hume.ai/docs/empathic-voice-interface-evi/configuration/session-settings) in the Hume documentation.
public struct SessionSettings: Codable {
    public let customSessionId: String?
    public let audio: AudioConfiguration?
    public let languageModelApiKey: String?
    public let systemPrompt: String?
    public let type: String
    public let tools: [Tool]?
    public let variables: [String: String]
    
    public init(
        customSessionId: String? = nil,
        audio: AudioConfiguration? = nil,
        languageModelApiKey: String? = nil,
        systemPrompt: String? = nil,
        tools: [Tool]? = nil,
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

// MARK: - SessionSettings Copy Extension
extension SessionSettings {
    func copy(
        customSessionId: String? = nil,
        audio: AudioConfiguration? = nil,
        languageModelApiKey: String? = nil,
        systemPrompt: String? = nil,
        tools: [Tool]? = nil,
        variables: [String: String]? = nil
    ) -> SessionSettings {
        return SessionSettings(
            customSessionId: customSessionId ?? self.customSessionId,
            audio: audio ?? self.audio,
            languageModelApiKey: languageModelApiKey ?? self.languageModelApiKey,
            systemPrompt: systemPrompt ?? self.systemPrompt,
            tools: tools ?? self.tools,
            variables: variables ?? self.variables
        )
    }
}
