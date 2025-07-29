//
//  EviConfig.swift
//  HumeAI2
//
//  Created by Chris on 11/19/24.
//

import Foundation

public enum EviVersion: String, Codable, CaseIterable {
  case v2 = "2"
  case v3 = "3"
}

struct EviConfig: Codable {
  let id: String
  let name: String
  let eviVersion: EviVersion
  let versionDescription: String?
  let version: Int
  let createdOn: Date
  let modifiedOn: Date
  let prompt: Prompt?
  let languageModel: LanguageModel?
  let voice: Voice?
  let tools: [EviTool]?
  let builtinTools: [BuiltinTool]?

  enum CodingKeys: String, CodingKey {
    case id, name, version, prompt, voice, tools
    case eviVersion = "evi_version"
    case versionDescription = "version_description"
    case createdOn = "created_on"
    case modifiedOn = "modified_on"
    case languageModel = "language_model"
    case builtinTools = "builtin_tools"
  }

  struct Prompt: Codable {
    let id: String
    let version: Double
    let text: String
  }

  struct LanguageModel: Codable {
    let modelProvider: String
    let modelResource: String
    let temperature: Double?

    enum CodingKeys: String, CodingKey {
      case modelProvider = "model_provider"
      case modelResource = "model_resource"
      case temperature
    }
  }

  struct Voice: Codable {
    enum Provider: String, Codable {
      case custom = "CUSTOM_VOICE"
      case hume = "HUME_AI"
    }

    let name: String
    let provider: Provider
    let id: String?

    static func custom(id: String, name: String) -> Voice {
      Voice(name: name, provider: .custom, id: id)
    }

    static func hume(id: String, name: String) -> Voice {
      Voice(name: name, provider: .hume, id: id)
    }
  }

  struct EviTool: Codable {
    let id: String
    let version: Double
  }

  struct BuiltinTool: Codable {
    let name: String
    let fallbackContent: String?

    enum CodingKeys: String, CodingKey {
      case name
      case fallbackContent = "fallback_content"
    }
  }
}

// MARK: - Mocking

extension EviConfig {
  static var mock: EviConfig {
    EviConfig(
      id: "mock-id",
      name: "Mock Evi Config",
      eviVersion: .v3,
      versionDescription: "This is a mock version description.",
      version: 1,
      createdOn: Date(),
      modifiedOn: Date(),
      prompt: Prompt(
        id: "prompt-mock-id",
        version: 1.0,
        text: "Mock prompt text."
      ),
      languageModel: LanguageModel(
        modelProvider: "MockProvider",
        modelResource: "mock-resource",
        temperature: 0.7
      ),
      voice: Voice(
        name: "MockVoice",
        provider: .custom,
        id: nil
      ),
      tools: [
        EviTool(id: "tool-mock-id-1", version: 1.0),
        EviTool(id: "tool-mock-id-2", version: 2.0),
      ],
      builtinTools: [
        BuiltinTool(name: "BuiltinToolMock1", fallbackContent: "Fallback content 1"),
        BuiltinTool(name: "BuiltinToolMock2", fallbackContent: nil),
      ]
    )
  }
}
