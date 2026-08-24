# Kitchen Prep Board — Android 1.0 Global Store Readiness

Review date: 24 August 2026

This is the release gate for the Android app. It uses a conservative global baseline; it does not claim that one checklist can independently certify compliance with every local law.

## Locked owner decisions

- **Platform:** Android first. iOS is not part of the Android 1.0 launch gate.
- **Public version name:** 1.0 / use `1.0.0` in release metadata unless Play requires a different display convention.
- **Provider:** Lateef Razaq-Oyetola carrying on business as GoodUse Studios.
- **Mailing address:** 36 Zorra Street, Toronto (Etobicoke), Ontario M8Z 0G5, Canada.
- **Support/privacy email:** lrodeveloperr@gmail.com.
- **Support-message normal retention:** 24 months after closure/last substantive activity, subject to legitimate longer legal/security needs.
- **Play developer account:** personal.
- **Audience:** 16+; neutral age screen required before ad initialization.
- **16–17 advertising:** Google TEEN treatment; no personalized ads; teen protections apply.
- **Analytics:** none for Android 1.0.
- **Crash diagnostics:** Google Play Android vitals only; no Firebase Analytics/Crashlytics in Android 1.0.
- **AdMob production IDs:** deliberately deferred until owner finishes phone/tablet QA.
- **Distribution:** all otherwise eligible Play-supported countries except jurisdictions excluded under `COUNTRY-AVAILABILITY.md` because the owner does not want extra local representative appointments beyond EEA/UK representation.
- **EU/EEA + UK representation:** owner intends to purchase one commercial provider/service capable of covering both; representative details remain a release blocker until appointed and published.

## Current technical status

- **Target API:** PASS — targetSdk 36.
- **Local-first architecture:** PASS — no account or developer-operated cloud database identified in the current Android source.
- **Android backup:** PASS — disabled.
- **Google UMP:** IMPLEMENTED in current source; must be delayed until the neutral age category and app-owned first-use privacy notice are resolved in the production port.
- **Privacy choices:** IMPLEMENTED — Settings can reopen the Google privacy-options form when required.
- **Google Play Billing:** IMPLEMENTED CLIENT-SIDE — final product configuration, localized price display and Play-track testing remain required.
- **AdMob production IDs:** BLOCKED pending owner device QA and live IDs.
- **Public legal URLs:** BLOCKED pending a public HTTPS legal site.
- **Native final UI:** BLOCKED — the approved HTML visual/workflow source must still be ported into the native Compose release implementation, including 31-language resources and first-use/legal screens.
- **Signed release validation:** BLOCKED — final AAB, signing, install/runtime, billing, age treatment, UMP and banner behavior must be tested in the release toolchain.

## First-use flow required in native Android

Keep first use short but compliant:

0. **Neutral age screen** — month/day/year or another genuinely neutral age input; do not prefill to the minimum age and do not reveal the threshold in a way that encourages falsification. Resolve an on-device age category before UMP or ads initialize.
   - under 16: do not admit the user to Android 1.0;
   - 16–17: `TEEN` advertising treatment;
   - 18+: adult treatment, subject to UMP/regional privacy choices.
1. **Welcome** — Kitchen Prep Board; local-first; no account; language selection.
2. **Privacy & ads notice** — kitchen boards remain on device; Google advertising processes device/app-use information; links to Privacy and Terms. This is an information screen, **not** an advertising-consent substitute.
3. **Three-step workflow** — Add/Paste → Tasks → Timing → Live.
4. Enter Home.

Then request permissions **only when needed**:

- show the food-safety acknowledgment before the first board, not as a launch wall;
- request POST_NOTIFICATIONS when the user first starts/enables timer notifications;
- request exact-alarm special access only when the timer feature actually needs it and after contextual explanation;
- let Google UMP show consent/privacy forms under Google’s regional logic; do not replace it with a custom consent checkbox.

## Mixed-audience / Families gate for 16+

Play provides a 16–17 target-audience band but notes that it may include children in some locales. Therefore the Android 1.0 16+ design must be treated as a mixed-age compliance case where required:

- select the accurate 16–17 and 18+ Play target groups;
- implement the neutral age screen before advertising/SDK behavior that depends on age;
- users aged 16–17 must not receive personalized ads;
- use Google’s current age-treatment signal (`TEEN`) for teen ad requests;
- verify whether the exact Google Mobile Ads SDK version/configuration used for users treated as children or unknown age meets Play Families requirements;
- do not transmit disallowed persistent identifiers for users treated as children/unknown age;
- configure ad-content controls conservatively; **T (Teen) or stricter** is the release ceiling unless a later policy review approves a different setting;
- keep store listing imagery/wording professional rather than child-directed; and
- recheck the Families policy immediately before submission.

If the final Play policy interpretation would require child-specific behavior that cannot be cleanly separated at 16–17, stop and reassess the audience declaration rather than misrepresenting it.

## Settings / legal destinations required

The production native app must provide working destinations for:

- Privacy Policy;
- Terms of Use;
- Google privacy choices when required/available;
- Delete local data;
- Safety Notice;
- Support;
- subscription terms;
- Manage subscription in Google Play; and
- app version/third-party notices where appropriate.

The Privacy Policy URL supplied to Play must be public, active, HTTPS, non-geofenced, readable without login and not a PDF.

## Google Play App content declarations

Before production rollout:

