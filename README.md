# Pour Toujours

**Different hours. Same family.**

Pour Toujours is a privacy-first family companion for people living across time zones. It helps a family understand local time, weather, holidays, birthdays, and sensible contact windows—without live location tracking or activity surveillance.

The first private family circle is **Famile pour tojours**, spanning Karachi, Chiba, Dublin, and Hattiesburg.

## Product principles

- See their world, not their whereabouts.
- Useful even when only one family member installs it.
- Home city, never background GPS.
- Availability is an explained estimate, never a tracked status.
- WhatsApp remains the communication layer; Pour Toujours provides context before contact.
- Calm, beautiful, glanceable design instead of a dashboard aesthetic.

## Current foundation

- Flutter + Dart
- Riverpod-ready application shell
- Material 3 base with a custom Pour Toujours design system
- fourteen seeded family profiles
- four grouped city windows
- original SVG app mark and city illustrations
- first premium Today screen

## Run locally

Install the Flutter SDK, then clone and switch to the active branch:

```bash
git clone https://github.com/glitchmatrix-jpg/Pour-Toujors.git
cd Pour-Toujors
git switch agent/initial-product-foundation
```

Generate the native platform folders once:

```bash
flutter create . --platforms=android,ios,web
flutter pub get
flutter run
```

`flutter create .` may regenerate standard project metadata, but the existing `lib/`, `assets/`, and `pubspec.yaml` contain the authored product foundation.

## Initial product scope

- Living city windows for Karachi, Chiba, Dublin, and Hattiesburg
- Local time and day
- Weather and sunrise/sunset context
- Estimated contact suitability
- Birthdays and reminders
- Public holidays and daylight-saving changes
- Family time planner
- WhatsApp shortcuts
- Home-screen widgets

## Asset policy

The first visual pack is original and stored under `assets/`. Any future photography must have documented licensing and attribution requirements before being committed.
