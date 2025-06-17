//
//  Inference.swift
//
//
//  Created by Daniel Rees on 5/19/24.
//

import Foundation


public struct Inference: Codable {
    public let prosody: ProsodyInference?

    public init(prosody: ProsodyInference?) {
        self.prosody = prosody
    }
}
