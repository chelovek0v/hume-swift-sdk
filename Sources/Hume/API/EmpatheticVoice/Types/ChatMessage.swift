//
//  File.swift
//  
//
//  Created by Daniel Rees on 5/19/24.
//

import Foundation

public struct ChatMessage: Codable {
    public let content: String?
    public let role: Role
    public let toolCall: ToolCallMessage?
    public let toolResult: ChatMessageToolResult?
}
