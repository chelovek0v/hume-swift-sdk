//
//  AudioConfiguration.swift
//
//
//  Created by Daniel Rees on 5/19/24.
//

import Foundation

public struct AudioConfiguration: Codable {
  /** Number of channels. */
  public let channels: Int
  /** Audio encoding. */
  public let encoding: Encoding
  /** Audio sample rate. */
  public let sampleRate: Int

  public init(channels: Int, encoding: Encoding, sampleRate: Int) {
    self.channels = channels
    self.encoding = encoding
    self.sampleRate = sampleRate
  }

}
