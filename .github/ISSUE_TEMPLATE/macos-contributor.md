**Title**: macOS contributor needed for iOS builds, tests, and signing

**Summary**
We need a contributor with access to a macOS machine (physical or macOS-hosted CI) to support iOS builds, Xcode-based CI jobs, and optional code signing/provisioning. The repository's CI now attempts to run Xcode builds and generate the app/XCFrameworks; these steps require macOS tooling and sometimes an Apple Developer account for signing.

**What we need from you**
- A macOS machine (local macOS or access to a macOS-hosted CI) with:
  - Xcode 16.4+ (or the Xcode version used by our CI) and Command Line Tools installed
  - Homebrew available (optional but helpful)
  - Ability to run `xcodebuild`, `xcodegen` (if generating project), `pod`/`carthage` if required
- Ability to run the CI macOS job locally or verify our GitHub Actions `macos-latest` runner results
- (Optional, but helpful) An Apple Developer account (team access) to help with provisioning profiles and signing when generating release-signed builds
- Comfort with running the following commands in the repo root and reporting back errors/logs:
  - `xcodebuild -project ios-app/<Project>.xcodeproj -scheme <Scheme> -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 14' clean build test`
  - `brew install xcodegen && xcodegen generate` (we include `ios-app/project.yml` in the repo)
  - `./scripts/build_rust_ios.sh && ./scripts/create_xcframework.sh` to produce the bundled native engine XCFramework

**What we will provide**
- A GitHub repo access (push/PR) and clear instructions for running the required build steps
- Guidance on which Xcode project/scheme names to use and which simulator/device targets we expect
- Test accounts, device identifiers or feature flags as needed to exercise CI tests
- Assistance with logs, reproductions and triage (I'll be available to pair-debug)

**Security & secrets**
- We will not ask you to share Apple credentials publicly. If signing/provisioning is needed in CI, we'll provide encrypted GitHub Actions secrets (we will require someone with access to set them in the repo settings).

**Expected availability & deliverables**
- One-time: validate and stabilize macOS CI job to succeed on `macos-latest` (or document required Xcode version)
- Ongoing (optional): run manual builds for release artifacts (XCFrameworks, signed builds) and help update CI as Xcode versions change

**How to respond**
Please reply with:
- Your availability (hours per week)
- Whether you have an Apple Developer Team/Account available (yes/no)
- macOS version and Xcode version(s) you can test with
- Any preferences about how you'd like to receive repo access (invite, fork/PR workflow)

Thank you — add any extra notes or constraints you need.
