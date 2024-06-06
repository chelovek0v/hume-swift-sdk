import XCTest
@testable import Hume

final class HumeClientTests: XCTestCase {
    
    var client: HumeClient!
    
    override func setUp() {
        self.client = HumeClient(apiKey: "key", clientSecret: "secret")
    }
    
    
    func test_empatheticVoice_returnsLazily() throws {
        let voice1 = self.client.empatheticVoice
        let voice2 = self.client.empatheticVoice
        
        XCTAssertTrue(voice1 === voice2)
    }
}
