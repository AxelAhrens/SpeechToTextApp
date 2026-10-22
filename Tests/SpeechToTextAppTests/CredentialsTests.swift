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

        let credentials = ProviderCredentials(appState: appState)
        XCTAssertEqual(credentials.openAIKey, "openai-test-only")
        XCTAssertEqual(credentials.anthropicKey, "anthropic-test-only")
    }

    func testUpdatingExistingKeychainItemKeepsLatestValue() {
        let key = "test-keychain-update-\(UUID().uuidString)"
        defer { KeychainHelper.delete(key: key) }

        XCTAssertTrue(KeychainHelper.save(key: key, value: "first-test-value"))
        XCTAssertTrue(KeychainHelper.save(key: key, value: "second-test-value"))
        XCTAssertEqual(KeychainHelper.retrieve(key: key), "second-test-value")
    }
}
