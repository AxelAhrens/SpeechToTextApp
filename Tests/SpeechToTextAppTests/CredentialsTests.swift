import XCTest
@testable import SpeechToTextApp

final class CredentialsTests: XCTestCase {
    func testOpenAIAndAnthropicKeysRemainIndependent() {
        let anthropicAccount = "test-anthropic-\(UUID().uuidString)"
        let openAIAccount = "test-openai-\(UUID().uuidString)"
        defer {
            KeychainHelper.delete(key: anthropicAccount)
            KeychainHelper.delete(key: openAIAccount)
        }
        let appState = AppState(
            anthropicKeyAccount: anthropicAccount,
            openAIKeyAccount: openAIAccount
        )

        appState.apiKey = "anthropic-test-only"
        appState.openAIAPIKey = "openai-test-only"

        XCTAssertEqual(appState.apiKey, "anthropic-test-only")
        XCTAssertEqual(appState.openAIAPIKey, "openai-test-only")
        XCTAssertEqual(
            KeychainHelper.retrieve(key: openAIAccount),
            "openai-test-only"
        )
        XCTAssertEqual(KeychainHelper.retrieve(key: anthropicAccount), "anthropic-test-only")

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
