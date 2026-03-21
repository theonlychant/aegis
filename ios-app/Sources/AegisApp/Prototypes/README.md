Prototype components

This folder contains a minimal SwiftUI prototype screen (`HomeView.swift`) intended
as a starting point for the GUI in issue #5.

How to run

Open `ios-app` in Xcode and add the `HomeView` to the app's entry point or
instantiate it in a SwiftUI preview. This file is intentionally minimal — it
simulates scan results to demonstrate list layout, severity tagging, and a
quick-scan button.

Next steps

- Replace simulated scan calls with the Swift wrapper calls into the XCFramework.
- Add accessibility labels and test with VoiceOver.
- Expand designs into full-screen flows and wire to realistic data models.
