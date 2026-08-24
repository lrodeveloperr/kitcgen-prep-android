# Kitchen Prep Board — Global Store Readiness (Android)

Review date: 24 August 2026

This checklist is the release gate for the Android app. It is designed as a conservative global baseline for wide Play distribution; it is not a representation that one document can independently certify every local law in every country.

## Current technical status

- **Target API:** PASS — targetSdk 36 meets the Android 16 / API 36 requirement applicable to new apps and updates from 31 August 2026.
- **Local-first architecture:** PASS — no account or developer-operated cloud database identified in the current Android source.
- **Android backup:** PASS — disabled.
- **Google UMP:** IMPLEMENTED — consent info is refreshed and required forms can be shown; final AdMob Privacy & messaging configuration still must be set in the AdMob account.
- **Privacy choices:** IMPLEMENTED — Settings can reopen the Google privacy-options form when required.
- **Google Play Billing:** IMPLEMENTED CLIENT-SIDE — final product configuration, localized price display and Play-track testing are still required.
- **AdMob production IDs:** BLOCKED — production app and banner IDs have not been supplied; current source can fall back to Google demo IDs.
- **Public legal URLs:** BLOCKED — current Android Settings contains placeholder/disabled Privacy Policy, Terms and Support rows.
- **Signed release validation:** BLOCKED — final AAB, signing, install/runtime, Play billing, UMP and banner behavior must be tested in the release toolchain.

## First-use flow approved for implementation

Keep first use short. The recommended sequence is:

1. **Welcome** — what the app does; local-first; no account.
2. **Privacy & ads notice** — boards stay on the device; the free version uses Google advertising; Google may process IP/general location, interactions, diagnostics and device identifiers; link to Privacy Policy and Terms. This is an information screen, **not** an advertising-consent substitute.
3. **Three-step workflow** — Add/Paste → Details/Tasks → Timing → Live.
4. Enter Home.

Then request sensitive/device permissions **only when needed**:

- Show the food-safety acknowledgment before the first board, not as a launch wall.
- Request Android notification permission when the user first enables/starts a timer that needs background notification.
- Request exact-alarm special access only when reliable precise timer recovery actually needs it and after explaining why.
- Let Google UMP display its required consent/privacy form under Google’s regional logic; do not replace it with a custom consent checkbox.

## Settings / legal destinations required in the production app

Under **Privacy & data / Help / Subscription**, provide working destinations for:

- Privacy Policy;
- Terms of Use;
- Manage privacy choices (Google UMP when available/required);
- Delete local data;
- Safety Notice;
- Support;
- Ads and subscription information;
- Manage subscription in Google Play; and
- app version / third-party notices where appropriate.

The Privacy Policy URL used in Play Console must be public, active, non-geofenced, readable without login and not a PDF.

## Google Play App content declarations

Before production rollout:

- **Contains ads:** YES.
- **Data safety:** complete from the final signed AAB using `PLAY-DATA-SAFETY-DRAFT.md` only as a draft aid.
- **Target audience:** release assumption is adults **18+ only**; owner must confirm. Do not select child-directed age groups unless the app/ads/legal design is completely reworked for Families/child rules.
- **Content rating:** complete IARC questionnaire; an app cannot ship with an unrated/missing rating.
- **App access:** no login/access instructions expected because the app has no account gate.
- **Financial features:** not a financial app; Play Billing is only the purchase mechanism.
- **Health:** app is not positioned as health/medical guidance. Safety copy must not claim food-safety certification.

## Advertising release gate

- Configure production AdMob app ID and banner ID; reject demo IDs in production.
- Configure AdMob Privacy & messaging for EEA/UK/Switzerland and relevant US-state messages.
- Keep the anchored banner physically separated from navigation/actions to reduce accidental-click risk.
- Do not introduce interstitials into active kitchen-prep/timer flow without a new retention/policy review.
- Ensure the privacy policy discloses Google advertising processing.
- Recheck Google Mobile Ads SDK data-disclosure documentation at release time.

## Subscription release gate

Current code product ID: `remove_ads_monthly`; current base plan ID: `monthly`.

Before release:

- confirm those IDs and the intended billing period;
- create/activate the product and base plan in Play Console;
- decide whether there is any trial or introductory offer;
- show the localized Play ProductDetails price and renewal period in-app; remove the current hard-coded `$1.49/month base price` text;
- clearly state that the recurring benefit is ad removal while subscribed;
- provide a Manage subscription path;
- verify purchase, acknowledgment, restore/reconciliation, cancellation and expiry using a Play-track build; and
- strongly consider server-side purchase verification before scale, although the current release is client-side.

