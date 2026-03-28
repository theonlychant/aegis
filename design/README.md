Aegis iOS UI design assets

Summary

We need a modern, privacy-first iOS application UI for Aegis that exposes and safely controls the native scanning engine (XCFramework). The UI should be approachable for non-technical users while giving advanced options for power users and administrators.

This folder contains a short design brief, token file, and a minimal SwiftUI prototype to seed development and discussion. These files were added as a starting point for issue #5: https://github.com/1proprogrammerchant/aegis/issues/5

Deliverables in this commit

- `tokens.json` - minimal design tokens (colors, typography, spacing)
- `prototypes/` - SwiftUI prototype files (HomeView) under the ios-app sources
- This README includes helpful resources and next steps.

Resources

- Apple Human Interface Guidelines (HIG): https://developer.apple.com/design/human-interface-guidelines/
- SwiftUI documentation: https://developer.apple.com/documentation/swiftui
- Accessibility: https://developer.apple.com/accessibility/
- Figma community: https://www.figma.com/community

Next steps

- Create Figma mockups for the screens listed in issue #5.
- Expand design tokens into a full component library.
- Implement the SwiftUI prototype into the `ios-app` target and wire to the Swift XCFramework wrapper.
