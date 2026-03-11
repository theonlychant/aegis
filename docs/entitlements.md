Entitlement request guidance

Steps to request entitlements and prepare for App Store / enterprise distribution:

1. Developer account prep
   - Ensure your Apple Developer Team has access to the "Capabilities" in the App ID.
   - For Network Extension features (content filter, packet tunnel, URL filtering) you must request the entitlement from Apple via a support/entitlement request form; include your use case and security/privacy documentation.

2. Required entitlements (common)
   - `com.apple.developer.networking.networkextension` — base NE entitlement
   - `com.apple.developer.networking.networkextension.filter` — content filter (NEFilterDataProvider)
   - `com.apple.developer.networking.vpn.api` — packet-tunnel / VPN modes (NEPacketTunnelProvider)
   - `com.apple.developer.networking.networkextension.url-filtering` — iOS 26+ URL filter features (where available)

3. App Attest / DeviceCheck
   - App Attest and DeviceCheck do not require special entitlements but require server-side verification and proper provisioning to use correctly.

4. App Store notes
   - Document exactly how the app behaves: which network flows are inspected, what telemetry is sent, and how users opt out.
   - Provide Apple with sample binaries and a clear security/privacy justification when requesting NE entitlements.

5. Enterprise / MDM
   - For managed devices, supervised mode and MDM can simplify deployment and allow additional enforcement options.

6. Testing
   - Use a dedicated test team ID to request entitlements for staging before production submission.

This document is a guidance template; follow Apple's official docs and the Developer Support process for final requests.
