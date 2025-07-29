//
//  File.swift
//
//
//  Created by Daniel Rees on 5/20/24.
//

import Foundation

struct AuthorizationToken: Codable {

  let tokenType: String
  let accessToken: String
  let grantType: String
  let issuedAt: Int
  let expiresIn: Int
}
