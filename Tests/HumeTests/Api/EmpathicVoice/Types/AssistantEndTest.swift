//
//  AssistantEndTest.swift
//
//
//  Created by Daniel Rees on 5/22/24.
//

import XCTest

@testable import Hume

final class AssistantEndTest: XCTestCase {

  let decoder = Defaults.decoder

  func test_decodes() throws {
    let json = """
      {
         "type": "assistant_end"
      }
      """

    let message = try! decoder.decode(SubscribeEvent.self, from: json.data(using: .utf8)!)
    guard case SubscribeEvent.assistantEnd(let assistantEnd) = message else { fatalError() }

    XCTAssertEqual(assistantEnd.type, "assistant_end")
  }
}
