//
//  AudioInput.swift
//
//
//  Created by Daniel Rees on 5/19/24.
//

import Foundation

public struct AudioInput: Codable {
  let customSessionId: String?
  /** Base64 encoded audio input. */
  let data: String
  let type: String

  public init(data: String, customSessionId: String? = nil) {
    self.customSessionId = customSessionId
    self.data = data
    self.type = "audio_input"
  }

}
