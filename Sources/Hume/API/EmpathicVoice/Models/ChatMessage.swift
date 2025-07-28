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

  public init(
    content: String?,
    role: Role,
    toolCall: ToolCallMessage?,
    toolResult: ChatMessageToolResult?
  ) {
    self.content = content
    self.role = role
    self.toolCall = toolCall
    self.toolResult = toolResult
  }
}
