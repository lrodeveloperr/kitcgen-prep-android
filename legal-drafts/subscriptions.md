# Kitchen Prep Board — Ads and Remove-Ads Subscription

The free Android version of Kitchen Prep Board is intended to provide the core app functionality with advertising. An optional Google Play subscription removes ads while the subscription entitlement is active.

## Android product draft

Current code identifiers:

- Product ID: `remove_ads_monthly`
- Base plan ID: `monthly`
- Product type: auto-renewing subscription
- Benefit: removes advertising while the subscription is active

These identifiers and the final Play Console configuration must be confirmed before release.

## Price and renewal

The app must display the price and billing period returned by Google Play for the user’s storefront. The production UI must not rely on a hard-coded base price.

The subscription renews automatically according to the terms displayed by Google Play unless the user cancels it. Users can manage or cancel subscriptions through Google Play. Cancellation stops future renewal but does not ordinarily erase local app data.

Any free trial, introductory price or promotional offer must be disclosed exactly as configured in Google Play and must not be described in the app unless the user is actually eligible for that offer.

## Refunds

Refunds and cancellation rights are governed by Google Play policy and applicable mandatory consumer law. Kitchen Prep Board must not promise a narrower refund right than applicable law provides.

## Privacy

Google Play processes the payment transaction. Kitchen Prep Board receives purchase/entitlement information needed to determine whether ads should be removed. See the Privacy Policy for details.

## Advertising

If the subscription entitlement is not active, advertising may be requested only when the app’s Google UMP / AdMob privacy state permits an ad request. If the entitlement is active, advertising should be suppressed.

## Release confirmations required

Before publication, confirm:

1. the exact product ID and base plan;
2. monthly versus another billing period;
3. whether any free trial or introductory offer exists;
4. the Play Console product is active in all intended storefronts;
5. the app displays localized ProductDetails pricing and renewal information rather than a hard-coded price; and
6. restore/reconciliation behavior has been tested using a Play-track build.

This page is a release draft until those items are confirmed.