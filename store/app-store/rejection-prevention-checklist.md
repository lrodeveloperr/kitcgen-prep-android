# Apple rejection-prevention checklist

This release incorporates the defects previously flagged on PressBench and Grocery Benefits Tracker.

- [x] Functional Terms of Use URL appears in the App Store description and dedicated metadata.
- [x] No auto-renewable subscription or IAP exists on iOS, so subscription disclosure, restore and promotional-image requirements do not apply.
- [x] No promoted IAP is configured; the app icon is never reused as IAP promotional artwork (PressBench Guideline 2.3.2 lesson).
- [x] Review notes state that no account or credentials are required and give a complete test path.
- [x] Review notes match the uploaded production build: paid upfront, ad-free, offline and local-only.
- [x] App privacy answers match the binary: no AdMob, analytics, ATT prompt, account, cloud sync or developer server.
- [x] Notification use is described and remains optional.
- [x] Food-safety limitations are stated without making safety guarantees.
- [x] Encryption declaration is explicit (`ITSAppUsesNonExemptEncryption = false`).
- [x] Version, bundle ID, SKU, team and locale are locked in release metadata.
- [ ] Genuine App Store screenshots must show this exact iOS build and its current UI before App Review submission.
- [ ] App Review contact fields and any requested completeness video must be filled before submission.
- [ ] Do not submit for App Review until pricing and territories are explicitly set.

