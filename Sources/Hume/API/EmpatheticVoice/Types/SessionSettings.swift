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
    
    public init(
        customSessionId: String?,
        audio: AudioConfiguration?,
        languageModelApiKey: String?,
        systemPrompt: String?,
        tools: [Tool]?
    ) {
        self.customSessionId = customSessionId
        self.audio = audio
        self.languageModelApiKey = languageModelApiKey
        self.systemPrompt = systemPrompt
        self.type = "session_settings"
        self.tools = tools
    }
    
    
    
}
