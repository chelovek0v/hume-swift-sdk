//
//  AccessTokenResolver.swift
//  HumeAI2
//
//  Created by Chris on 4/1/25.
//

import Foundation

internal struct AccessTokenResolver {
    internal static func resolve(options: HumeClient.Options) async throws -> String {
        try await {
            switch options {
            case .accessToken(let accessToken):
                return accessToken
            case .apiKey(let apiKey, let clientSecret):
                return try await fetchAccessToken(apiKey: apiKey, clientSecret: clientSecret)
            }
        }()
    }
    
    private static func fetchAccessToken(apiKey: String, clientSecret: String) async throws -> String {
        let authString = "\(apiKey):\(clientSecret)"
        let encoded = authString.data(using: .utf8)?.base64EncodedString()
    
        // TODO: make host configurable
        let host: String = "api.hume.ai"
        let url = URL(string: "https://\(host)/oauth2-cc/token")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.setValue("Basic \(encoded!)", forHTTPHeaderField: "Authorization")
        request.httpBody = "grant_type=client_credentials".data(using: .utf8)
        
        // TODO: Return HumeErrors instead
        let (data, _) = try await URLSession.shared.data(for: request)
    
        let token = try Defaults.decoder.decode(AuthorizationToken.self, from: data)
        return token.accessToken
    }
}
