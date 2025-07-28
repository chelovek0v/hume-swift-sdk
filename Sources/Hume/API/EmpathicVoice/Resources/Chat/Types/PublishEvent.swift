//
//  File.swift
//
//
//  Created by Daniel Rees on 5/19/24.
//

import Foundation

public enum PublishEvent {
  case audioInput(AudioInput)
  case sessionSettings(SessionSettings)
  case userInput(UserInput)
  case assistantInput(AssistantInput)
  case toolResponseMessage(ToolResponseMessage)
  case toolErrorMessage(ToolErrorMessage)
  case pauseAssistantMessage(PauseAssistantMessage)
  case resumeAssistantMessage(ResumeAssistantMessage)
}
