struct ProviderCredentials {
    let openAIKey: String
    let anthropicKey: String

    init(appState: AppState) {
        openAIKey = appState.openAIAPIKey
        anthropicKey = appState.apiKey
    }
}
