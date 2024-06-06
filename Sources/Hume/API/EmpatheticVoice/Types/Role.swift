//
//  Role.swift
//
//
//  Created by Daniel Rees on 5/19/24.
//

import Foundation


public enum Role: String, Codable {
    case assistant
    case system
    case user
    case all
    case tool
}
