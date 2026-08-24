# Kitchen Prep Board — Android 1.0 Global Store Readiness

Review date: 24 August 2026

This is the release gate for the Android app. It uses a conservative global baseline; it does not claim that one checklist can independently certify compliance with every local law.

## Locked owner decisions

- **Platform:** Android first.
- **Public version:** `1.0.0`.
- **Provider:** Lateef Razaq-Oyetola carrying on business as GoodUse Studios.
- **Mailing address:** 36 Zorra Street, Toronto (Etobicoke), Ontario M8Z 0G5, Canada.
- **Support/privacy email:** lrodeveloperr@gmail.com.
- **Support-message normal retention:** 24 months after closure/last substantive activity, subject to legitimate longer legal/security needs.
- **Play developer account:** personal; identity verified 4 August 2026. Treat the account as subject to the current new-personal-account testing rule unless Play Console already shows Production access.
- **Audience:** adults **18+ only**.
- **Age data:** no DOB/age gate; do not collect or store date of birth.
- **Analytics:** none for Android 1.0.
- **Crash diagnostics:** Google Play Android vitals only; no Firebase Analytics/Crashlytics in Android 1.0.
- **AdMob production IDs:** deliberately deferred until owner finishes phone/tablet QA.
- **Distribution:** all otherwise eligible Play-supported countries except jurisdictions excluded under `COUNTRY-AVAILABILITY.md` because the owner does not want extra local representative appointments beyond EEA/UK representation.
- **EU/EEA + UK representation:** owner intends to purchase one commercial provider/service capable of covering both; representative details remain a release blocker until appointed and published.
- **Remove-ads model:** optional monthly auto-renewing subscription, benefit = ad removal only.
- **Locked U.S. base price:** **US$1.49/month**, no free trial or introductory offer at launch.

## Why US$1.49/month

Current market checks place simple ad-removal subscriptions around **US$0.99–$1.99/month**. Food/cooking subscriptions with materially more premium functionality are higher. Kitchen Prep Board's subscription removes ads only, so $2.99+ would be difficult to justify, while $0.99 gives up too much subscription ARPU for a long-session utility. **$1.49/month is the selected launch midpoint.**

Launch configuration is monthly only, no trial, no introductory discount, and no annual plan initially. The free app is already the product trial.

## Current technical status

- **Target API:** PASS — targetSdk 36.
- **Local-first architecture:** PASS — no account or developer-operated cloud database identified.
- **Android backup:** PASS — disabled.
- **Google UMP:** IMPLEMENTED — attaches only after app-owned first-use notice is complete.
- **Privacy choices:** IMPLEMENTED — Settings can reopen Google privacy options when required.
- **Google Play Billing:** IMPLEMENTED CLIENT-SIDE — product/base-plan configuration and Play-track testing remain required.
- **Localized subscription price display:** IMPLEMENTED — the billing controller queries the `monthly` base plan `ProductDetails` and flows Google Play's formatted price/billing period into Settings before purchase. The app does not hard-code the storefront price.
- **AdMob production IDs:** BLOCKED pending device QA/live IDs.
- **Public legal repository:** CREATED — `lrodeveloperr/kitchen-prep-board-policies-repo`; GitHub Pages still needs to be enabled/verified.
- **Native final UI:** BLOCKED — approved HTML visual/workflow source still needs final Compose port, including 31-language resources.
- **Signed release validation:** BLOCKED — final AAB, signing, install/runtime, billing, UMP and banner behavior must be tested.

## First-use flow required in native Android

No age gate. Keep first use short:

1. **Welcome** — Kitchen Prep Board; local-first; no account; adults 18+; language selection.
2. **Privacy & ads notice** — kitchen boards remain on device; Google advertising processes device/app-use information; links to Privacy and Terms. Information only, **not** a consent substitute.
3. **Three-step workflow** — Add/Paste → Tasks → Timing → Live.
4. Enter Home.

Then request device permissions only in context:

- food-safety acknowledgment before first board, not as a launch wall;
- POST_NOTIFICATIONS when the user first uses timer notifications;
- exact-alarm special access only when reliable timer behavior genuinely needs it and after explanation;
- Google UMP handles regional consent/privacy choices.

## Google Play declarations

- **Contains ads:** YES.
- **Target audience:** **18 and over only**.
- **Families:** app/store listing must not be designed or marketed to children; no child-directed ad configuration.
- **Data safety:** complete against final signed AAB using `PLAY-DATA-SAFETY-DRAFT.md` only as an aid.
- **Content rating:** complete IARC questionnaire; do not ship unrated.
- **App access:** no login/access instructions expected.
- **Health:** not a health/medical app; keep food-safety boundary explicit.
- **Financial:** not a financial app; Play Billing is only the payment mechanism.

