# Kitchen Prep Board — Google Play Data safety draft (Android 1.0)

This is a working declaration aid, not a substitute for completing Play Console against the final signed Android App Bundle.

## App-owned data model

Core kitchen-board data is local-first. The current Android architecture does not transmit ordinary board/task/template/quantity/timer/note/reference-URL content to a GoodUse Studios server because no developer-operated cloud backend is present.

The release also resolves an **age-treatment category** before advertising. The user enters a date of birth locally; the date itself is discarded after the app derives one of `TEEN`, `ADULT`, or `BLOCKED`. Only the derived category is stored in app-private preferences. It is used to select compliant Google advertising treatment and is not sent to a GoodUse Studios server.

## Third-party SDK data that must be reflected

The production build uses Google Mobile Ads / AdMob and Google UMP. Google’s Mobile Ads SDK disclosures state that the SDK may automatically collect or share data including:

- IP address, potentially used to estimate general/approximate location;
- app/ad interaction information;
- diagnostic information; and
- device or other identifiers, including advertising-related identifiers where available and permitted.

Expected purposes include advertising/marketing, measurement, security and fraud prevention. The exact Play Console categories and sharing flags must be mapped to Google’s then-current SDK disclosure and the final configuration.

### Age treatment

- **16–17:** Google Mobile Ads `AgeRestrictedTreatment.TEEN`; no personalized ads/remarketing; teen protections apply.
- **18+:** adult/unspecified age-restricted treatment; Google UMP and regional privacy choices determine the permitted ad-serving mode.
- **Under 16:** Android 1.0 blocks entry and does not initialize UMP/Mobile Ads.

Google UMP is tagged conservatively as under-age-of-consent for the 16–17 category. The Mobile Ads age-treatment signal is set separately because UMP does not automatically forward its under-age tag to Mobile Ads.

## Google Play Billing

Google Play processes payment information. The app does not receive the user’s full payment-card number. The app receives purchase/entitlement information such as product ID, purchase state and purchase token for subscription operation.

Payment data processed directly by Google Play may qualify for Google Play’s payment-service handling exception in the Data safety form. Do not apply that exception more broadly than Play’s current instructions permit. Reassess if purchase data is ever sent to a GoodUse Studios server.

## Support communications

If a user emails support, the email address, message and any voluntarily attached information are received outside the app by GoodUse Studios. The normal support retention period is 24 months after closure/last substantive activity, subject to legitimate longer legal/security needs.

## Crash and ANR diagnostics

Android 1.0 includes **no Firebase Analytics and no Firebase Crashlytics**. GoodUse Studios intends to use Google Play **Android vitals** for Play-provided crash and ANR information from devices/users participating in Google/Android diagnostics. Android vitals is not an app-embedded analytics/crash SDK.

If Firebase Crashlytics, Firebase Analytics or any other diagnostic/analytics SDK is added later, stop release of that change until this draft, the public Privacy Policy, SDK inventory and Play Data safety declaration are updated.

## Working Play Console answers

- **Does the app collect or share required user data types?** Yes, because third-party advertising SDK behavior counts even though core board data is local.
- **Is data encrypted in transit?** Google service traffic is expected to use encrypted transport; verify the final SDK/runtime and answer exactly as Play defines the field.
- **Can users request deletion?** Local app data can be deleted in-app. GoodUse Studios-held support communications can be addressed through the privacy contact. Google-controlled advertising/payment data is subject to Google controls/policies.
- **Account creation?** No.
- **Account deletion requirement?** No Kitchen Prep Board account exists; reassess if account functionality is ever added.

## Candidate data categories to verify in the final Play form

1. **Location — approximate/general location**: advertising SDK may derive general location from IP.
2. **App activity — app interactions**: advertising/measurement SDK activity.
3. **App info and performance — diagnostics**: SDK diagnostic information.
4. **Device or other IDs**: advertising/device identifiers where age treatment, device settings, law and Google configuration permit.

For each category, verify:

- collected and/or shared;
- required vs optional under Google’s current Data safety definitions;
- exact purposes;
- whether collection differs for TEEN versus ADULT age treatment; and
- whether UMP/privacy choices alter collection/processing in a way Play expects disclosed.

## Local age category

The app-owned derived age-treatment category should be reassessed under Play’s exact current data-type definitions immediately before form submission. It is stored locally and not sent to GoodUse Studios; however the corresponding age **signal** is supplied to Google ad/consent SDKs to obtain age-appropriate treatment. Do not describe the app as collecting a date of birth: the entered date is not retained.

## Must be re-audited if any of these are added

- Firebase Analytics or another analytics SDK;
- Firebase Crashlytics or another crash-reporting SDK;
- cloud sync or a developer API;
- login/account system;
- remote export/import;
- personalized recommendation backend;
- location, camera, microphone, contacts or media permissions;
- new advertising SDKs or ad formats;
- server-side purchase verification; or
- a change to the 16+ audience/age-treatment model.

Final step: compare this draft, the public Privacy Policy, Google’s SDK disclosures, the final Play target-audience/Families declarations and the final signed AAB immediately before completing Play Console Data safety.