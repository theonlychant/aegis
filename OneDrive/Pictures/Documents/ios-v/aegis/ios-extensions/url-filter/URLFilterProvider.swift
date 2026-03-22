import NetworkExtension

@available(iOS 26.0, *)
class URLFilterProvider: NEFilterControlProvider {
    // iOS 26+ URL filter stubs
    override func startFilter(completionHandler: @escaping (Error?) -> Void) {
        completionHandler(nil)
    }

    override func handleNewFlow(_ flow: NEFilterFlow) -> NEFilterNewFlowVerdict {
        return .allow()
    }
}
