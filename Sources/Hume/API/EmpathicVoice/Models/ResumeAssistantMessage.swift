//
//  ResumeAssistantMessage.swift
//
//
//  Created by Daniel Rees on 6/2/24.
//

import Foundation

public struct ResumeAssistantMessage: Codable {

  public let customSessionId: String?
  public let type: String

  public init(customSessionId: String? = nil) {
    self.customSessionId = customSessionId
    self.type = "resume_assistant_message"
  }
}
