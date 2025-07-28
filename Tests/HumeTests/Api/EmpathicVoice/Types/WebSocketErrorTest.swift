//
//  WebSocketErrorTest.swift
//
//
//  Created by Daniel Rees on 5/24/24.
//

import XCTest

@testable import Hume

final class WebSocketErrorTest: XCTestCase {

  let decoder = Defaults.decoder

  func test_decodesUserMessage() throws {
    let json = """
      {
         "type": "error",
         "code": "I0116",
         "slug": "transcription_failure",
         "message": "Unable to transcribe audio. Please ensure that your audio is appropriately encoded."
      }
      """

    let message = try! decoder.decode(SubscribeEvent.self, from: json.data(using: .utf8)!)
    guard case SubscribeEvent.webSocketError(let error) = message else { fatalError() }

    XCTAssertEqual(error.type, "error")
    XCTAssertEqual(error.code, "I0116")
    XCTAssertEqual(error.slug, "transcription_failure")
    XCTAssertEqual(
      error.message,
      "Unable to transcribe audio. Please ensure that your audio is appropriately encoded.")
  }

}