## Advertising release gate

- Owner completes phone/tablet QA before live AdMob IDs are introduced.
- Replace Google demo IDs with production IDs; production validation must reject demo IDs.
- Configure AdMob Privacy & messaging for EEA/UK/Switzerland and relevant US-state messages.
- Android 1.0 uses normal **adult** UMP/ad treatment only.
- Do not force `npa=1` globally; adult requests follow UMP/regional rules.
- Keep maximum ad-content rating at **T (Teen)** for brand suitability unless a later review deliberately changes it.
- Keep fixed anchored banner separated from navigation/actions by a non-interactive safe gap.
- No interstitials in active prep/timer workflow for Android 1.0.
- Recheck Mobile Ads SDK disclosures against exact final SDK version.

## Crash/analytics gate

Android 1.0 includes **no Firebase Analytics and no Firebase Crashlytics**. Use Google Play **Android vitals** for Play-provided crash/ANR information. Adding any embedded analytics/crash SDK later requires Privacy Policy, Data safety and SDK-inventory review before release.

## Subscription release gate — price locked

Production configuration:

- product ID: **`remove_ads_monthly`**;
- base plan: **`monthly`**;
- billing period: **monthly auto-renewal**;
- U.S. base price: **US$1.49/month**;
- free trial: **none**;
- introductory offer: **none at launch**;
- annual plan: **none at launch**;
- benefit: removes ads while subscription is active.

Before release:

- create/activate the product/base plan in Play Console and set the U.S. base price to **US$1.49/month**;
- review Google's generated localized storefront prices and adjust selectively later if needed;
- verify the app shows Google Play's localized `ProductDetails` price and renewal period before purchase;
- provide Manage subscription;
- verify purchase, acknowledgment, reconciliation, cancellation and expiry using a Play-track build;
- do not hard-code storefront price in app UI.

## Permissions release gate

Current manifest declares INTERNET, POST_NOTIFICATIONS, RECEIVE_BOOT_COMPLETED and SCHEDULE_EXACT_ALARM.

- INTERNET: justified by ads, UMP and Play services.
- POST_NOTIFICATIONS: runtime request in timer context, not first launch.
- RECEIVE_BOOT_COMPLETED: timer recovery.
- SCHEDULE_EXACT_ALARM: special-access flow only where genuinely needed; degrade gracefully.
- Do not add USE_EXACT_ALARM unless a separate policy review confirms eligibility.

## Country availability

Use `COUNTRY-AVAILABILITY.md`. The owner wants broad Play distribution but will not appoint extra country-specific representatives outside the planned EU/EEA + UK relationship. Jurisdictions with clear or materially uncertain separate representative triggers remain excluded.

Do not advertise a fixed country count until the final Play Console country list is selected and counted immediately before production.

## Public legal site

Public repo exists: **`lrodeveloperr/kitchen-prep-board-policies-repo`**.

Stable policy pages have been created for Privacy, Terms, Support, Safety, Data Choices and Subscription terms, and the Android BuildConfig is wired to the expected GitHub Pages URLs. GitHub Pages must still be enabled/verified at **main → /docs**.

## EU/EEA + UK representative

Owner intends to pay for one provider capable of covering both regimes. Current low-cost candidate: **DataRep**, subject to its consultation confirming the exact EU/EEA + UK appointment/package. Do not publish a provider as representative until formal appointment details are received.

## Personal Play account testing

Owner does not know the creation date; identity verification occurred **4 August 2026**. Because the account is personal and appears recent, **assume the current closed-testing production-access requirement applies unless Play Console already shows Production access**.

## Remaining owner inputs/actions

1. Confirm from Play Console whether Production access is already granted; otherwise proceed with the required closed test.
2. EU/EEA + UK representative details after appointment.
3. Production AdMob app ID and banner ID after phone/tablet QA.
4. In Play Console, create/activate `remove_ads_monthly` → `monthly` at **US$1.49/month**, with no trial/intro offer.
5. Enable/verify GitHub Pages for `kitchen-prep-board-policies-repo` if not already live.

The subscription price decision is no longer open.

## iOS boundary

Android launches first. The current iOS repository does not yet have verified native persistence, background timer recovery, StoreKit, AdMob/consent or share ingress. Do not delay Android 1.0 on iOS parity.

## Release rule

Do not submit the production AAB until public URLs work, representative details (if required) are published, final country selection is recorded, production ad IDs are configured, subscription is live/tested, native 31-language resources are present, contextual permission flows are tested, Data safety matches the final signed AAB, and device/runtime QA passes.