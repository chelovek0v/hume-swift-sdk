//
//  HumeClient.swift
//
//
//  Created by Daniel Rees on 5/17/24.
//

import Foundation


public class HumeClient {
    
    struct Options {
        let apiKey: String
        let clientSecret: String
    }
    
    private let options: HumeClient.Options
    
    public init(apiKey: String, clientSecret: String) {
        self.options = HumeClient.Options(
            apiKey: apiKey,
            clientSecret: clientSecret)
    }
    
    public lazy var empatheticVoice: EmpatheticVoice = {
        return EmpatheticVoice(options: options)
    }()
}
