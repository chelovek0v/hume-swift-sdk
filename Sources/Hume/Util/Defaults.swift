//
//  Defaults.swift
//
//
//  Created by Daniel Rees on 5/22/24.
//

import Foundation

class Defaults {

  static let decoder: JSONDecoder = {
    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase

    return decoder
  }()

  static let encoder: JSONEncoder = {
    let encoder = JSONEncoder()
    encoder.keyEncodingStrategy = .convertToSnakeCase

    return encoder
  }()
}
