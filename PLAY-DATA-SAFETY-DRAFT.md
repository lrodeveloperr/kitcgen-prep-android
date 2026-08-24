# Kitchen Prep Board — Google Play Data safety draft

This is a working declaration aid, not a substitute for completing the Play Console questionnaire against the final signed AAB.

## App-owned data model

Core kitchen-board data is local-first. The current Android architecture does not transmit ordinary board/task/template/quantity/timer/note/reference-URL content to a GoodUse Studios server because no developer-operated cloud backend is present.

## Third-party SDK data that must be reflected

The production build uses Google Mobile Ads / AdMob and Google UMP. Google’s Mobile Ads SDK disclosures state that the SDK may automatically collect or share data including:

- IP address, potentially used to estimate general/approximate location;
- app/ad interaction information;
- diagnostic information; and
- device or other identifiers, including advertising-related identifiers where available.

Expected purposes include advertising/marketing, analytics or measurement, security and fraud prevention. The exact Play Console categories and sharing flags must be mapped to Google’s then-current SDK disclosure and the final configuration.

## Google Play Billing

Google Play processes payment information. The app does not receive the user’s full payment-card number. The app receives purchase/entitlement information such as product ID, purchase state and purchase token for subscription operation.

Payment data processed directly by Google Play may qualify for Google Play’s payment-service handling exception in the Data safety form. Do not declare that exception more broadly than Play’s instructions permit. Reassess if purchase data is ever sent to a GoodUse Studios server.

## Support communications

If a user emails support, the email address, message and any voluntarily attached information are received outside the app by GoodUse Studios. Store-form treatment should follow Google’s current rules for data collected through app functionality versus separate support communications.

## Working Play Console answers

- **Does the app collect or share any required user data types?** Yes, because third-party advertising SDK behavior counts even though core board data is local.
- **Is data encrypted in transit?** Google SDK network transport should use encrypted connections; verify final SDK/runtime behavior.
- **Can users request deletion?** Local data can be deleted in-app. For GoodUse Studios-held support data, users can email the privacy contact. Google-controlled advertising/payment data is subject to Google controls/policies.
- **Account creation?** No.
- **Account deletion requirement?** No user account is created by Kitchen Prep Board, so the Play account-deletion requirement should not apply unless account functionality is added later.

## Candidate data categories to verify in the final Play form

1. **Location — approximate/general location**: because the advertising SDK may derive general location from IP.
2. **App activity — app interactions**: advertising/measurement SDK activity.
3. **App info and performance — diagnostics**: SDK diagnostic information.
4. **Device or other IDs**: advertising/device identifiers used by the advertising SDK.

For each category, verify the final Google Mobile Ads SDK disclosure, whether the data is collected and/or shared, whether collection is optional based on privacy choices, and the exact purposes shown in Play Console.

## Must be re-audited if any of these are added

- Firebase Analytics or another analytics SDK;
- crash-reporting SDK;
- cloud sync or a developer API;
- login/account system;
- remote export/import;
- personalized recommendation backend;
- location, camera, microphone, contacts or media permissions;
- new advertising SDKs or ad formats; or
- server-side purchase verification.

Final step: compare this draft, the public Privacy Policy, Google’s SDK disclosure and the final signed AAB immediately before completing Play Console Data safety.