import XCTest
@testable import SpeechToTextApp

final class CredentialsTests: XCTestCase {
    func testOpenAIAndAnthropicKeysRemainIndependent() {
        let appState = AppState()
        let previousAnthropicKey = appState.apiKey
        let previousOpenAIKey = KeychainHelper.retrieve(key: Constants.Keychain.openaiAPIKeyKey)
        defer {
            appState.apiKey = previousAnthropicKey
            if let previousOpenAIKey {
                appState.openAIAPIKey = previousOpenAIKey
            } else {
                KeychainHelper.delete(key: Constants.Keychain.openaiAPIKeyKey)
            }
        }

        appState.apiKey = "anthropic-test-only"
        appState.openAIAPIKey = "openai-test-only"

        XCTAssertEqual(appState.apiKey, "anthropic-test-only")
        XCTAssertEqual(appState.openAIAPIKey, "openai-test-only")
        XCTAssertEqual(
            KeychainHelper.retrieve(key: Constants.Keychain.openaiAPIKeyKey),
            "openai-test-only"
        )
        XCTAssertEqual(KeychainHelper.retrieve(key: Constants.Keychain.apiKeyKey), "anthropic-test-only")
    }
}
