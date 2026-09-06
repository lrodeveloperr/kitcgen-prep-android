# Kitchen Prep Board — Android 1.0 Country Availability Gate

Review date: 24 August 2026

Owner direction: make Android 1.0 available in all Google Play-supported countries **except jurisdictions outside the EEA/UK where the current release would require GoodUse Studios to appoint an additional local data-protection representative (or where a representative trigger is sufficiently uncertain that global scale could create that obligation).**

This is a release-control document, not a substitute for local legal advice. The country list must be rechecked immediately before production rollout because privacy laws and regulatory guidance change.

## EEA and UK

**Include only after the planned Article 27 representation service is appointed if required by the final processing model.**

The intended approach is to use one commercial provider that can supply both EU/EEA and UK representation. Representative name/address/contact details must be inserted into the effective Privacy Policy before those territories are enabled.

## Conservative Android 1.0 exclusions — separate local representative regime

The following Play countries/territories should be **excluded at Android 1.0 launch** unless GoodUse Studios later chooses to appoint the relevant local representative or qualified counsel confirms that the representative obligation does not apply to this app:

### Clear / strong representative requirement for foreign controllers

- **Türkiye**
- **Rwanda**
- **Egypt**
- **Bahrain**
- **Ecuador**

### GDPR-like / extraterritorial representative regimes — excluded conservatively

Because advertising is an ongoing part of Kitchen Prep Board and the owner does not want additional local representative relationships, Android 1.0 excludes these jurisdictions rather than relying on an uncertain occasional/low-risk exemption:

- **Albania**
- **Serbia**
- **Bosnia and Herzegovina**
- **North Macedonia**
- **Kosovo**
- **Montenegro**
- **Botswana**

### Representative trigger with threshold/scope ambiguity — excluded under the owner’s conservative rule

- **Thailand**
- **Georgia**
- **Algeria**
- **Peru**

## Countries currently not excluded solely for representative reasons

A jurisdiction is not excluded merely because it has privacy, registration, DPO, transfer, consumer-protection, tax or breach-notification rules. This document addresses the owner’s specific **no additional local representative** constraint.

Examples that currently remain eligible on that narrow criterion include:

- **Switzerland** — a Swiss representative is required only when statutory cumulative conditions include large-scale, regular and high-risk processing; the current local-first/non-sensitive Android 1.0 model is not treated as meeting those conditions. Reassess if scale/risk changes.
- **South Korea** — local-representative obligations are threshold-based; the initial small-publisher release is far below the currently published high thresholds. Reassess if Korean user volume or global revenue approaches the statutory threshold.

## Audience / advertising overlay

Country availability does not change the Android 1.0 audience design:

- target audience is **18 and over only**;
- no date of birth or age category is collected by the app;
- no child/teen advertising path is implemented;
- Google UMP handles adult regional advertising privacy choices where required;
- the store listing and marketing must remain adult-oriented and not child-directed.

## Release process

Before selecting countries in Play Console:

1. obtain and publish EU/EEA + UK representative details if required;
2. recheck this exclusion list against current laws/regulator guidance;
3. exclude every jurisdiction listed above from Android 1.0 availability;
4. verify that no newly changed Play-supported jurisdiction has introduced a mandatory local-representative rule applicable to the app;
5. save/export the final Play country list as release evidence; and
6. update this file with the exact final country count and date.

Do not describe Android 1.0 as available in a fixed number of countries until the final Play-supported country list minus exclusions has been counted in Play Console.