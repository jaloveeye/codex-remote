# iOS Emulator Launch Record
- Date: 2026-03-11
- User Request: Launch iPhone 11 Pro Max and iPad Pro 13-inch (M4) simulators first for iOS deployment/screenshot prep.

## Commands run
1. `xcrun simctl list devices`
2. `xcrun simctl boot 2A4F7E06-649D-4D2F-895A-14847405D07C`
3. `xcrun simctl boot AC206DBD-7352-4A4C-A136-A2C8924A1C45`
4. `xcrun simctl list devices | awk '/iPhone 11 Pro Max|iPad Pro 13-inch \(M4\)/ {print}'`

## Launch result (running)
- `iPhone 11 Pro Max - Listo` -> `2A4F7E06-649D-4D2F-895A-14847405D07C` **Booted**
- `iPad Pro 13-inch (M4)` -> `AC206DBD-7352-4A4C-A136-A2C8924A1C45` **Booted**

## Notes
- iPhone device name in local simulator list is `iPhone 11 Pro Max - Listo` (with suffix `- Listo`), so that exact UDID was used.
- Simulator app launch command was executed (`open -a Simulator`) in the same flow.
