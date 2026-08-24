# Kitchen Prep Board — Android 1.0 Country Availability Gate

Review date: 24 August 2026

Owner direction: make Android 1.0 available in all Google Play-supported countries **except jurisdictions outside the EEA/UK where the current release would require GoodUse Studios to appoint an additional local data-protection representative (or where a representative trigger is sufficiently uncertain that global scale could create that obligation).**

This is a release-control document, not a substitute for local legal advice. The country list must be rechecked immediately before production rollout because privacy laws and regulatory guidance change.

## EEA and UK

**Include, subject to appointing the planned Article 27 representation service before production if required by the final processing model.**

The intended approach is to use one commercial provider that can supply both EU/EEA and UK representation. Representative name/address/contact details must be inserted into the effective Privacy Policy before launch.

## Conservative Android 1.0 exclusions — separate local representative regime

The following Play countries/territories should be **excluded at Android 1.0 launch** unless GoodUse Studios later chooses to appoint the relevant local representative or qualified counsel confirms that the representative obligation does not apply to this app:

### Clear / strong representative requirement for foreign controllers

- **Türkiye** — foreign controllers subject to the registration regime generally act through a Turkish data-controller representative.
- **Rwanda** — foreign controllers/processors processing data of individuals located in Rwanda are required to designate a representative in Rwanda.
- **Egypt** — the 2025 executive regulations require foreign controllers/processors without an Egyptian presence to appoint an approved representative in Egypt.
- **Bahrain** — the Personal Data Protection Law contains a representative requirement for covered foreign legal persons.
- **Ecuador** — foreign controllers/processors offering goods/services or monitoring people in Ecuador are subject to a local representative regime.

### GDPR-like / extraterritorial representative regimes — excluded conservatively

These regimes contain representative requirements with exemptions or scope tests similar to GDPR. Because advertising is an ongoing part of Kitchen Prep Board and the owner does not want additional local representative relationships, Android 1.0 excludes them rather than relying on an uncertain 'occasional/low-risk' exemption:

- **Albania**
- **Serbia**
- **Bosnia and Herzegovina**
- **North Macedonia**
- **Kosovo**
- **Montenegro**
- **Botswana**

### Representative trigger with threshold/scope ambiguity — excluded under the owner’s conservative rule

- **Thailand** — foreign controllers may need a Thai representative; a non-sensitive/not-large-amount exemption exists, but scale can change that analysis.
- **Georgia** — current law contains a special-representative rule for foreign controllers/processors using technical means in Georgia; excluded to avoid testing that scope on end-user devices.
- **Algeria** — law/guidance contains a representative requirement where a foreign controller uses processing means located in Algeria; excluded conservatively.
- **Peru** — the current regulation contains a representative/contact-point mechanism for covered foreign processing; excluded because the owner does not want additional representative appointments.

## Countries currently not excluded solely for representative reasons

A jurisdiction is not excluded merely because it has privacy, registration, DPO, transfer, consumer-protection, tax or breach-notification rules. This document addresses the owner’s specific **no additional local representative** constraint.

Examples that currently remain eligible on that narrow criterion include:

- **Switzerland** — a Swiss representative is required only when the statutory cumulative conditions include large-scale, regular and high-risk processing; the current local-first/non-sensitive Android 1.0 model is not treated as meeting those conditions. Reassess if scale/risk changes.
- **South Korea** — local-representative obligations are threshold-based; the initial small-publisher release is far below the currently published high thresholds. Reassess if Korean user volume or global revenue approaches the statutory threshold.

## Age / advertising overlay

Country availability does not override the 16+ target-audience design:

- neutral age screen before advertising;
- users below 16 are not admitted;
- users aged 16–17 receive Google teen ad treatment (no personalized ads + teen protections);
- mixed-audience/Families obligations must be satisfied wherever Play treats the 16–17 audience as children;
- adult advertising/UMP treatment may only begin after the age category is resolved.

## Release process

Before selecting countries in Play Console:

1. obtain and publish EU/EEA + UK representative details if required;
2. recheck this exclusion list against current laws/regulator guidance;
3. exclude every jurisdiction listed above from Android 1.0 availability;
4. verify that no newly changed Play-supported jurisdiction has introduced a mandatory local-representative rule applicable to the app;
5. save/export the final Play country list as release evidence; and
6. update this file with the exact final country count and date.

Do not describe Android 1.0 as available in '175 countries' until the final Play-supported country list minus these exclusions has been counted in Play Console.