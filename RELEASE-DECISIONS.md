# Kitchen Prep Board — Locked Android 1.0 Release Decisions

Recorded: 24 August 2026

These owner decisions are the release baseline unless explicitly changed later.

## Publisher / contact

- Operator: **Lateef Razaq-Oyetola carrying on business as GoodUse Studios**
- Mailing address: **36 Zorra Street, Toronto (Etobicoke), Ontario M8Z 0G5, Canada**
- Privacy/support email: **lrodeveloperr@gmail.com**
- Normal support-email retention: **24 months after closure/last substantive activity**, with longer retention only where legitimately required.

## Platform / version

- Android launches first.
- Public Android versionName: **1.0.0**.
- Verify the next unused integer versionCode in Play immediately before production upload.
- iOS is not a blocker for Android launch and is not yet store-ready.

## Audience

- Android 1.0 is intended for **16+**.
- Neutral date-of-birth screen appears before UMP, Billing connection, or Mobile Ads initialization.
- Exact date of birth is not persisted; only the derived category is stored locally.
- Under 16: blocked from Android 1.0.
- 16–17: `TEEN` Google Mobile Ads age-restricted treatment; no personalized ads.
- 18+: adult/unspecified age-restricted treatment; UMP and applicable regional privacy choices control advertising mode.
- Play target-audience/Families declarations must be verified because Play notes that 16–17 may be treated as children in some locales.

## Advertising

- Free version uses a persistent anchored banner.
- No interstitials in active prep/timer workflow for Android 1.0.
- Banner space is reserved before ad load to prevent layout shift.
- A non-interactive gap separates banner from navigation/actions.
- Maximum ad content rating: Teen (`T`) or stricter for Android 1.0.
- Production AdMob IDs will be supplied only after owner phone/tablet QA.
- Development/demo AdMob IDs must be rejected by production validation.
- Do not force `npa=1` for adults; adult treatment follows UMP/regional rules. Teen treatment remains non-personalized.

## Diagnostics / analytics

- No Firebase Analytics in Android 1.0.
- No Firebase Crashlytics in Android 1.0.
- Use Google Play **Android vitals** for Play-provided crash/ANR reporting.
- Adding any analytics/crash SDK later requires a fresh Privacy Policy + Data safety + SDK inventory review.

## Subscription

- Android may offer an auto-renewing remove-ads subscription.
- Exact product/base-plan IDs, billing period, pricing strategy and any trial/intro offer remain to be confirmed.
- Production UI must display Google Play’s current localized price and billing period before purchase; no hard-coded price.

## Privacy / legal site

- Policies must be public HTTPS pages, accessible without login and not PDF-only.
- Recommended free host: a public GitHub Pages repository named `kitchen-prep-board-legal`.
- Effective policies will include provider identity, mailing address, support email, age treatment, AdMob/UMP, Google Play Billing, 24-month support retention, Android vitals, local data deletion, food-safety boundary and country/representative disclosures.

## Representative strategy / country availability

- Owner will pay for **one provider** that can cover EU/EEA + UK representation if required.
- Current low-cost candidate: DataRep, subject to consultation and formal appointment.
- Countries outside EEA/UK that create an additional local representative obligation for this release model are excluded from Android 1.0.
- `COUNTRY-AVAILABILITY.md` is the controlling release-country review file.
- Do not advertise a fixed country count until the final Play Console country list has been selected and counted.

## Play account

- Play developer account type: **personal**.
- Account creation date / current Production access still must be confirmed to determine whether the 12-testers-for-14-days production-access rule applies.

## Release blockers still requiring owner input

1. Play personal-account creation date **or** confirmation Production access is already granted.
2. Public `kitchen-prep-board-legal` repo/domain.
3. EU/EEA + UK representative details after appointment.
4. Production AdMob Android app ID and banner ID after device QA.
5. Final remove-ads subscription configuration (product/base plan, period, pricing strategy, trial/intro offer or none).
6. Next unused Play versionCode if versionCode 3 has already been uploaded.

All earlier owner-information items are resolved.