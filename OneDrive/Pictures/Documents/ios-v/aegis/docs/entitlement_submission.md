Entitlement submission and App Store guidance

Checklist

- Prepare detailed justification for Network Extension usage, content filtering, and VPN if used.
- Prepare a short demo video showing the app exercising the NE features and the UI flows.
- Provide an App Store review note describing how user data is processed and privacy controls.
- Ensure privacy policy explicitly documents telemetry and opt-in flows.
- Attach the `.entitlements` files and mention the Team ID and bundle IDs in the request.

When requesting NE entitlements from Apple

- Use Apple Developer support to submit an entitlement request; include the use case, screenshots, and a demo account.
- For content filter / URL filtering, show how the app blocks/filters and explain fallback when entitlement is not granted.

Enterprise / MDM testing

- For supervised devices, verify behavior with an MDM server and document MDM payloads.
- Test on a supervised device and include logs and step-by-step test plan for Apple if requested.

Notes

- Apple may require additional information or a limited demo build. Keep a staging Team/Account for entitlement testing.
