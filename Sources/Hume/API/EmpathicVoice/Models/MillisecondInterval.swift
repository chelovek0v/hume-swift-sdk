//
//  MillisecondInterval.swift
//
//
//  Created by Daniel Rees on 5/19/24.
//

import Foundation

public struct MillisecondInterval: Codable {

  /** Start time of the interval in milliseconds. */
  public let begin: Int

  /** End time of the interval in milliseconds. */
  public let end: Int

  public init(begin: Int, end: Int) {
    self.begin = begin
    self.end = end
  }
}
