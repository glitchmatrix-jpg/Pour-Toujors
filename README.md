# Pour Toujours

**Different hours. Same family.**

Pour Toujours is a privacy-first Flutter family companion for people living across time zones. It combines local time, family routines, weather context, birthdays, and holidays without live location tracking or activity surveillance.

The first private family circle is **Famile pour tojours**, spanning Karachi, Chiba, Dublin, and Hattiesburg.

## Product principles

- See their world, not their whereabouts.
- Useful even when only one family member installs it.
- Home city, never background GPS.
- Every availability label includes a reason and confidence level.
- Uncertainty is shown honestly instead of being disguised as a live status.
- WhatsApp remains the communication layer; Pour Toujours provides context before contact.
- Premium, atmospheric design rather than a clock dashboard.

## Current prototype

The v0.2 Flutter prototype includes:

- cinematic family-horizon opening screen
- live timezone-aware city clocks
- fourteen family routine profiles
- five honest availability states
- confidence and explanation panels for every status
- original SVG city artwork for Karachi, Chiba, Dublin, and Hattiesburg
- grouped city windows
- current-call guidance
- privacy-first trust language

## Run locally

```powershell
cd "$HOME\Documents\Pour-Toujors"
git switch agent/initial-product-foundation
git pull
flutter pub get
flutter analyze
flutter run -d chrome
```

For Android, generate or retain the Android platform folder and run against a connected device or emulator.

## Next milestones

1. Validate and refine v0.2 on phone-sized Android screens.
2. Build the interactive 24-hour family overlap timeline.
3. Add profile and routine editing.
4. Integrate weather and public-holiday providers with caching.
5. Add private accounts and claimed-profile controls.
6. Build native Android and iOS widgets.
