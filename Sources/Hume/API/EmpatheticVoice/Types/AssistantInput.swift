//
//  AssistantInput.swift
//
//
//  Created by Daniel Rees on 5/19/24.
//

import Foundation

/**
 * When provided, the input is spoken by EVI.
 */
public struct AssistantInput: Codable {
    public let customSessionId: String?
    /** Text to be synthesized. */
    public let text: String
    public let type: String
    
    public init(text: String, customSessionId: String? = nil) {
        self.customSessionId = customSessionId
        self.text = text
        self.type = "assistant_input"
    }
}
