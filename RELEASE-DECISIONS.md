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
- No APK/AAB has previously been uploaded, so versionCode **1** is the production starting point unless Play Console shows otherwise.
- iOS is not a blocker for Android launch and is not yet store-ready.

## Audience

- Android 1.0 is **18+ only**.
- No DOB screen, no stored age category, no teen/child ad path.
- Play target audience must be **18 and over only**.
- Listing, creative and advertising configuration must remain adult-oriented and not child-directed.

## Advertising

- Free version uses a persistent anchored banner.
- No interstitials in active prep/timer workflow for Android 1.0.
- Banner space is reserved before ad load to prevent layout shift.
- A non-interactive gap separates banner from navigation/actions.
- Maximum ad content rating remains **Teen (T)** or stricter for brand suitability; this does not make the app teen-targeted.
- Production AdMob IDs will be supplied only after owner phone/tablet QA.
- Development/demo AdMob IDs must be rejected by production validation.
- Do not force `npa=1` globally; adult ad treatment follows UMP/regional rules.

## Diagnostics / analytics

- No Firebase Analytics in Android 1.0.
- No Firebase Crashlytics in Android 1.0.
- Use Google Play **Android vitals** for Play-provided crash/ANR reporting.
- Adding any analytics/crash SDK later requires a fresh Privacy Policy + Data safety + SDK inventory review.

## Subscription — LOCKED

- Product ID: **`remove_ads_monthly`**.
- Base plan: **`monthly`**.
- Product type: **auto-renewing monthly subscription**.
- U.S. Play base price: **US$1.49/month**.
- Free trial: **none**.
- Introductory offer: **none at launch**.
- Annual plan: **none at launch**.
- Benefit: **removes ads while the subscription is active; no core functionality is paywalled**.
- Google Play should generate/localize storefront pricing from the US$1.49 base, with selective lower local prices considered later from conversion data.
- Production UI must display Google Play's live localized `ProductDetails` price and billing period before purchase. The app must not hard-code `$1.49` as the user's storefront price.

### Pricing rationale

Simple ad-removal subscriptions commonly sit around **US$0.99–$1.99/month**. Cooking/meal products that bundle meaningful premium functionality are materially higher. Kitchen Prep Board charges only for ad removal, so **US$1.49/month** is the selected midpoint: low enough to convert frequent users while producing substantially more subscriber ARPU than US$0.99.

## Privacy / legal site

- Policies must be public HTTPS pages, accessible without login and not PDF-only.
- Public repo: **`lrodeveloperr/kitchen-prep-board-policies-repo`**.
- GitHub Pages is sufficient; a paid domain is optional.
- Effective policies include provider identity, mailing address, support email, 18+ positioning, AdMob/UMP, Google Play Billing, 24-month support retention, Android vitals, local data deletion, food-safety boundary and country/representative disclosures.

## Representative strategy / country availability

- Owner will pay for **one provider** that can cover EU/EEA + UK representation if required.
- Current low-cost candidate: DataRep, subject to consultation and formal appointment.
- Countries outside EEA/UK that create an additional local representative obligation for this release model are excluded from Android 1.0.
- `COUNTRY-AVAILABILITY.md` is the controlling release-country review file.
- Do not advertise a fixed country count until the final Play Console country list has been selected and counted.

## Play account

- Play developer account type: **personal**.
- Identity verification occurred **4 August 2026**.
- Account creation date is unknown. Because the account appears recent, treat the closed-testing production-access rule as applicable unless Play Console already shows Production access.

## Release blockers still requiring owner input/action

1. Confirm whether Play Console already shows **Production access**; otherwise proceed with the required closed-test path.
2. EU/EEA + UK representative details after appointment.
3. Production AdMob Android app ID and banner ID after device QA.
4. In Play Console, create/activate `remove_ads_monthly` → `monthly` and set **US$1.49/month**, with no trial/intro offer.
5. Enable GitHub Pages for `kitchen-prep-board-policies-repo` if not already enabled.

The subscription price decision itself is final; only the Play Console configuration step remains.