# iOS Widget — one-time Xcode setup

The widget's source is complete in this repo (`ios/NuptialWidget/`), but Xcode
project targets cannot be safely authored by hand, so the extension target must
be added once in Xcode on a Mac. Five minutes, one time; after this every
build (local and Codemagic) includes the widget.

## Steps

1. Open `ios/Runner.xcworkspace` in Xcode.
2. **File → New → Target… → Widget Extension.**
   - Product Name: `NuptialWidget` (exactly — the Flutter side reloads
     timelines by this kind string).
   - Bundle id should become `au.com.bitbot.nuptialflight.NuptialWidget`.
   - Untick "Include Configuration App Intent" / intent options.
   - Don't activate the scheme when prompted if asked about running it.
3. Xcode generates a `NuptialWidget` group with boilerplate Swift and
   Info.plist. **Delete the generated files** and add the repo's files to the
   target instead: `ios/NuptialWidget/NuptialWidget.swift` and
   `ios/NuptialWidget/Info.plist` (set the target's Info.plist path to
   `NuptialWidget/Info.plist` under Build Settings → Packaging).
4. **App Groups** (both targets must share `group.au.com.bitbot.nuptialflight`):
   - Runner target → Signing & Capabilities → + Capability → App Groups →
     add `group.au.com.bitbot.nuptialflight`. The repo already contains
     `ios/Runner/Runner.entitlements`; point Code Signing Entitlements at it
     if Xcode created a different file.
   - NuptialWidget target → same capability, same group. Entitlements file:
     `ios/NuptialWidget/NuptialWidget.entitlements`.
   - The App Group must also exist in the Apple Developer portal for the
     `au.com.bitbot.*` identifiers (Xcode's automatic signing will offer to
     register it).
5. Set the widget target's iOS Deployment Target to 14.0 (or the Runner's
   minimum, whichever is higher).
6. Build Runner once (`flutter build ios` or Xcode ⌘B). Commit the
   `project.pbxproj` changes Xcode made.

## How it works

- Flutter publishes the percentage via `home_widget`
  (`lib/controller/widgets_mobile.dart`): `saveWidgetData('_percentage', …)`
  into the App Group, then `updateWidget(iOSName: 'NuptialWidget')` which asks
  WidgetKit to reload the timeline.
- `NuptialWidget.swift` reads `_percentage` from the App Group's UserDefaults
  and renders the same emoji ladder and severity palette as the Android widget
  (`AppWidgetProvider.kt`) — thresholds and colours are mirrored comments in
  both files; change one, change both.

## Codemagic note

After the target exists in `project.pbxproj`, the existing
`flutter build ipa` step builds the extension automatically. Automatic code
signing must be allowed to manage the extra bundle id
(`au.com.bitbot.nuptialflight.NuptialWidget`) and the App Group.