- **Contains ads:** YES.
- **Data safety:** complete from the final signed AAB using `PLAY-DATA-SAFETY-DRAFT.md` only as an aid.
- **Target audience:** 16–17 and 18+ only, subject to the mixed-audience/Families review above.
- **Content rating:** complete IARC questionnaire; do not ship unrated.
- **App access:** no login/access instructions expected because there is no account gate.
- **Health:** not positioned as health/medical guidance; food-safety boundary remains explicit.
- **Financial:** not a financial app; Play Billing is only the purchase mechanism.

## Advertising release gate

- Owner completes phone/tablet QA before live AdMob IDs are introduced.
- Replace demo app/banner IDs with production IDs and reject demo IDs in production.
- Configure AdMob Privacy & messaging for EEA/UK/Switzerland and relevant US-state messages.
- Apply age treatment before every ad request.
- Teen requests: TEEN treatment, no personalized ads, teen protections.
- If users are treated as children under applicable Play/Families rules, use only compliant/certified ad serving and identifier controls for those requests.
- Keep the fixed anchored banner separated from navigation/actions by a non-interactive safe gap.
- No interstitials in active prep/timer workflow for Android 1.0.
- Recheck Google Mobile Ads SDK data-disclosure documentation against the exact final SDK version.

## Crash/analytics gate

Android 1.0 intentionally includes **no Firebase Analytics and no Firebase Crashlytics**.

Use Google Play **Android vitals** after testing/launch for Play-provided crash and ANR information. If Firebase Crashlytics, Analytics or another diagnostic SDK is later added, stop release of that change until Privacy Policy, Data safety, SDK inventory and user disclosures are updated.

## Subscription release gate

Current source identifiers are `remove_ads_monthly` / `monthly`, but these are not yet owner-confirmed production configuration.

Before release:

- confirm final product ID/base plan/billing period and whether any trial/intro offer exists;
- create and activate the subscription in Play Console;
- display the localized Play ProductDetails price and billing period before the purchase action;
- clearly state that the recurring benefit is ad removal while subscribed;
- provide Manage subscription;
- verify purchase, acknowledgment, reconciliation, cancellation and expiry using a Play-track build; and
- do not hard-code a storefront price.

## Permissions release gate

Current manifest declares INTERNET, POST_NOTIFICATIONS, RECEIVE_BOOT_COMPLETED and SCHEDULE_EXACT_ALARM.

- INTERNET: justified by ads, UMP and Play services.
- POST_NOTIFICATIONS: runtime request in timer context, not first launch.
- RECEIVE_BOOT_COMPLETED: timer recovery.
- SCHEDULE_EXACT_ALARM: use special-access flow only where genuinely needed; check availability and degrade gracefully.
- Do not add USE_EXACT_ALARM unless a separate policy review confirms the app qualifies and the owner deliberately accepts the boundary.

## Country availability

Use `COUNTRY-AVAILABILITY.md` as the country-selection gate.

The owner wants broad Play distribution but will **not** appoint extra country-specific representatives outside the planned EU/EEA + UK representation relationship. Jurisdictions with a clear or materially uncertain separate representative trigger are excluded from Android 1.0.

Do not advertise a fixed country count (such as 175) until the final Play-supported country list minus exclusions is counted immediately before production.

## Public legal site

The legal drafts are staged under `legal-drafts/` in this private repository. They cannot serve as the production Play privacy URL.

Recommended free solution: create a public repository such as **`kitchen-prep-board-legal`** and publish `/docs` with GitHub Pages, following the existing Grocery Benefits Tracker legal-site pattern. A paid domain is optional, not necessary for Play compliance.

Once the public repository exists, publish stable HTTPS pages for Privacy, Terms, Support, Safety, Data Choices and Subscription terms, then insert those exact URLs into the Android BuildConfig/Settings and Play Console.

## EU/EEA + UK representative

Owner intends to pay for one provider capable of covering both regimes. Current low-cost candidate: **DataRep**, subject to its free consultation confirming the exact combined EU/EEA + UK appointment and package for this app. Do not publish a provider as the representative until the appointment is actually complete and its legal entity/contact details are supplied.

## Personal Play account testing

Owner confirmed the Play developer account is personal.

If the personal developer account was created **after 13 November 2023**, Google currently requires a closed test with at least **12 testers opted in continuously for 14 days** before applying for production access. Account creation date / existing production access therefore remains an owner input unless the Play dashboard already shows Production access.

## Information still required from the owner

1. **Play personal-account creation date** or confirmation that Production access is already granted.
2. **Public legal-site repository/domain** — recommended: create public `kitchen-prep-board-legal` GitHub repo and enable GitHub Pages.
3. **EU/EEA + UK representative appointment details** after purchase/appointment.
4. **Production AdMob app ID and banner ID** after phone/tablet QA.
5. **Final remove-ads subscription configuration**: product/base-plan IDs, billing period, price strategy and whether any trial/intro offer exists.
6. **Next unused Play versionCode** if Play already contains uploaded builds. Public versionName is locked to 1.0.0.

Everything else listed in the earlier owner-information checklist is resolved.

## iOS boundary

Android launches first. The current iOS repository does not yet contain verified native persistence, background timer recovery, StoreKit, AdMob/consent or share ingress. Do not delay Android 1.0 on iOS parity, and do not describe iOS as store-ready.

## Release rule

Do not mark policy drafts effective and do not submit the production AAB until public URLs work, representative details (if required) are published, final country selection is recorded, the neutral age/teen ad-treatment path is tested, production ad IDs are configured, subscription configuration is live/tested, native 31-language resources are present, contextual permission flows are tested, Data safety matches the final signed AAB, and device/runtime QA passes.