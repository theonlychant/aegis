import NetworkExtension

class ContentFilterProvider: NEFilterDataProvider {
    override func handleNewFlow(_ flow: NEFilterFlow) -> NEFilterNewFlowVerdict {
        // Placeholder: consult local cache or backend for verdicts
        return .allow()
    }

    override func handleInboundData(from flow: NEFilterFlow, readBytesStart offset: Int, readBytes: Data, completionHandler: @escaping (NEFilterDataVerdict?) -> Void) {
        completionHandler(.allow())
    }
}
