//
//  HumeClient.swift
//
//
//  Created by Daniel Rees on 5/17/24.
//

import Foundation


public class HumeClient {
    public enum Options {
        case apiKey(apiKey: String, clientSecret: String)
        case accessToken(tokenProvider: () async throws -> String)
    }
    
    private let options: HumeClient.Options

    public init(options: Options) {
        self.options = options
    }
    
    public lazy var empatheticVoice: EmpatheticVoice = {
        return EmpatheticVoice(options: options)
    }()
}
