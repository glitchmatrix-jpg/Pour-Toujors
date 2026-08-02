# Availability model

Pour Toujours never presents routine-derived availability as live truth.

## Labels

- **Probably asleep** — the current local time falls outside the stated waking window.
- **Likely working** — the current local time falls inside a clearly stated work or class block.
- **Usually free** — the current local time falls inside a specifically stated free or preferred calling window.
- **May be free** — the person is probably awake, but their availability is uncertain.
- **Schedule unclear** — no entered routine covers the current time.

## Confidence

Every status also has a confidence level:

- **High-confidence routine** — directly stated work, sleep, or reliable free window.
- **Routine estimate** — probable but not guaranteed.
- **Low-confidence estimate** — deliberately cautious because the supplied routine is ambiguous.

## Interpretation recorded for v0.2

The phrase “the rest are free from 10am to 12pm” was interpreted as **10:00 AM to midnight** rather than 10:00 AM to noon, because it appeared alongside midnight sleeping times and broad daily availability. This assumption should be corrected in seed data if noon was intended.

## Privacy

The model uses only manually entered home city and routine information. It does not inspect GPS, device activity, WhatsApp presence, calendars, or background behavior.
