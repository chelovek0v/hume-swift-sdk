//
//  AssistantMessageTest.swift
//
//
//  Created by Daniel Rees on 5/22/24.
//

import XCTest

@testable import Hume

final class AssistantMessageTest: XCTestCase {

  let decoder = Defaults.decoder

  func test_decodesUserMessage() throws {
    let json = """
      {
         "type": "assistant_message",
         "id": "794c0ea42010401f83dcc3fdede826f9",
         "message": {
            "role": "assistant",
            "content": "Hey there!"
         },
         "models": {
            "prosody": {
               "scores": {
                  "Admiration": 0.041015625,
                  "Adoration": 0.028717041015625,
                  "Aesthetic Appreciation": 0.024932861328125,
                  "Amusement": 0.1102294921875,
                  "Anger": 0.05780029296875,
                  "Anxiety": 0.05999755859375,
                  "Awe": 0.02886962890625,
                  "Awkwardness": 0.052398681640625,
                  "Boredom": 0.035797119140625,
                  "Calmness": 0.073486328125,
                  "Concentration": 0.023345947265625,
                  "Confusion": 0.0306396484375,
                  "Contemplation": 0.00746917724609375,
                  "Contempt": 0.0225982666015625,
                  "Contentment": 0.057403564453125,
                  "Craving": -9.870529174804688E-4,
                  "Desire": 6.337165832519531E-4,
                  "Determination": 0.06658935546875,
                  "Disappointment": 0.0374755859375,
                  "Disgust": 0.0164947509765625,
                  "Distress": 0.08782958984375,
                  "Doubt": 0.01363372802734375,
                  "Ecstasy": 0.0236053466796875,
                  "Embarrassment": 0.0012798309326171875,
                  "Empathic Pain": 0.01326751708984375,
                  "Entrancement": 0.014923095703125,
                  "Envy": 0.00847625732421875,
                  "Excitement": 0.2425537109375,
                  "Fear": 0.03448486328125,
                  "Guilt": 0.005046844482421875,
                  "Horror": 0.0189666748046875,
                  "Interest": 0.14208984375,
                  "Joy": 0.1202392578125,
                  "Love": 0.0279388427734375,
                  "Nostalgia": 0.013641357421875,
                  "Pain": 0.0174407958984375,
                  "Pride": 0.035003662109375,
                  "Realization": 0.041595458984375,
                  "Relief": 0.03594970703125,
                  "Romance": 0.00943756103515625,
                  "Sadness": 0.018157958984375,
                  "Satisfaction": 0.073974609375,
                  "Shame": 0.0011377334594726562,
                  "Surprise (negative)": 0.05474853515625,
                  "Surprise (positive)": 0.13671875,
                  "Sympathy": 0.0099029541015625,
                  "Tiredness": 0.0099945068359375,
                  "Triumph": 0.0307159423828125
               }
            }
         },
         "from_text": false
      }
      """

    let message = try! decoder.decode(SubscribeEvent.self, from: json.data(using: .utf8)!)
    guard case SubscribeEvent.assistantMessage(let assistantMessage) = message else { fatalError() }

    XCTAssertEqual(assistantMessage.type, "assistant_message")
    XCTAssertEqual(assistantMessage.id, "794c0ea42010401f83dcc3fdede826f9")
    XCTAssertEqual(assistantMessage.message.role, Role.assistant)
    XCTAssertEqual(assistantMessage.message.content, "Hey there!")
  }

}
