//
//  WebSearchToolContent.swift
//  HumeAI2
//
//  Created by Chris on 1/3/25.
//

import Foundation

struct WebSearchReference: Identifiable, Codable {
    var id: String { "\(name)_\(UUID())" }
    let name: String
    let url: String?
    let content: String?
    let opengraph: OpenGraph
    
    enum CodingKeys: String, CodingKey {
        case name
        case url
        case content
        case opengraph
    }
}

struct OpenGraph: Codable {
    let title: String?
    let image: String?
}

struct WebSearchContent: Codable {
    let summary: String?
    let references: [WebSearchReference]
}

extension WebSearchContent {
    static func from(toolResponseMessage: ToolResponseMessage) -> WebSearchContent? {
        guard let data = toolResponseMessage.content.data(using: .utf8) else {
            return nil
        }
        return try? JSONDecoder().decode(WebSearchContent.self, from: data)
    }
}