## Permissions release gate

Current manifest declares INTERNET, POST_NOTIFICATIONS, RECEIVE_BOOT_COMPLETED and SCHEDULE_EXACT_ALARM.

- INTERNET: justified by ads, UMP and Play services.
- POST_NOTIFICATIONS: request at runtime in context, not automatically on first launch.
- RECEIVE_BOOT_COMPLETED: used for timer recovery.
- SCHEDULE_EXACT_ALARM: use the Android special-access flow only when exact timing is genuinely required; check `canScheduleExactAlarms()` and degrade gracefully when access is unavailable.
- Do not add USE_EXACT_ALARM unless the app clearly qualifies for Google Play’s restricted alarm/timer use case and the release team deliberately accepts that policy boundary.

## Global privacy / consumer-law baseline

The public policy and app behavior should cover the common obligations that recur across GDPR/EEA, UK GDPR, Canada/PIPEDA, California and other US state privacy laws, Brazil LGPD, Japan APPI, Australia Privacy Act/APPs and similar regimes:

- clear controller/provider identity and contact;
- concise notice of what is processed, why, by whom and whether it is shared;
- separate consent where consent is legally required;
- easy withdrawal/manage-privacy path;
- retention and deletion information;
- international-transfer/third-party disclosures;
- access/correction/deletion/objection or opt-out rights where applicable;
- no dark patterns or bundled advertising consent; and
- truthful store disclosures matching actual SDK behavior.

The local-first architecture significantly reduces GoodUse Studios’ direct collection. AdMob/UMP is the main privacy-sensitive third-party path and must remain aligned with Google’s current regional requirements.

## Children / age gate

Release baseline requires owner confirmation that the product is intended for adults 18+ and will not be marketed to children. This is important for Google Play Families rules, child-directed ad treatment, UK child-design rules and newer child-platform laws such as Brazil’s digital child protections.

If children are later intentionally included, stop release and perform a dedicated child-privacy/ads/design review.

## Public legal site blocker

The legal drafts are staged under `legal-drafts/` in this private repository. A private GitHub URL is **not** an acceptable public Play privacy URL.

Owner must provide one of:

- a public GitHub repository that can be served with GitHub Pages (recommended pattern: `kitchen-prep-board-legal`), or
- a public GoodUse Studios website/domain.

Once supplied, publish stable HTTPS pages for Privacy, Terms, Support, Safety, Data Choices and Subscription terms, then insert those exact URLs into the Android app and Play Console.

## Information still required from the owner

1. Confirm legal/provider name for publication: `Lateef Razaq-Oyetola carrying on business as GoodUse Studios` or replacement legal entity.
2. Public business mailing address to show where legally appropriate.
3. Confirm support/privacy email (`lrodeveloperr@gmail.com` or replacement).
4. Public legal-site destination: GitHub Pages repo/domain.
5. Confirm intended audience is 18+ only.
6. Confirm production AdMob publisher/app/banner IDs.
7. Confirm Android subscription product ID, base plan, billing period and whether any trial/intro offer exists.
8. Confirm whether Android launch will use subscription-only ad removal or another purchase model.
9. Confirm desired normal support-email retention period (draft policy currently leaves this open).
10. Confirm whether an EU GDPR Article 27 representative and UK GDPR representative have been appointed or will be obtained if legally required.
11. Confirm Play developer-account type/status and whether the account is subject to pre-production testing requirements.
12. Provide final app version/version code and release signing setup when ready for the production AAB.
13. Confirm no Firebase Analytics, Crashlytics, cloud sync, login, developer server or additional SDK will be added before release.

## iOS warning

The current iOS repository explicitly documents that native persistence, background timer recovery, StoreKit, AdMob/consent and share ingress have not yet been implemented. The iOS build therefore cannot be called store-ready from the current repository state. A separate native iOS production-parity pass is required before an App Store launch.

## Release rule

Do not mark the policy drafts effective and do not submit the production AAB until all `[...REQUIRED]` placeholders are resolved, public URLs work, Play declarations match the final signed build, production ad IDs are configured, the subscription is live/tested, permission flows are tested, and the release AAB passes device/runtime QA.