//
//  Tool.swift
//
//
//  Created by Daniel Rees on 5/19/24.
//

import Foundation

public struct Tool: Codable {
  /** Type of tool. */
  public let type: ToolType
  /** Name of the function. */
  public let name: String
  /** Parameters of the function. Is a stringified JSON schema. */
  public let parameters: String
  public let description: String?
  public let fallbackContent: String?

  public init(
    type: ToolType,
    name: String,
    parameters: String,
    description: String?,
    fallbackContent: String?
  ) {
    self.type = type
    self.name = name
    self.parameters = parameters
    self.description = description
    self.fallbackContent = fallbackContent
  }
}
