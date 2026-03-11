Xcode project generation using XcodeGen

We provide a `project.yml` for XcodeGen to generate an Xcode project with the app and two extension targets.

Prerequisites
- Install `xcodegen`: `brew install xcodegen`

Generate

```bash
cd ios-app
xcodegen generate
```

This will create `Aegis.xcodeproj`. Open it in Xcode, add the `xcframeworks/AegisEngine.xcframework` if you produced one, and wire up the entitlements and provisioning profiles.
