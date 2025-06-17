//
//  HumeClient.swift
//
//
//  Created by Daniel Rees on 5/17/24.
//

import Foundation


public class HumeClient {
    public enum Options {
        /// Use an access token with the Hume APIs
        case accessToken(token: String)
    }
    
    private let options: HumeClient.Options

    public init(options: Options) {
        self.options = options
    }
    
    public lazy var empathicVoice: EmpathicVoice = {
        return EmpathicVoice(options: options)
    }()
}
