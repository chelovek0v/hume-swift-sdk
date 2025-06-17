//
//  ProsodyInference.swift
//
//
//  Created by Daniel Rees on 5/19/24.
//

import Foundation


public struct ProsodyInference: Codable {
    public let scores: EmotionScores

    public init(scores: EmotionScores) {
        self.scores = scores
    }
}
